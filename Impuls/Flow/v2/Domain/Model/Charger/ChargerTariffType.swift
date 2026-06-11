//
//  ChargerTariffType.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 26.11.23.
//

import Foundation

enum ChargerTariffType {
    case start
    case standard
    case perMinute
    case daily
    
    var title: String {
        switch self {
        case .start:
            return "START"
        case .standard:
            return "STANDARD"
        case .perMinute:
            return "PER-MINUTE"
        case .daily:
            return "DAILY"
        }
    }
    
    var amount: String {
        switch self {
        case .start:
            return "0 AMD"
        case .standard:
            return "149.9 AMD"
        case .perMinute:
            return "4.99 AMD/min"
        case .daily:
            return "599 AMD/day"
        }
    }
    
    var minimal: String {
        switch self {
        case .start:
            return "5 min = 0 amd"
        case .standard:
            return "30 min = 149.9 amd"
        case .perMinute:
            return "Minimal - 4.99 amd"
        case .daily:
            return "Minimal - 599 amd"
        }
    }
    
    var order: Int {
        switch self {
        case .start:
            return 1
        case .standard:
            return 2
        case .perMinute:
            return 3
        case .daily:
            return 4
        }
    }
}
