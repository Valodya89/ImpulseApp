//
//  MimoShapes.swift
//  MimoBike
//
//  Replacements for `GMSMutablePath`, `GMSPolygon`, `GMSPolyline`, `GMSCircle`.
//  Each overlay keeps the Google-style `map` property: assigning a map adds the
//  object to that map's object manager; assigning `nil` removes it.
//

import UIKit
import CoreLocation
import DGis

// MARK: - Path

/// Replacement for `GMSMutablePath`.
final class MimoMutablePath {
    private(set) var coordinates: [CLLocationCoordinate2D] = []

    init() {}

    func add(_ coordinate: CLLocationCoordinate2D) {
        coordinates.append(coordinate)
    }

    var count: UInt { UInt(coordinates.count) }

    func coordinate(at index: UInt) -> CLLocationCoordinate2D {
        coordinates[Int(index)]
    }

    var geoPoints: [GeoPoint] { coordinates.map { $0.geoPoint } }
}

// MARK: - Polygon

/// Replacement for `GMSPolygon`.
final class MimoPolygon: MimoMapOverlay {
    var path: MimoMutablePath?
    var holes: [MimoMutablePath]?
    var fillColor: UIColor?
    var strokeColor: UIColor?
    var strokeWidth: CGFloat = 1

    fileprivate var dgisObject: Polygon?
    private(set) weak var attachedManager: MapObjectManager?

    weak var map: MimoMapView? {
        didSet {
            guard map !== oldValue else { return }
            removeFromMap()
            if let map = map { addTo(map) }
        }
    }

    init() {}

    convenience init(path: MimoMutablePath) {
        self.init()
        self.path = path
    }

    private func buildContours() -> [[GeoPoint]] {
        var contours: [[GeoPoint]] = []
        if let path = path, path.count > 0 { contours.append(path.geoPoints) }
        holes?.forEach { hole in
            if hole.count > 0 { contours.append(hole.geoPoints) }
        }
        return contours
    }

    private func addTo(_ mapView: MimoMapView) {
        guard let manager = mapView.objectManager else { return }
        let contours = buildContours()
        guard !contours.isEmpty else { return }
        let options = PolygonOptions(
            contours: contours,
            color: (fillColor ?? .clear).dgisColor,
            strokeWidth: LogicalPixel(value: Float(strokeWidth)),
            strokeColor: (strokeColor ?? .clear).dgisColor
        )
        guard let polygon = try? Polygon(options: options) else { return }
        dgisObject = polygon
        attachedManager = manager
        manager.addObject(item: polygon)
        mapView.track(self)
    }

    private func removeFromMap() {
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
}

// MARK: - Polyline

/// Replacement for `GMSPolyline`.
final class MimoPolyline: MimoMapOverlay {
    var path: MimoMutablePath?
    var strokeColor: UIColor?
    var strokeWidth: CGFloat = 1

    fileprivate var dgisObject: Polyline?
    private(set) weak var attachedManager: MapObjectManager?

    weak var map: MimoMapView? {
        didSet {
            guard map !== oldValue else { return }
            removeFromMap()
            if let map = map { addTo(map) }
        }
    }

    init() {}

    convenience init(path: MimoMutablePath) {
        self.init()
        self.path = path
    }

    private func addTo(_ mapView: MimoMapView) {
        guard let manager = mapView.objectManager, let path = path, path.count > 1 else { return }
        let options = PolylineOptions(
            points: path.geoPoints,
            width: LogicalPixel(value: Float(strokeWidth)),
            color: (strokeColor ?? .black).dgisColor
        )
        guard let polyline = try? Polyline(options: options) else { return }
        dgisObject = polyline
        attachedManager = manager
        manager.addObject(item: polyline)
        mapView.track(self)
    }

    private func removeFromMap() {
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
}

// MARK: - Circle

/// Replacement for `GMSCircle`.
final class MimoCircle: MimoMapOverlay {
    var position: CLLocationCoordinate2D
    var radius: CLLocationDistance
    var fillColor: UIColor?
    var strokeColor: UIColor?
    var strokeWidth: CGFloat = 1

    fileprivate var dgisObject: Circle?
    private(set) weak var attachedManager: MapObjectManager?

    weak var map: MimoMapView? {
        didSet {
            guard map !== oldValue else { return }
            removeFromMap()
            if let map = map { addTo(map) }
        }
    }

    init(position: CLLocationCoordinate2D, radius: CLLocationDistance) {
        self.position = position
        self.radius = radius
    }

    private func addTo(_ mapView: MimoMapView) {
        guard let manager = mapView.objectManager else { return }
        let options = CircleOptions(
            position: position.geoPoint,
            radius: Meter(value: Float(radius)),
            color: (fillColor ?? .clear).dgisColor,
            strokeWidth: LogicalPixel(value: Float(strokeWidth)),
            strokeColor: (strokeColor ?? .clear).dgisColor
        )
        guard let circle = try? Circle(options: options) else { return }
        dgisObject = circle
        attachedManager = manager
        manager.addObject(item: circle)
        mapView.track(self)
    }

    private func removeFromMap() {
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
}
