//
//  EVChargingType.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 3/14/25.
//

import Foundation

enum EVChargingType: String, Decodable, CaseIterable {
    case standard = "STANDARD"
    case faster = "FASTER"
    case superFast = "SUPER_FAST"
    
    var iconName: String {
        switch self {
        case .standard:
            return "ev_charging_type_STANDARD"
        case .faster:
            return "ev_charging_type_FASTER"
        case .superFast:
            return "ev_charging_type_SUPER_FAST"
        }
    }
    
    var title: String {
        switch self {
        case .standard:
            return "Standard"
        case .faster:
            return "Faster"
        case .superFast:
            return "Super Fast"
        }
    }
}
