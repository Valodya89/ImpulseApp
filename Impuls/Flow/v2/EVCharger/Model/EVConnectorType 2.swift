//
//  EVConnectorType.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 3/14/25.
//

import Foundation

enum EVConnectorType: String, Decodable, CaseIterable {
    case type1 = "TYPE_1"
    case type2 = "TYPE_2"
    case gbt = "GB_T"
    case ccs1 = "CCS_1"
    case ccs2 = "CCS_2"
    case chAdeMo = "CH_ADE_MO"
    case tesla = "TESLA"
    
    var iconName: String {
        switch self {
        case .type1:
            return "ev_TYPE_1"
        case .type2:
            return "ev_TYPE_2"
        case .gbt:
            return "ev_GB_T"
        case .ccs1:
            return "ev_CCS_1"
        case .ccs2:
            return "ev_CCS_2"
        case .chAdeMo:
            return "ev_CH_ADE_MO"
        case .tesla:
            return "ev_TESLA"
        }
    }
    
    var title: String {
        switch self {
        case .type1:
            return "J-1772"
        case .type2:
            return "Type 2"
        case .gbt:
            return "GB/T"
        case .ccs1:
            return "CCS1"
        case .ccs2:
            return "CCS2"
        case .chAdeMo:
            return "CHAdeMO"
        case .tesla:
            return "Tesla"
        }
    }
}
