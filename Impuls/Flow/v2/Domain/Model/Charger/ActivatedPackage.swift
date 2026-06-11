//
//  ActivatedPackage.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 12.03.24.
//

import Foundation

struct ActivatedPackage: Decodable {
    let id: String
    let package: ServicePackage?
}

struct ServicePackage: Decodable {
    let id: String
    let name: String
    let start: Int64
    let end: Int64
}
