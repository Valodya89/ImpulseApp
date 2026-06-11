//
//  EVAmenity.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 3/14/25.
//

import Foundation

enum EVAmenity: String, Decodable, CaseIterable {
    case wifi = "WIFI"
    case restroom = "RESTROOM"
    case restaurant = "RESTAURANT"
    case shopping = "SHOPPING"
    case park = "PARK"
    case lodging = "LODGING"
    
    var iconName: String {
        switch self {
        case .wifi:
            return "ev_WIFI"
        case .restroom:
            return "ev_RESTROOM"
        case .restaurant:
            return "ev_RESTAURANT"
        case .shopping:
            return "ev_SHOPPING"
        case .park:
            return "ev_PARK"
        case .lodging:
            return "ev_LODGING"
        }
    }
    
    var title: String {
        switch self {
        case .wifi:
            return "EV_CHARGER_wi_fi".localized()
        case .restroom:
            return "EV_CHARGER_restrooms".localized()
        case .restaurant:
            return "EV_CHARGER_restaurants".localized()
        case .shopping:
            return "EV_CHARGER_shopping".localized()
        case .park:
            return "EV_CHARGER_park".localized()
        case .lodging:
            return "EV_CHARGER_lodging".localized()
        }
    }
}
