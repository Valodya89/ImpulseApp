//
//  SingleScooterResponse.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 28.07.22.
//

import Foundation


struct SingleScooterResponse: Codable {
    let scooter: Scooter?
    var billingTariffs: [BillingTarif]?
    var speedTariffs: [SpeedTariff]?
}

struct BillingTarif: Codable {
    let id: String?
    let title: String?
    let priceName: String?
    let description: String?
    let mode: String?
    let price: Double?
    let minutes: Int?
    let logo: ScooterTarrifLogo?
    
    // MARK: CodingKeys
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case priceName = "priceName"
        case description = "description"
        case mode = "mode"
        case price = "price"
        case minutes = "minutes"
        case logo = "logo"
    }
    
    var isSelected = false
}

struct SpeedTariff: Codable {
    let id: String?
    let title: String?
    let price: Double?
    let speed: Int?
    
    // MARK: CodingKeys
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case title = "title"
        case price = "price"
        case speed = "speed"
    }
    
    var isSelected = false
}

struct ScooterTarrifLogo: Codable {
    let id: String?
    let node: String?
}

extension SpeedTariff {
    
    var prettyPrinted: String {
        return ""
    }
}
