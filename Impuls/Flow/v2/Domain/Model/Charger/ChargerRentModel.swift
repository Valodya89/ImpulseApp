//
//  ChargerRentModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 13.03.24.
//

import Foundation

struct ChargerRentModel: Decodable {
    let id: String
    let payment: Payment
    let user: String
    let startStation: String
    let endStation: String
    /// The code printed on the cabinet - what the rider actually scanned. The
    /// station fields above are internal ids. Optional so the list still decodes
    /// if a rent predates the field.
    let startStationQR: String?
    let endStationQR: String?
    let powerBank: String
    let stationType: String
    let scan: Int64
    let end: Int
    let start: Int
}

extension ChargerRentModel {

    /// Station as it should be shown to a rider: the QR code, never the internal id.
    var startStationCode: String {
        startStationQR ?? startStation
    }

    var endStationCode: String {
        endStationQR ?? endStation
    }
}
