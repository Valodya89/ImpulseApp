//
//  HomeAPI.swift
//  MimoBike
//
//  Created by Albert on 17.05.21.
//

import Foundation

enum HomeAPI: APIProtocol {
    
    case getParkings
    case getZoneInfo
    case getTripBy(id: String)
    case pause(id: String)
    case continuePause(id: String)
    case getZones
    case getBikeZones
    case getBikes
    case getScooters
    case getScooterById(id: String)
    case scanScooter(id: String, insurance: Bool, speedModeTariff: String, billingModeTariff: String, longitude: Double, latitude: Double,  deviceId: String)
    case changeSpedTariff(tripId: String, speedId: String)
    case getNews(token: String)
    case getChargingStations
    case scanCharger(id: String, latitude: Double, longitude: Double)
    case chargerState
    case finishCheck(id: String)
    
    case availableServices(code: String)
    
    case chargerTariffs
    case chargerPackages
    case chargerPackageActivate(id: String)
    case chargerAccount
    
    case scooterAccount
    case lockLeasedScooter(id: String)
    case unlockLeasedScooter(id: String)
    case openBatteryCover(id: String)
    
    var base: String {
        switch self {
        case .getParkings:
            return MimoBaseURLs.scooter.rawValue
        case .getZoneInfo:
            return MimoBaseURLs.scooter.rawValue
        case .getBikes:
            return MimoBaseURLs.sharing.rawValue
        case .getScooters:
            return MimoBaseURLs.scooter.rawValue
        case .getScooterById:
            return MimoBaseURLs.scooter.rawValue
        case .scanScooter, .getZones:
            return MimoBaseURLs.scooter.rawValue
        case .getBikeZones:
            return MimoBaseURLs.sharing.rawValue
        case .pause, .continuePause, .getTripBy:
            return MimoBaseURLs.scooter.rawValue
        case .changeSpedTariff:
            return MimoBaseURLs.scooter.rawValue
        case .getNews:
            return MimoBaseURLs.accounts.rawValue
        case .getChargingStations, .scanCharger, .chargerState:
            return MimoBaseURLs.charger.rawValue
        case .finishCheck:
            return MimoBaseURLs.scooter.rawValue
        case .chargerTariffs, .chargerPackages, .chargerPackageActivate, .chargerAccount:
            return MimoBaseURLs.charger.rawValue
        case .availableServices:
            return MimoBaseURLs.accounts.rawValue
        case .scooterAccount, .lockLeasedScooter, .unlockLeasedScooter, .openBatteryCover:
            return MimoBaseURLs.scooter.rawValue
        }
    }
    
    var path: String {
        switch self {
        case .getParkings:
            return "api/parking"
        case .getZoneInfo:
            return "api/zones/info"
        case .getBikes:
            return "bike/list"
        case .getScooters:
            return "api/scooter"
        case .getScooterById(let id):
            return "api/scooter/\(id)"
        case .scanScooter:
            return "api/trip/scan"
        case .getZones:
            return "api/zones"
        case .getBikeZones:
            return "api/riding-zones"
        case .pause(let id):
            return "api/trip/\(id)/pause"
        case .continuePause(let id):
            return "api/trip/\(id)/continue"
        case .changeSpedTariff(let tripId, _):
            return "api/trip/\(tripId)/speed-change"
        case .getNews:
            return "api/news"
        case .getTripBy(let id):
            return "api/trip/\(id)"
        case .getChargingStations:
            return "api/station"
        case let .scanCharger(id: id, latitude: _, longitude: _):
            return "api/rent/\(id)/scan"
        case .chargerState:
            return "api/state"
        case .finishCheck(let id):
            return "api/trip/\(id)/finish/check"
        case .chargerTariffs:
            return "api/tariff"
        case .chargerPackages:
            return "api/package/list"
        case let .chargerPackageActivate(id: id):
            return "api/package/\(id)/activate"
        case .availableServices:
            return "available-services/list"
        case .chargerAccount:
            return "api/account"
        case .scooterAccount:
            return "api/scooter-account"
        case .lockLeasedScooter(let id):
            return "api/scooter/leased/v2/\(id)/lock"
        case .unlockLeasedScooter(let id):
            return "api/scooter/leased/v2/\(id)/unlock"
        case .openBatteryCover(let id):
            return "api/scooter/leased/v2/\(id)/open-battery-cover"
        }
    }
    
    var header: [String : String] {
        switch self {
        case .getNews(let token):
            return [
                "Authorization": "Bearer \(token)",
                "Content-Type": "application/json",
                "locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
            ]
        case .getScooterById, .scooterAccount:
            return ["locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))]
        case .scanScooter, .getZones, .chargerState:
            return [
                "Content-Type": "application/json"
            ]
        case .scanCharger:
            return [
                "Content-Type": "application/json",
                "locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.current.deviceLanguageCode)
            ]
        case .pause, .continuePause, .changeSpedTariff, .getTripBy, .finishCheck:
            return [
                "Content-Type": "application/json"
            ]
        case .getZoneInfo, .getChargingStations:
            return [ "Content-Type": "application/json",
                     "locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))]
        case .chargerPackages, .chargerTariffs:
            return [
                "locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.current.deviceLanguageCode)
            ]
        default:
            return [:]
        }
    }
    
    var query: [String : String] {
        switch self {
        case .changeSpedTariff(_, let speedId):
            return ["speedModeTariff" : speedId]
        case let .availableServices(code: code):
            return ["countryCode": code]
        default:
            return [:]
        }
    }
//    let str = "{\n    \"criteria\": [\n    {\n        \"fieldName\": \"qr\",\n        \"fieldValue\": \"\(qr)\",\n        \"searchOperation\": \"EQUALS\"\n    }\n ]\n }"
    var bodyString: String? {
        switch self {
        case let .scanScooter(id, insurance, speedModeTariff, billingModeTariff, longitude, latitude, deviceId):
            let str = "{\n    \"id\": \"\(id)\",\n    \"insurance\": \"\(insurance)\",\n    \"speedModeTariff\": \"\(speedModeTariff)\",\n    \"billingModeTariff\": \"\(billingModeTariff)\",\n    \"deviceId\": \"\(deviceId)\",\n    \"location\": {\n    \"longitude\" : \(longitude),\n    \"latitude\" : \(latitude)   }\n   \n}"
            print("bodyString = \(str)")
            return str
        case let .scanCharger(id: _, latitude: latitude, longitude: longitude):
            let str = "{\"latitude\": \(latitude),\n\"longitude\": \(longitude)}"
            return str
        default: return nil
        }
    }

    var body: [String : Any]? {
        switch self {
        case .getBikes, .getScooters, .getChargingStations, .scanCharger, .chargerState, .getScooterById, .scanScooter, .getZones, .getBikeZones, .getZoneInfo, .getParkings:
            return nil
        case .pause, .continuePause, .changeSpedTariff, .getNews, .getTripBy, .finishCheck:
            return nil
        case .chargerPackages, .chargerTariffs, .chargerPackageActivate:
            return nil
        case .availableServices, .chargerAccount, .scooterAccount, .lockLeasedScooter, .unlockLeasedScooter, .openBatteryCover:
            return nil
        }
    }
    
    var method: RequestMethod {
        switch self {
        case .getBikes, .getScooters, .getChargingStations, .chargerState, .getScooterById, .getZones, .getBikeZones, .getNews, .getTripBy, .getZoneInfo, .getParkings:
            return .get
        case .scanScooter:
            return .post
        case .pause, .continuePause, .changeSpedTariff, .scanCharger, .finishCheck:
            return .post
        case .chargerPackages, .chargerTariffs:
            return .get
        case .chargerPackageActivate:
            return .patch
        case .availableServices:
            return .get
        case .chargerAccount, .scooterAccount:
            return .get
        case .lockLeasedScooter, .unlockLeasedScooter, .openBatteryCover:
            return .post
        }
    }
    
    var formData: MultipartFormData? {
        return nil
    }
}
