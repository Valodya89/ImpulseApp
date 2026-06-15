//
//  MimoMarker.swift
//  MimoBike
//
//  Replacement for `GMSMarker`. Keeps the Google-style mutable API: assigning
//  `marker.map = mapView` adds it, `marker.map = nil` removes it, and changing
//  `position` / `icon` after the marker is on a map updates it live.
//

import UIKit
import CoreLocation
import DGis

/// Mirrors `GMSMarkerAnimation`.
enum MimoMarkerAnimation {
    case none
    case pop
}

final class MimoMarker: MimoMapOverlay, Hashable {

    // MARK: Google-compatible API

    var position: CLLocationCoordinate2D {
        didSet { dgisObject?.position = position.geoPointWithElevation }
    }

    var icon: UIImage? {
        didSet { applyIcon() }
    }

    /// `GMSMarker.iconView` — rasterised to an image for 2GIS.
    var iconView: UIView? {
        didSet {
            icon = iconView?.asImage
        }
    }

    /// Arbitrary app payload. Kept independent of the SDK object so the app's
    /// `marker.userData is SomeType` checks keep working.
    var userData: Any?

    var title: String?
    var snippet: String?
    var zIndex: Int32 = 0

    /// Stored for `GMSMarker` API compatibility. `appearAnimation` / `groundAnchor`
    /// / `isTappable` are accepted but not all are forwarded to 2GIS (markers are
    /// tappable by default and use a centred anchor).
    var appearAnimation: MimoMarkerAnimation = .none
    var groundAnchor: CGPoint = CGPoint(x: 0.5, y: 1.0)
    var isTappable: Bool = true

    weak var map: MimoMapView? {
        didSet {
            guard map !== oldValue else { return }
            removeFromMap()
            if let map = map { addTo(map) }
        }
    }

    // MARK: Internal

    private(set) var dgisObject: Marker?
    private(set) weak var attachedManager: MapObjectManager?

    // MARK: Init

    init() {
        self.position = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }

    convenience init(position: CLLocationCoordinate2D) {
        self.init()
        self.position = position
    }

    // MARK: Build / attach

    /// Builds the underlying 2GIS marker. Used both by `map` assignment and by
    /// `MimoClusterManager` (which adds it to its own clustering manager).
    func makeDgisMarker() -> Marker? {
        let image: DGis.Image?
        if let icon = icon {
            image = MimoMap.shared.imageFactory?.make(image: icon)
        } else {
            image = nil
        }
        let options = MarkerOptions(
            position: position.geoPointWithElevation,
            icon: image,
            text: title ?? "",
            userData: self,
            zIndex: ZIndex(value: UInt32(max(zIndex, 0)))
        )
        let marker = try? Marker(options: options)
        dgisObject = marker
        return marker
    }

    private func addTo(_ mapView: MimoMapView) {
        guard let manager = mapView.objectManager, let marker = makeDgisMarker() else { return }
        attachedManager = manager
        manager.addObject(item: marker)
        mapView.track(self)
    }

    func removeFromMap() {
        if let object = dgisObject, let manager = attachedManager {
            manager.removeObject(item: object)
        }
        dgisObject = nil
        attachedManager = nil
    }

    func mimoMapDidClear() {
        dgisObject = nil
        attachedManager = nil
    }

    private func applyIcon() {
        guard let object = dgisObject else { return }
        if let icon = icon, let image = MimoMap.shared.imageFactory?.make(image: icon) {
            object.icon = image
        }
    }

    // MARK: Hashable

    static func == (lhs: MimoMarker, rhs: MimoMarker) -> Bool { lhs === rhs }
    func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}
