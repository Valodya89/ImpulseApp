//
//  Currency.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 30.06.23.
//

import Foundation

enum Currency {
    case amd
    
    var symbol: String {
        switch self {
        case .amd:
            return "֏"
        }
    }
    
    var name: String {
        switch self {
        case .amd:
            return "AMD"
        }
    }
}
