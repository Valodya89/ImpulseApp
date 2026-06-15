//
//  MimoCamera.swift
//  MimoBike
//
//  Replacements for `GMSCameraPosition` and `GMSCameraUpdate`.
//

import UIKit
import CoreLocation
import DGis

/// Mirrors the small slice of `GMSCameraPosition` the app uses.
final class MimoCameraPosition {
    var target: CLLocationCoordinate2D
    var zoom: Float

    init(target: CLLocationCoordinate2D, zoom: Float) {
        self.target = target
        self.zoom = zoom
    }

    convenience init(latitude: CLLocationDegrees, longitude: CLLocationDegrees, zoom: Float) {
        self.init(target: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), zoom: zoom)
    }

    static func camera(withLatitude latitude: CLLocationDegrees,
                       longitude: CLLocationDegrees,
                       zoom: Float) -> MimoCameraPosition {
        MimoCameraPosition(latitude: latitude, longitude: longitude, zoom: zoom)
    }

    static func camera(withTarget target: CLLocationCoordinate2D, zoom: Float) -> MimoCameraPosition {
        MimoCameraPosition(target: target, zoom: zoom)
    }

    var dgisPosition: CameraPosition {
        CameraPosition(point: target.geoPoint, zoom: Zoom(value: zoom))
    }
}

/// Mirrors `GMSCameraUpdate` for the `setTarget(_:zoom:)` use case.
final class MimoCameraUpdate {
    let target: CLLocationCoordinate2D?
    let zoom: Float?

    private init(target: CLLocationCoordinate2D?, zoom: Float?) {
        self.target = target
        self.zoom = zoom
    }

    static func setTarget(_ target: CLLocationCoordinate2D, zoom: Float) -> MimoCameraUpdate {
        MimoCameraUpdate(target: target, zoom: zoom)
    }

    static func setTarget(_ target: CLLocationCoordinate2D) -> MimoCameraUpdate {
        MimoCameraUpdate(target: target, zoom: nil)
    }

    static func zoom(to zoom: Float) -> MimoCameraUpdate {
        MimoCameraUpdate(target: nil, zoom: zoom)
    }
}
