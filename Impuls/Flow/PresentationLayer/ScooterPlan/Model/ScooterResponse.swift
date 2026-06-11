//
//  ScooterResponse.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/18/22.
//

import Foundation

// MARK: - ScooterResponseElement
public struct ScooterResponse: Codable {
    
    // MARK: Properties
    public let id: String?
    public let qr: String?
    public let type: String?
    public let located: Located?
    public let batteryPercent: Int?
    public let remainingMileage: Int?

    // MARK: CodingKeys
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case qr = "qr"
        case type = "type"
        case located = "located"
        case batteryPercent = "batteryPercent"
        case remainingMileage = "remainingMileage"
    }

    // MARK: Initialization
    public init(id: String?, qr: String?, type: String?, batteryPercent: Int?, remainingMileage: Int?, located: Located?) {
        self.id = id
        self.qr = qr
        self.type = type
        self.batteryPercent = batteryPercent
        self.remainingMileage = remainingMileage
        self.located = located
    }
}

struct ScooterAccountDto: Decodable {
    let leasedScooters: [String]?
    let insurance: ActiveInsurance?
}

struct ActiveInsurance: Decodable {
    let activatedAt: Double
    let activeUntil: Double
}
