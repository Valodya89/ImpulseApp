//
//  EVConnectorState.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 8/1/25.
//

import Foundation

enum EVConnectorState: String, Decodable {
    case available = "AVAILABLE"
    case preparing = "PREPARING"
    case charging = "CHARGING"
    case suspendedEvse = "SUSPENDED_EVSE"
    case suspendedEv = "SUSPENDED_EV"
    case finishing = "FINISHING"
    case reserved = "RESERVED"
    case unavailable = "UNAVAILABLE"
    case faulted = "FAULTED"
}
