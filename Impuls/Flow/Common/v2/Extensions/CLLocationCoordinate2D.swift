//
//  CLLocationCoordinate2D.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.05.23.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D {
    
    func distanceInKm(from coordinate: CLLocationCoordinate2D) -> Double {
        let R = 6371.0 // Radius of the earth in km
        let dLat = (coordinate.latitude - self.latitude).radians
        let dLon = (coordinate.longitude - self.longitude).radians
        
        let a = sin(dLat/2) * sin(dLat/2) + cos(self.latitude.radians) * cos(coordinate.latitude.radians) * sin(dLon/2) * sin(dLon/2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        let d = R * c * 1000 // Distance in m
        
        return d
    }
    
    func prettyPrintedDistance(from coordinate: CLLocationCoordinate2D) -> String {
        let distance = Int(distanceInKm(from: coordinate))
        
        let km = distance / 1000
        let metr = distance % 1000
        if km > 0 {
            return "\(km) " + "MOBILE_global_kilometr".localized() + " \(metr) " + "MOBILE_global_metr".localized()
        } else {
            return "\(distance) " + "MOBILE_global_metr".localized()
        }
    }
    
    var clLocation: CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
}

extension Array where Element == CLLocationCoordinate2D {
    func center() -> CLLocationCoordinate2D {
        var maxLatitude: Double = -200;
        var maxLongitude: Double = -200;
        var minLatitude: Double = Double(MAXFLOAT);
        var minLongitude: Double = Double(MAXFLOAT);
        
        for location in self {
            if location.latitude < minLatitude {
                minLatitude = location.latitude;
            }
            
            if location.longitude < minLongitude {
                minLongitude = location.longitude;
            }
            
            if location.latitude > maxLatitude {
                maxLatitude = location.latitude;
            }
            
            if location.longitude > maxLongitude {
                maxLongitude = location.longitude;
            }
        }
        
        return CLLocationCoordinate2D(latitude: CLLocationDegrees((maxLatitude + minLatitude) * 0.5), longitude: CLLocationDegrees((maxLongitude + minLongitude) * 0.5));
    }
}
