//
//  EVAmenity.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 3/14/25.
//

import Foundation

enum EVFacility: String, Decodable, CaseIterable {
    case hotel = "HOTEL"
    case restaurant = "RESTAURANT"
    case cafe = "CAFE"
    case mall = "MALL"
    case supermarket = "SUPERMARKET"
    case sport = "SPORT"
    case recreationArea = "RECREATION_AREA"
    case nature = "NATURE"
    case museum = "MUSEUM"
    case bikeSharing = "BIKE_SHARING"
    case busStop = "BUS_STOP"
    case taxiStand = "TAXI_STAND"
    case trainStation = "TRAIN_STATION"
    case airport = "AIRPORT"
    case carpoolParking = "CARPOOL_PARKING"
    case fuelStation = "FUEL_STATION"
    case wifi = "WIFI"
}

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
