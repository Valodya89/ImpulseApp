//
//  ScooterResult.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/18/22.
//

import CoreLocation
import Foundation

class ScooterLocationCaching {
    private(set) static var cache: NSCache<AnyObject, AnyObject> = .init()

    static func getSafeLocationCoordinate(location: CLLocationCoordinate2D) -> String {
        return location.latitude.description + location.longitude.description
    }
}

struct ScooterResult: MimoResult {
    
    let id: String
    let qr: String
    let type: String
    let batteryPercent: BatteryPercent
    let remainingMileage: Mileage
    var longitude: Double
    var latitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    internal init(id: String,qr: String, type: String, batteryPercent: BatteryPercent, remainingMileage: Int, longitude: Double, latitude: Double ) {
        self.id = id
        self.qr = qr
        self.type = type
        self.longitude = longitude
        self.latitude = latitude
        self.batteryPercent = batteryPercent
        self.remainingMileage = remainingMileage
    }
    
    func toGMSMarker(animate: Bool = true) -> MimoMarker {
        let marker = MimoMarker()
        marker.icon = batteryPercent.scooterMarkerIcon
        marker.position = coordinate
        marker.appearAnimation = animate ? .pop : .none
        
        return marker
    }
    
    func toSelectedGMSMarker(animate: Bool = true) -> MimoMarker {
        let marker = MimoMarker()
        marker.icon = batteryPercent.scooterMarkerSelectedIcon
        marker.position = coordinate
        marker.appearAnimation = animate ? .pop : .none
        
        return marker
    }
}
