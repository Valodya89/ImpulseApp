//
//  MimoGeocoder.swift
//  MimoBike
//
//  Replacement for `GMSGeocoder` reverse geocoding.
//
//  NOTE: The 2GIS *Map* (lite) SDK does not expose a public coordinate→address
//  (reverse geocoding) API; that lives in the directory/search backend. To keep
//  the app's address features working without an extra paid endpoint, this uses
//  Apple's `CLGeocoder`. The call-site API mirrors `GMSGeocoder` exactly
//  (`reverseGeocodeCoordinate(_:completionHandler:)` → `firstResult()`), so
//  callers are unchanged. Swap the body for 2GIS `SearchManager` reverse
//  geocoding later if directory keys become available.
//

import Foundation
import CoreLocation

/// Mirrors `GMSReverseGeocodeResult`.
final class MimoReverseGeocodeResult {
    let thoroughfare: String?
    let subLocality: String?
    let locality: String?
    let administrativeArea: String?
    let country: String?
    let postalCode: String?
    let lines: [String]?

    init(placemark: CLPlacemark) {
        self.thoroughfare = placemark.thoroughfare
        self.subLocality = placemark.subLocality
        self.locality = placemark.locality
        self.administrativeArea = placemark.administrativeArea
        self.country = placemark.country
        self.postalCode = placemark.postalCode

        var components: [String] = []
        if let s = placemark.thoroughfare { components.append(s) }
        if let s = placemark.subThoroughfare { components.append(s) }
        if let s = placemark.subLocality { components.append(s) }
        if let s = placemark.locality { components.append(s) }
        self.lines = components.isEmpty ? nil : [components.joined(separator: ", ")]
    }
}

/// Mirrors `GMSReverseGeocodeResponse`.
final class MimoReverseGeocodeResponse {
    private let allResults: [MimoReverseGeocodeResult]
    init(results: [MimoReverseGeocodeResult]) { self.allResults = results }
    func firstResult() -> MimoReverseGeocodeResult? { allResults.first }
    func results() -> [MimoReverseGeocodeResult]? { allResults }
}

/// Mirrors `GMSGeocoder`.
final class MimoGeocoder {
    private let geocoder = CLGeocoder()

    init() {}

    func reverseGeocodeCoordinate(
        _ coordinate: CLLocationCoordinate2D,
        completionHandler: @escaping (MimoReverseGeocodeResponse?, Error?) -> Void
    ) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                completionHandler(nil, error)
                return
            }
            let results = (placemarks ?? []).map { MimoReverseGeocodeResult(placemark: $0) }
            completionHandler(MimoReverseGeocodeResponse(results: results), nil)
        }
    }
}
