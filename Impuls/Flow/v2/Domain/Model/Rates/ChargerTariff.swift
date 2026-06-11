//
//  ChargerTariff.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 09.03.24.
//

import Foundation

struct ChargerTariff: Decodable {
    let id: String
    let description: String
    let logo: ImageObj?
    let order: Int
    let price: Double
    let priceName: String
    let title: String
    let type: String
}
