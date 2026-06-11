//
//  EVChargerAPI.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/25/25.
//

import Foundation

enum EVChargerAPI: APIProtocol {
    case getChargingStations
    case filterChargingStations(criterias: [[String: Any]])
    case getLocationList(latitude: Double, longitude: Double, radius: Double, chargingTypes: [String], connectorTypes: [String], facilities: [String], minPowerKwts: Double, maxPowerKwts: Double, stations: [String])
    case getChargingStation(id: String)
    case getChargingStationDetailed(id: String)
    case getChargingStationDetailedByStationId(stationId: String)
    case startCharging(stationId: String, connectorId: Int, kwts: Double)
    case getChargingState
    case getCharging(chargingId: String)
    case finishCharging(stationId: String)
    case getGuide
    
    var base: String {
        MimoBaseURLs.evCharger.rawValue
    }
    
    var path: String {
        switch self {
        case .getChargingStations:
            return "api/station"
        case .filterChargingStations:
            return "api/station/filter"
        case .getLocationList:
            return "api/location/list"
        case .getChargingStation(let id):
            return "api/station/\(id)"
        case .getChargingStationDetailed(let id):
            return "api/location/\(id)"
        case .getChargingStationDetailedByStationId(let stationId):
            return "api/location/by-station-id/\(stationId)"
        case .startCharging:
            return "api/charging/initiate"
        case .getChargingState:
            return "api/state"
        case .getCharging(let id):
            return "api/charging/\(id)"
        case .finishCharging(let id):
            return "api/charging/\(id)/finish"
        case .getGuide:
            return "guide/HOW_TO_USE"
        }
    }
    
    var header: [String : String] {
        switch self {
        case .getChargingStations, .filterChargingStations, .getLocationList:
            return [ "Content-Type": "application/json",
                     "locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))]
        case .getChargingStation, .getChargingStationDetailed, .getChargingStationDetailedByStationId:
            return [ "Content-Type": "application/json",
                     "locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))]
        case .startCharging, .getChargingState, .getCharging, .finishCharging, .getGuide:
            return [ "Content-Type": "application/json",
                     "locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))]
        }
    }
    
    var query: [String : String] {
        return [:]
    }
    
    var body: [String : Any]? {
        switch self {
        case .filterChargingStations(let criterias):
            return ["criteria": criterias]
        case let .getLocationList(latitude, longitude, radius, chargingTypes, connectorTypes, facilities, minPowerKwts, maxPowerKwts, stations):
            var body: [String: Any] = [
                "latitude": latitude,
                "longitude": longitude,
                "radius": radius,
                "chargingTypes": chargingTypes,
                "connectorTypes": connectorTypes,
                "facilities": facilities,
                "minPowerKwts": minPowerKwts,
                "maxPowerKwts": maxPowerKwts
            ]
            if !stations.isEmpty {
                body["stations"] = stations
            }
            return body
        case let .startCharging(stationId, connectorId, kwts):
            return [
                "stationId": stationId,
                "connectorId": connectorId,
                "kwts": kwts
            ]
        default:
        return nil
        }
    }
    
    var bodyString: String? {
        return nil
    }
    
    var formData: MultipartFormData? {
        return nil
    }
    
    var method: RequestMethod {
        switch self {
        case .getChargingStations, .getChargingStation, .getChargingStationDetailed, .getChargingStationDetailedByStationId:
            return .get
        case .filterChargingStations, .getLocationList:
            return .post
        case .startCharging, .finishCharging:
            return .post
        case .getChargingState, .getCharging:
            return .get
        case .getGuide:
            return .get
        }
    }
}
