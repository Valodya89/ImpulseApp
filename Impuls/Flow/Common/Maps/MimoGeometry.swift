//
//  MimoGeometry.swift
//  MimoBike
//
//  Coordinate / colour bridging between CoreLocation+UIKit and the 2GIS SDK,
//  plus a point-in-polygon test that replaces `GMSGeometryContainsLocation`.
//

import UIKit
import CoreLocation
import DGis

// MARK: - Coordinate bridging

extension CLLocationCoordinate2D {
    var geoPoint: GeoPoint {
        GeoPoint(latitude: Latitude(value: latitude), longitude: Longitude(value: longitude))
    }

    var geoPointWithElevation: GeoPointWithElevation {
        GeoPointWithElevation(latitude: Latitude(value: latitude), longitude: Longitude(value: longitude))
    }
}

extension GeoPoint {
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude.value, longitude: longitude.value)
    }
}

// MARK: - Colour bridging

extension UIColor {
    /// 2GIS `Color`. Falls back to opaque black if the conversion fails.
    var dgisColor: DGis.Color {
        DGis.Color(self) ?? DGis.Color(red: 0, green: 0, blue: 0, alpha: 1)
    }
}

// MARK: - Point in polygon (replacement for GMSGeometryContainsLocation)

/// Ray-casting point-in-polygon test. `geodesic` is accepted for call-site
/// compatibility with `GMSGeometryContainsLocation` but is ignored (the app's
/// zones are small enough that planar testing matches the previous behaviour).
@discardableResult
func mimoGeometryContainsLocation(
    _ point: CLLocationCoordinate2D,
    _ path: MimoMutablePath,
    _ geodesic: Bool
) -> Bool {
    let coords = path.coordinates
    guard coords.count > 2 else { return false }

    var isInside = false
    var j = coords.count - 1
    for i in 0..<coords.count {
        let a = coords[i]
        let b = coords[j]
        if (a.longitude > point.longitude) != (b.longitude > point.longitude) {
            let slope = (point.longitude - a.longitude) / (b.longitude - a.longitude)
            let latAtLng = a.latitude + slope * (b.latitude - a.latitude)
            if point.latitude < latAtLng {
                isInside.toggle()
            }
        }
        j = i
    }
    return isInside
}
