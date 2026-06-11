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
    let powerBank: String
    let stationType: String
    let scan: Int64
    let end: Int
    let start: Int
}
