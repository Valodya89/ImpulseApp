//
//  RentedCharger.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.11.23.
//

import Foundation

struct RentedCharger: Decodable {
    let state: RentedChargerState?
    let powerBank: PowerBank?
    let data: RentedChargerData?
}

struct RentedChargerData: Decodable {
    let id: String
    let state: RentedChargerState?
    let user: String
    let startStation: String
    let startStationQR: String
    let endStation: String?
    let powerBank: String
    let stationType: String?
    let scan: Double
    let start: Double?
    let end: Double?
    let activePackageValid: Bool?
    let activePackage: ServicePackage?
    let billingDetails: RentedChargerBillingDetails?
}

struct RentedChargerBillingDetails: Decodable {
    let amount: Double?
    let currentTariff: RentedChargerTariff?
    let nextTariff: RentedChargerTariff?
}

struct RentedChargerTariff: Decodable {
    let id: String
    let type: String
    let order: Int
    let price: Double
    let priceName: String
}

enum RentedChargerState: String, Decodable {
    case rentScanned = "RENT_SCANNED"
    case rentStarted = "RENT_STARTED"
    case rentEnded = "RENT_ENDED"
}

