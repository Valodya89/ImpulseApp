//
//  ParkingResponse.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 23.01.23.
//

import Foundation
import CoreLocation
import UIKit
struct ParkingResponse: Codable {
    
    let id: String?
    let location: Location?
}

struct Location: Codable {
    let longitude: Double?
    let latitude: Double?
}

extension ParkingResponse {
    func toGMSMarker() -> MimoMarker {
        let marker = MimoMarker()
        marker.position = CLLocationCoordinate2D(latitude: location?.latitude ?? 0.0, longitude: location?.longitude ?? 0.0)
        marker.icon = #imageLiteral(resourceName: "parking_nim")
//        marker.title = "Parking\n\(id ?? "")"
        marker.appearAnimation = .pop
        marker.userData = "Parking\n\(id ?? "")"
        
        return marker
    }
}
