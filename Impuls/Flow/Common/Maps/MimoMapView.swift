//
//  MimoMapView.swift
//  MimoBike
//
//  Replacement for `GMSMapView`. A storyboard-instantiable `UIView` that hosts a
//  2GIS map. Re-creates the small slice of the Google Maps API the app relies on
//  (markers/overlays via a `MapObjectManager`, camera control, projection,
//  tap + camera delegate callbacks, "my location").
//

import UIKit
import CoreLocation
import DGis

/// Overlays implement this so `MimoMapView.clear()` can detach them without
/// double-removing from the (already emptied) object manager.
protocol MimoMapOverlay: AnyObject {
    func mimoMapDidClear()
}

struct MimoVisibleRegion {
    var farLeft: CLLocationCoordinate2D
    var farRight: CLLocationCoordinate2D
    var nearLeft: CLLocationCoordinate2D
    var nearRight: CLLocationCoordinate2D
}

final class MimoMapView: UIView {

    // MARK: SDK objects

    private(set) var mapFactory: IMapFactory?
    var dgisMap: DGis.Map? { mapFactory?.map }
    private(set) var objectManager: MapObjectManager?
    private var dgisMapView: (UIView & IMapView)?

    // MARK: Google-compatible surface

    weak var delegate: MimoMapViewDelegate?
    var selectedMarker: MimoMarker?
    lazy var projection = MimoProjection(mapView: self)

    var isMyLocationEnabled: Bool {
        get { locationSource != nil }
        set {
            guard newValue != (locationSource != nil) else { return }
            if newValue {
                if let source = MimoMap.shared.makeMyLocationSource() {
                    locationSource = source
                    dgisMap?.addSource(source: source)
                }
            } else if let source = locationSource {
                dgisMap?.removeSource(source: source)
                locationSource = nil
            }
        }
    }

    /// Current camera position. Settable like `GMSMapView.camera` — assigning a
    /// value moves the camera instantly (or stores it until the map is ready).
    var camera: MimoCameraPosition {
        get {
            guard let position = dgisMap?.camera.position else {
                return pendingCamera ?? MimoCameraPosition(latitude: 0, longitude: 0, zoom: 0)
            }
            return MimoCameraPosition(target: position.point.clCoordinate, zoom: position.zoom.value)
        }
        set {
            guard let map = dgisMap else {
                pendingCamera = newValue
                return
            }
            moveCancellable = map.camera.move(
                position: newValue.dgisPosition, time: 0, animationType: .linear
            ).sink(receiveValue: { _ in }, failure: { _ in })
        }
    }

    // MARK: Internal state

    private var locationSource: MyLocationMapObjectSource?
    private var positionCancellable: DGis.Cancellable?
    private var stateCancellable: DGis.Cancellable?
    private var moveCancellable: DGis.Cancellable?
    private let tracked = NSHashTable<AnyObject>.weakObjects()
    private var didSetup = false
    private var lastObjectTapTime: TimeInterval = 0
    private var pendingCamera: MimoCameraPosition?

    // MARK: Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        tap.cancelsTouchesInView = false
        tap.delegate = self
        addGestureRecognizer(tap)
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        setupIfNeeded()
    }

    // MARK: Setup

    private func setupIfNeeded() {
        guard !didSetup, window != nil, let factory = MimoMap.shared.makeMapFactory() else { return }
        didSetup = true
        mapFactory = factory

        let mv = factory.mapView
        dgisMapView = mv
        objectManager = MapObjectManager(map: factory.map)

        mv.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(mv, at: 0)
        NSLayoutConstraint.activate([
            mv.topAnchor.constraint(equalTo: topAnchor),
            mv.bottomAnchor.constraint(equalTo: bottomAnchor),
            mv.leadingAnchor.constraint(equalTo: leadingAnchor),
            mv.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        mv.addObjectTappedCallback(callback: .init(callback: { [weak self] info in
            self?.handleObjectTap(info)
        }))

        positionCancellable = factory.map.camera.positionChannel.sink { [weak self] position in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.delegate?.mapView(self, didChange: MimoCameraPosition(
                    target: position.point.clCoordinate, zoom: position.zoom.value))
            }
        }
        stateCancellable = factory.map.camera.stateChannel.sink { [weak self] state in
            guard let self = self, state == .free else { return }
            DispatchQueue.main.async {
                self.delegate?.mapView(self, idleAt: self.camera)
            }
        }

        if let pending = pendingCamera {
            pendingCamera = nil
            camera = pending
        }
    }

    // MARK: Overlay tracking

    func track(_ overlay: MimoMapOverlay) {
        tracked.add(overlay)
    }

    /// `GMSMapView.clear()` — removes every marker/overlay from the map.
    func clear() {
        objectManager?.removeAll()
        tracked.allObjects.compactMap { $0 as? MimoMapOverlay }.forEach { $0.mimoMapDidClear() }
        tracked.removeAllObjects()
        selectedMarker = nil
    }

    // MARK: Camera

    func animate(to position: MimoCameraPosition) {
        move(to: position.dgisPosition)
    }

    func animate(toLocation location: CLLocationCoordinate2D) {
        let zoom = dgisMap?.camera.position.zoom ?? Zoom(value: 15)
        move(to: CameraPosition(point: location.geoPoint, zoom: zoom))
    }

    func animate(toZoom zoom: Float) {
        guard let point = dgisMap?.camera.position.point else { return }
        move(to: CameraPosition(point: point, zoom: Zoom(value: zoom)))
    }

    func animate(with update: MimoCameraUpdate) {
        guard let current = dgisMap?.camera.position else { return }
        let point = update.target?.geoPoint ?? current.point
        let zoom = update.zoom.map { Zoom(value: $0) } ?? current.zoom
        move(to: CameraPosition(point: point, zoom: zoom))
    }

    private func move(to position: CameraPosition) {
        guard let map = dgisMap else { return }
        moveCancellable = map.camera.move(position: position, time: 0.3, animationType: .linear).sink(
            receiveValue: { _ in }, failure: { _ in }
        )
    }

    // MARK: Tap handling

    private func handleObjectTap(_ info: RenderedObjectInfo) {
        lastObjectTapTime = Date.timeIntervalSinceReferenceDate
        let coordinate = info.closestMapPoint.point.clCoordinate

        switch info.item.item {
        case let marker as Marker:
            if let mimo = marker.userData as? MimoMarker {
                DispatchQueue.main.async { _ = self.delegate?.mapView(self, didTap: mimo) }
            }
        case let cluster as SimpleClusterObject:
            let synthetic = MimoMarker(position: coordinate)
            synthetic.userData = MimoCluster(count: UInt(cluster.objectCount), position: coordinate)
            DispatchQueue.main.async { _ = self.delegate?.mapView(self, didTap: synthetic) }
        default:
            break
        }
    }

    @objc private func handleMapTap(_ recognizer: UITapGestureRecognizer) {
        // Suppress the empty-map tap if an object tap was just delivered.
        if Date.timeIntervalSinceReferenceDate - lastObjectTapTime < 0.15 { return }
        let location = recognizer.location(in: self)
        let coordinate = projection.coordinate(for: location)
        guard CLLocationCoordinate2DIsValid(coordinate) else { return }
        delegate?.mapView(self, didTapAt: coordinate)
    }
}

extension MimoMapView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
        true
    }
}

// MARK: - Projection

final class MimoProjection {
    private weak var mapView: MimoMapView?

    init(mapView: MimoMapView) {
        self.mapView = mapView
    }

    func point(for coordinate: CLLocationCoordinate2D) -> CGPoint {
        guard let screenPoint = mapView?.dgisMap?.camera.projection.mapToScreen(point: coordinate.geoPoint) else {
            return .zero
        }
        let scale = UIScreen.main.nativeScale
        return CGPoint(x: CGFloat(screenPoint.x) / scale, y: CGFloat(screenPoint.y) / scale)
    }

    func coordinate(for point: CGPoint) -> CLLocationCoordinate2D {
        let scale = UIScreen.main.nativeScale
        let screenPoint = ScreenPoint(x: Float(point.x * scale), y: Float(point.y * scale))
        guard let geoPoint = mapView?.dgisMap?.camera.projection.screenToMap(point: screenPoint) else {
            return kCLLocationCoordinate2DInvalid
        }
        return geoPoint.clCoordinate
    }

    func visibleRegion() -> MimoVisibleRegion {
        let bounds = mapView?.bounds ?? .zero
        return MimoVisibleRegion(
            farLeft: coordinate(for: CGPoint(x: bounds.minX, y: bounds.minY)),
            farRight: coordinate(for: CGPoint(x: bounds.maxX, y: bounds.minY)),
            nearLeft: coordinate(for: CGPoint(x: bounds.minX, y: bounds.maxY)),
            nearRight: coordinate(for: CGPoint(x: bounds.maxX, y: bounds.maxY))
        )
    }
}
