//
//  MimoType.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 02.05.23.
//

import Foundation

enum MimoType: Int, CaseIterable {
    case scooter
    case bike
    case charger
    case evCharger
    
    var service: String {
        switch self {
        case .scooter:
            return "SCOOTER"
        case .bike:
            return "BIKE"
        case .charger:
            return "CHARGER"
        case .evCharger:
            return "EV_CHARGER"
        }
    }
}

// TODO: - This type was temporarily added for EV Charger. Replace it with MimoType after deletion
enum MimoProductType: Int, CaseIterable {
    case scooter
    case bike
    case charger
    case evCharger
    
    var mimoType: MimoType? {
        switch self {
        case .scooter:
            return .scooter
        case .bike:
            return .bike
        case .charger:
            return .charger
        case .evCharger:
            return nil
        }
    }
    
    var service: String {
        switch self {
        case .scooter:
            return "SCOOTER"
        case .bike:
            return "BIKE"
        case .charger:
            return "CHARGER"
        case .evCharger:
            return "EV_CHARGER"
        }
    }
}
