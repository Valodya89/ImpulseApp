//
//  ChargingStation.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 20.11.23.
//

import Foundation
import GoogleMaps

struct ChargingStation: Decodable, MimoResult {
    let id: String?
    /// The code printed on the cabinet - what a rider matches the row against.
    let qr: String?
    let type: String?
    let slotsCount: Int?
    let powerBanksCount: Int?
    let powerBanks: [PowerBank]?
    let location: Located?
    let destinationName: String?
    let destinationAddress: String?
    let images: [ImageObj]?
    let logo: ImageObj?
    let workingHours: String?
    let instagramUrl: String?
    let facebookUrl: String?
    let websiteUrl: String?
    let linkedinUrl: String?
    let discount: Int
    let status: String?
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: location?.latitude ?? 0, longitude: location?.longitude ?? 0)
    }
}

struct PowerBank: Decodable {
    let id: String?
    let slotNumber: Int?
    let electricQuantity: Double?
    let voltage: Int?
    let amperage: Int?
}

extension ChargingStation {

    /// Power banks the backend reports as available in the cabinet.
    var availablePowerBanksCount: Int {
        max(0, powerBanksCount ?? 0)
    }

    func toGMSMarker() -> GMSMarker {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: location?.latitude ?? 0, longitude: location?.longitude ?? 0)
        marker.appearAnimation = .none
        let slotsCount = slotsCount ?? 0
        let availableSlotsCount = powerBanksCount ?? 0
        marker.iconView = ChargerMarkerView(
            slotsCount: slotsCount - availableSlotsCount,
            avaliablePBCount: availableSlotsCount,
            discount: discount
        )
        marker.groundAnchor = .init(x: 0.3, y: 0.5)
        return marker
    }
    
    func toSelectedGMSMarker() -> GMSMarker {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: location?.latitude ?? 0, longitude: location?.longitude ?? 0)
        marker.appearAnimation = .none
        let slotsCount = slotsCount ?? 0
        let availableSlotsCount = powerBanksCount ?? 0
        marker.iconView = ChargerSelectedMarkerView(
            slotsCount: slotsCount - availableSlotsCount,
            avaliablePBCount: availableSlotsCount,
            discount: discount
        )
        marker.groundAnchor = .init(x: 0.3, y: 1)
        
        return marker
    }
}
