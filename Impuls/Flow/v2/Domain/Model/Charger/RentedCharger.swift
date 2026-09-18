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

    private enum CodingKeys: String, CodingKey {
        case id, state, user, startStation, startStationQR, endStation, powerBank, stationType, scan, start, end, activePackageValid, activePackage, billingDetails
    }

    /// Only the id is required. The socket's RENT_ENDED message and the state
    /// endpoint do not always carry every field the scan response does, and a
    /// message that failed to decode was silently dropped - so the app never
    /// learned the rent was over.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        state = try? container.decodeIfPresent(RentedChargerState.self, forKey: .state)
        user = try container.decodeIfPresent(String.self, forKey: .user) ?? ""
        startStation = try container.decodeIfPresent(String.self, forKey: .startStation) ?? ""
        startStationQR = try container.decodeIfPresent(String.self, forKey: .startStationQR) ?? ""
        endStation = try container.decodeIfPresent(String.self, forKey: .endStation)
        powerBank = try container.decodeIfPresent(String.self, forKey: .powerBank) ?? ""
        stationType = try container.decodeIfPresent(String.self, forKey: .stationType)
        scan = try container.decodeIfPresent(Double.self, forKey: .scan) ?? 0
        start = try container.decodeIfPresent(Double.self, forKey: .start)
        end = try container.decodeIfPresent(Double.self, forKey: .end)
        activePackageValid = try container.decodeIfPresent(Bool.self, forKey: .activePackageValid)
        activePackage = try? container.decodeIfPresent(ServicePackage.self, forKey: .activePackage)
        billingDetails = try? container.decodeIfPresent(RentedChargerBillingDetails.self, forKey: .billingDetails)
    }
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

