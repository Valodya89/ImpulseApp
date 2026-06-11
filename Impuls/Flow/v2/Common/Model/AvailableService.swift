//
//  AvailableService.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 12.03.24.
//

import Foundation

struct AvailableService: Decodable {
    let id: String
    let countryCode: String
    let service: String
}
