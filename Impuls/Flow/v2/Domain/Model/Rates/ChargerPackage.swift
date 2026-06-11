//
//  ChargerPackage.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 09.03.24.
//

import Foundation

struct ChargerPackage: Decodable {
    let id: String
    let applicable: Bool
    let description: String
    let duration: Int
    let localizedName: String
    let logo: ImageObj?
    let name: String
    let popular: Bool
    let price: Double
    let priceName: String
    let timeUnit: String
}
