//
//  ParkingResponse.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 23.01.23.
//

import Foundation
import GoogleMaps

struct ParkingResponse: Codable {
    
    let id: String?
    let location: Location?
}

struct Location: Codable {
    let longitude: Double?
    let latitude: Double?
}

extension ParkingResponse {
    func toGMSMarker() -> GMSMarker {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: location?.latitude ?? 0.0, longitude: location?.longitude ?? 0.0)
        marker.icon = #imageLiteral(resourceName: "parking_nim")
//        marker.title = "Parking\n\(id ?? "")"
        marker.appearAnimation = .pop
        marker.userData = "Parking\n\(id ?? "")"
        
        return marker
    }
}
