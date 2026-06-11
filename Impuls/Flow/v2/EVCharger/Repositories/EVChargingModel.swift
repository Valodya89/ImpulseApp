//
//  EVChargingModel.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 5/4/25.
//

import Foundation

struct EVChargingModel {
    let id: String
    let state: String
    let user: String
    let stationId: String
    let connectorId: Int
    let kwt: Double?
    
    init(chargingModel: EVChargingDTO) {
        self.id = chargingModel.id
        self.state = chargingModel.state
        self.user = chargingModel.user
        self.stationId = chargingModel.stationId
        self.connectorId = chargingModel.connectorId
        self.kwt = nil//chargingModel.kwt
    }
}
