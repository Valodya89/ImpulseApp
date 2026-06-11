//
//  BikeResponse.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 5/9/21.
//

import Foundation

struct BikeResponse: Codable {
    let id: String?
    let qr: String?
    let mac: String?
    let voltage: Double?
    let longitude: Double?
    let latitude: Double?
    let updated: Bool?
}
