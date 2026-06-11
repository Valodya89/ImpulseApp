//
//  PackageModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/7/21.
//

import Foundation

struct PackageModel: Decodable {
    let id: String
    let name: String
    let localizedName: String
    let description: String
    let timeUnit: String
    let duration: Double
    let popular: Bool
    let price: Double
    let logo: ImageObj
}

struct ActivePackage: Decodable {
    let id: String
    let name: String
    let start: TimeInterval
    let end: TimeInterval
    
    var startDate: Date {
        return Date(timeIntervalSince1970: start / 1000)
    }
    
    var endDate: Date {
        return Date(timeIntervalSince1970: end / 1000)
    }
}

struct ActiveTarrif: Decodable {
    let id: String
    let name: String
    let start: Double
    let end: Double
    
    var startDate: Date {
        return Date(timeIntervalSince1970: start / 1000)
    }
    
    var endDate: Date {
        return Date(timeIntervalSince1970: end / 1000)
    }
}
