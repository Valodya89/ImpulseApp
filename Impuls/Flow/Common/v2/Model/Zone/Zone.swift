//
//  Zone.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 29.06.23.
//

import Foundation

struct Zone: Codable {
    let id: String
    let type: ZoneType?
    let color: String?
    let borderColor: String?
    let featureCollection: MapZone?
    let active:  Bool
    let createdAt: Double?
}

struct MapZone: Codable {
    let features: [Features]?
    let type: String?
}

struct Features: Codable {
    let geometry: Geometry?
    let properties: Properties?
    let type: String?
}

struct Geometry: Codable {
    let coordinates: [[[Double]]]?
    let type: String?
}

struct Properties: Codable {
    
}

enum ZoneType: String, Codable {
    case RESTRICTED
    case FORBIDDEN
    case RIDE
    case OUT
}
