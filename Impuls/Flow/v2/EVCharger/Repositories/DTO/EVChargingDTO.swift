//
//  EVChargingDTO.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 5/4/25.
//

import Foundation

struct EVChargingDTO: Decodable {
    let id: String
    let state: String
    let user: String
    let stationId: String
    let connectorId: Int
    let start: Int
    let end: Int
    
    let currentImport: Double
    let percent: Double
    let powerKw: Double
    let kwtsCharged: Double
    
    let priceConfig: PriceConfig
    let price: Price?
    
    struct PriceConfig: Decodable {
        let currency: String
        let pricePerKWt: Int
    }
    
    struct Price: Decodable {
        let currency: String?
        let amount: Double?
    }
}

struct ChargingListDto: Decodable {
    let stationId: String
    let connectorId: Int
    let connectorType: EVConnectorType
    let chargingType: EVChargingType
    let destinationAddress: String?
    let destinationName: String?
    let start: Int
    let end: Int
    let kwtsCharged: Double
    let priceConfig: PriceConfig
    let price: Price?
    let payment: Payment?
    let state: ChargingState?
    
    struct PriceConfig: Decodable {
        let currency: String
        let pricePerKWt: Int
    }
    
    struct Price: Decodable {
        let currency: String
        let amount: Double
    }
    
    struct Payment: Decodable {
        let amount: Double
    }
    
    enum ChargingState: String, Decodable {
        case failed = "FAILED"
        case finished = "FINISHED"
    }
}
