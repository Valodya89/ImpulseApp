//
//  TariffModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/7/21.
//

import Foundation

struct TariffModel: Decodable {
    let id: String
    let name: String
    let priceName: String
    let description: String
    let pricing: Double
    let type: String
    let activable: Bool
    let active: Bool
    let logo: ImageObj
    let order: Int
    let code: String
    let extendedDetails: [ExtendedDetail]?
    
    func getDescription() -> String {
        return "\(pricing) \("MOBILE_global_total_currency".localized())/MINUTE"
    }
}

struct ExtendedDetail: Decodable {
    let order: Int
    let name: String
    let priceName: String
    let description: String
}
