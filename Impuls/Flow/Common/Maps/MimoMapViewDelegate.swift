//
//  MimoMapViewDelegate.swift
//  MimoBike
//
//  Replacement for the subset of `GMSMapViewDelegate` the app uses.
//  Implemented as a plain Swift protocol with default (no-op) implementations,
//  so conformers only override the callbacks they care about — mirroring the
//  optional methods of `GMSMapViewDelegate`.
//

import UIKit
import CoreLocation

protocol MimoMapViewDelegate: AnyObject {
    /// Return `true` if the tap was handled (matches `GMSMapViewDelegate`).
    func mapView(_ mapView: MimoMapView, didTap marker: MimoMarker) -> Bool
    func mapView(_ mapView: MimoMapView, didTapAt coordinate: CLLocationCoordinate2D)
    func mapView(_ mapView: MimoMapView, didChange position: MimoCameraPosition)
    func mapView(_ mapView: MimoMapView, idleAt position: MimoCameraPosition)
    func mapView(_ mapView: MimoMapView, markerInfoWindow marker: MimoMarker) -> UIView?
}

extension MimoMapViewDelegate {
    func mapView(_ mapView: MimoMapView, didTap marker: MimoMarker) -> Bool { false }
    func mapView(_ mapView: MimoMapView, didTapAt coordinate: CLLocationCoordinate2D) {}
    func mapView(_ mapView: MimoMapView, didChange position: MimoCameraPosition) {}
    func mapView(_ mapView: MimoMapView, idleAt position: MimoCameraPosition) {}
    func mapView(_ mapView: MimoMapView, markerInfoWindow marker: MimoMarker) -> UIView? { nil }
}

/// Marker tag used to mirror `marker.userData is GMUCluster` checks.
/// A cluster tap surfaces a synthetic `MimoMarker` whose `userData` is a `MimoCluster`.
final class MimoCluster {
    let count: UInt
    let position: CLLocationCoordinate2D
    init(count: UInt, position: CLLocationCoordinate2D) {
        self.count = count
        self.position = position
    }
}
