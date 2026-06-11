//
//  ScooterStateModel.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 26.07.22.
//

import Foundation

struct ScooterStateModel: Codable {
    var state: TripAction?
    let scooter: Scooter?
    let data: ScooterStateData?
}

struct Scooter: Codable {
    let id: String?
    let qr: String?
    let type: String?
    let located: LocatedData?
    let batteryPercent: BatteryPercent?
    let remainingMileage:  Int?
    let speed: Int?
}

struct LocatedData: Codable {
    let longitude: Double?
    let latitude: Double?
    let timestamp:  Double
}

struct ScooterStateData: Codable {
    let id: String?
    let state: String?
    let scan: Double?
    let start: Double?
    let end: Double?
    let speedModeTariff: SpeedModeTariff?
    let billingModeTariff: BillingModeTariff?
    let user: String?
    let scooter: String?
    let startPosition: ScooterPosition?
    let endPosition: ScooterPosition?
    let startMileage: Int?
    let endMileage: Int?
    let distance: Double?
    let amount: Double?
    let path: [ScooterPath]?
    let pauses: [Pause]?
}

public struct SpeedModeTariff: Codable {
    let id: String?
    let price: Double?
    let speedMode: String?
    let speed: Int?
}

public struct BillingModeTariff: Codable {
    let id: String?
    let mode: String?
    let minutes: Int?
    let price: Double?
}

struct ScooterPosition: Codable {
    let longitude: Double?
    let latitude: Double?
    let timestamp: Double?
}

struct ScooterPath: Codable {
    let longitude: Double?
    let latitude: Double?
    let timestamp: Double?
}

extension Array where Element == Pause {
    var sum: Int {
        return self.filter({ $0.end != nil }).compactMap({ ($0.end ?? 0) - ($0.start ?? 0) }).reduce(0, +)
    }
}
            
/*
{,
        "data": {
       
            "startPosition": {
                "longitude": 44.501554512920585,
                "latitude": 40.18494906471158,
                "timestamp": 1659140357879
            },
            "endPosition": null,
            "startMileage": 21527,
            "endMileage": 0,
            "distance": 0,
            "amount": 708.4,
            "pauses": [],
            "speedChanges": [
                {
                    "start": 1659140369261,
                    "end": null,
                    "speedModeTariffDetails": {
                        "id": "62d69822c8afb263e44f4b50",
                        "price": 28.0,
                        "speedMode": "slow",
                        "speed": 0
                    }
                }
            ]
        }
    }
*/
