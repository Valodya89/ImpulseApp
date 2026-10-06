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

/// Impulse is a power-bank rental app: its backend has no scooter, bike or EV
/// charging deployment (those hosts do not even resolve), so the app must never
/// call those services. Gate every per-product request on this list.
extension MimoProductType {
    static let offeredByThisApp: [MimoProductType] = [.charger]

    var isOfferedByThisApp: Bool { MimoProductType.offeredByThisApp.contains(self) }
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
