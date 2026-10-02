//
//  EligibilityAPI.swift
//  Impuls
//
//  Each service answers for its own action:
//    ipay       GET api/bank/card/{provider}/eligibility
//    powerbank  GET api/rent/{id}/eligibility?action=START_RENT|BOOK&latitude&longitude
//    scooter    GET api/trip/eligibility
//    sharing    GET api/trip/eligibility?action=START_RIDE|BOOK
//    ev-charger GET api/charging/eligibility?stationId&connectorId&kwts
//

import Foundation

enum EligibilityCheck {

    enum PowerbankAction: String {
        case startRent = "START_RENT"
        case book = "BOOK"
    }

    enum SharingAction: String {
        case startRide = "START_RIDE"
        case book = "BOOK"
    }

    /// `provider` is the value passed to `api/bank/card/{provider}/attach`.
    case attachCard(provider: String)
    /// `stationId` is the value passed to `api/rent/{id}/scan`.
    case powerbank(stationId: String, action: PowerbankAction, latitude: Double?, longitude: Double?)
    case scooter
    case sharing(action: SharingAction)
    case evCharging(stationId: String, connectorId: Int, kwts: Double)
}

extension EligibilityCheck {

    /// The pre-check for an action request the backend has just refused, so a
    /// screen that only knows the error can still re-check after each step.
    init?(rejectedRequest request: URLRequest) {
        guard let url = request.url else { return nil }

        let path = url.path
        let parts = path.split(separator: "/").map(String.init)
        let absolute = url.absoluteString

        var parameters: [String: Any] = [:]
        URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.forEach { parameters[$0.name] = $0.value }
        if let body = request.httpBody,
           let json = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
            parameters.merge(json) { _, new in new }
        }

        func double(_ key: String) -> Double? {
            if let value = parameters[key] as? Double { return value }
            if let value = parameters[key] as? NSNumber { return value.doubleValue }
            if let value = parameters[key] as? String { return Double(value) }
            return nil
        }

        func isHost(_ base: MimoBaseURLs) -> Bool {
            guard let host = URL(string: base.rawValue)?.host else { return false }
            return url.host == host
        }

        if isHost(.payment), path.hasSuffix("/attach"),
           let index = parts.firstIndex(of: "card"), parts.count > index + 2 {
            self = .attachCard(provider: parts[index + 1])
        } else if isHost(.charger), path.hasSuffix("/scan"),
                  let index = parts.firstIndex(of: "rent"), parts.count > index + 2 {
            self = .powerbank(stationId: parts[index + 1], action: .startRent,
                              latitude: double("latitude"), longitude: double("longitude"))
        } else if isHost(.evCharger), absolute.contains("api/charging/initiate"),
                  let stationId = parameters["stationId"] as? String,
                  let connectorId = double("connectorId"),
                  let kwts = double("kwts") {
            self = .evCharging(stationId: stationId, connectorId: Int(connectorId), kwts: kwts)
        } else if isHost(.scooter), absolute.contains("api/trip/scan") || path.hasSuffix("/book") {
            self = .scooter
        } else if isHost(.sharing), path.hasSuffix("/book") {
            self = .sharing(action: .book)
        } else if isHost(.sharing), path.hasSuffix("/scan") {
            self = .sharing(action: .startRide)
        } else {
            return nil
        }
    }
}

extension EligibilityCheck: APIProtocol {

    var base: String {
        switch self {
        case .attachCard:
            return MimoBaseURLs.payment.rawValue
        case .powerbank:
            return MimoBaseURLs.charger.rawValue
        case .scooter:
            return MimoBaseURLs.scooter.rawValue
        case .sharing:
            return MimoBaseURLs.sharing.rawValue
        case .evCharging:
            return MimoBaseURLs.evCharger.rawValue
        }
    }

    var path: String {
        switch self {
        case .attachCard(let provider):
            return "api/bank/card/\(provider)/eligibility"
        case .powerbank(let stationId, _, _, _):
            return "api/rent/\(stationId)/eligibility"
        case .scooter, .sharing:
            return "api/trip/eligibility"
        case .evCharging:
            return "api/charging/eligibility"
        }
    }

    var header: [String: String] {
        [
            "Content-Type": "application/json",
            "locale": StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2))
        ]
    }

    var query: [String: String] {
        switch self {
        case .attachCard, .scooter:
            return [:]
        case let .powerbank(_, action, latitude, longitude):
            var query = ["action": action.rawValue]
            if let latitude, let longitude {
                query["latitude"] = String(latitude)
                query["longitude"] = String(longitude)
            }
            return query
        case .sharing(let action):
            return ["action": action.rawValue]
        case let .evCharging(stationId, connectorId, kwts):
            return [
                "stationId": stationId,
                "connectorId": String(connectorId),
                "kwts": String(kwts)
            ]
        }
    }

    var body: [String: Any]? { nil }
    var bodyString: String? { nil }
    var formData: MultipartFormData? { nil }
    var method: RequestMethod { .get }
}
