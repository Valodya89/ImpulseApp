//
//  BikeResult.swift
//  MimoBike
//
//  Created by Albert on 13.05.21.
//

import GoogleMaps
import Foundation

protocol MimoResult {
    var coordinate: CLLocationCoordinate2D { get }
}

class BikeLocationCaching {
    private(set) static var cache: NSCache<AnyObject, AnyObject> = .init()
    
    static func getSafeLocationCoordinate(location: CLLocationCoordinate2D) -> String {
        return location.latitude.description + location.longitude.description
    }
}

struct BikeResult: MimoResult {
    
    let id: String
    let qr: String
    let mac: String
    let voltage: Double
    let longitude: Double
    let latitude: Double
    let updated: Bool
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var timePrettyPrinted: String {
        let minutes = (self.voltage - 3.66) * 100 * 5
        let minutesUnwrapped = (minutes >= 0) ? minutes : 0

        let hours: Int = Int(minutesUnwrapped / 60)
        let leftedMinutes: Int = Int(minutesUnwrapped) - (hours * 60)

        let min = "MOBILE_guest_map_minutes".localized().lowercased()
        let h = "MOBILE_guest_map_hours".localized().lowercased()
        return "\(hours) \(h) \(leftedMinutes) \(min)"
    }
    
    internal init(id: String, qr: String, mac: String, voltage: Double, longitude: Double, latitude: Double, updated: Bool) {
        self.id = id
        self.qr = qr
        self.mac = mac
        self.voltage = voltage
        self.longitude = longitude
        self.latitude = latitude
        self.updated = updated
    }
    
    func toGMSMarker() -> GMSMarker {
        let marker = GMSMarker()
        marker.icon = #imageLiteral(resourceName: "ic_bike_marker")
        marker.position = coordinate
        marker.appearAnimation = .pop
        
        return marker
    }
    
    func toSelectedGMSMarker() -> GMSMarker {
        let marker = GMSMarker()
        marker.icon = "ic_markerSelected".image
        marker.position = coordinate
        marker.appearAnimation = .pop
        
        return marker
    }
}
