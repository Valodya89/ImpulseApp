//
//  HomeMapper.swift
//  MimoBike
//
//  Created by Albert on 13.05.21.
//

import Foundation

final class HomeMapper {
    static func toBikeResults(from response: [BikeResponse]) -> [BikeResult] {
        let bikeResults: [BikeResult] = response.compactMap({ BikeResult(id: $0.id ?? "",
                                                                         qr: $0.qr ?? "",
                                                                         mac: $0.mac ?? "",
                                                                         voltage: $0.voltage ?? 0,
                                                                         longitude: $0.longitude ?? 0,
                                                                         latitude: $0.latitude ?? 0,
                                                                         updated: $0.updated ?? false) })
        return bikeResults
    }
    
    static func toScooterResults(from response: [ScooterResponse]) -> [ScooterResult] {
        let scooterResults: [ScooterResult] = response.compactMap({ ScooterResult(id: $0.id ?? "",
                                                                                  qr: $0.qr ?? "",
                                                                                  type: $0.type ?? "",
                                                                                  batteryPercent: $0.batteryPercent ?? 0,
                                                                                  remainingMileage: $0.remainingMileage ?? 0,
                                                                                  longitude: $0.located?.longitude ?? 0.0,
                                                                                  latitude: $0.located?.latitude ?? 0.0) })
        return scooterResults
    }
}
