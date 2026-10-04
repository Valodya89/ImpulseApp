//
//  RentedCharger.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.11.23.
//

import Foundation

/// One `StateMessagedDto` - an entry of `GET /api/state`, the body of
/// `POST /api/rent/{id}/scan` or a STOMP frame (powerbank docs/mobile-api.md
/// "GET /api/state", docs/events.md "WebSocket / STOMP pushes").
///
/// Decoding is lenient on purpose: a value this build does not know must never
/// fail the whole state list or drop a frame the screens could still use. Only
/// the shape of the document itself (a JSON object) is required.
struct RentedCharger: Decodable {
    /// The three states the screens distinguish. `nil` for every other
    /// documented state (NONE, BOOKING_*, RENT_NOT_STARTED) and for a value this
    /// build does not know - see `rentState` for the exact one.
    let state: RentedChargerState?
    /// The exact `state` as the backend documents it, unknown values included.
    let rentState: PowerBankRentState
    /// The current `PowerBank` document for the relevant power bank.
    let powerBank: PowerBank?
    /// The `ActiveRent`. `nil` for booking frames - their `data` is a `Booking`,
    /// not a rent - and when the body does not parse.
    let data: RentedChargerData?

    /// A rent frame (`RENT_*`), i.e. `data` is an `ActiveRent` when present.
    var isRent: Bool { rentState.isRent }
    /// A booking frame (`BOOKING_*`): never route it into rent handling.
    var isBooking: Bool { rentState.isBooking }

    private enum CodingKeys: String, CodingKey {
        case state, powerBank, data
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let rawState = try? container.decodeIfPresent(String.self, forKey: .state)
        rentState = rawState.map(PowerBankRentState.init(rawValue:)) ?? .none
        state = rentState.displayState
        powerBank = try? container.decodeIfPresent(PowerBank.self, forKey: .powerBank)

        if rentState.isBooking {
            data = nil
        } else {
            data = try? container.decodeIfPresent(RentedChargerData.self, forKey: .data)
        }
    }

    init(state: RentedChargerState?, powerBank: PowerBank?, data: RentedChargerData?) {
        self.state = state
        self.rentState = state.map(PowerBankRentState.init) ?? .none
        self.powerBank = powerBank
        self.data = data
    }
}

/// The `ActiveRent` document.
struct RentedChargerData: Decodable {
    let id: String
    let state: RentedChargerState?
    let user: String
    let startStation: String
    let startStationQR: String
    let endStation: String?
    let powerBank: String
    let stationType: String?
    let scan: Double
    let start: Double?
    let end: Double?
    let managerRent: Bool
    let activePackageValid: Bool?
    let activePackage: ServicePackage?
    let billingDetails: RentedChargerBillingDetails?

    private enum CodingKeys: String, CodingKey {
        case id, state, user, startStation, startStationQR, endStation, powerBank, stationType, scan, start, end, managerRent, activePackageValid, activePackage, billingDetails
    }

    /// Only the id is required. The socket's RENT_ENDED message and the state
    /// endpoint do not always carry every field the scan response does, and a
    /// message that failed to decode was silently dropped - so the app never
    /// learned the rent was over.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        state = try? container.decodeIfPresent(RentedChargerState.self, forKey: .state)
        user = (try? container.decodeIfPresent(String.self, forKey: .user)) ?? ""
        startStation = (try? container.decodeIfPresent(String.self, forKey: .startStation)) ?? ""
        startStationQR = (try? container.decodeIfPresent(String.self, forKey: .startStationQR)) ?? ""
        endStation = try? container.decodeIfPresent(String.self, forKey: .endStation)
        powerBank = (try? container.decodeIfPresent(String.self, forKey: .powerBank)) ?? ""
        stationType = try? container.decodeIfPresent(String.self, forKey: .stationType)
        scan = (try? container.decodeIfPresent(Double.self, forKey: .scan)) ?? 0
        start = try? container.decodeIfPresent(Double.self, forKey: .start)
        end = try? container.decodeIfPresent(Double.self, forKey: .end)
        managerRent = (try? container.decodeIfPresent(Bool.self, forKey: .managerRent)) ?? false
        activePackageValid = try? container.decodeIfPresent(Bool.self, forKey: .activePackageValid)
        activePackage = try? container.decodeIfPresent(ServicePackage.self, forKey: .activePackage)
        billingDetails = try? container.decodeIfPresent(RentedChargerBillingDetails.self, forKey: .billingDetails)
    }
}

struct RentedChargerBillingDetails: Decodable {
    let amount: Double?
    let currentTariff: RentedChargerTariff?
    let nextTariff: RentedChargerTariff?

    private enum CodingKeys: String, CodingKey {
        case amount, currentTariff, nextTariff
    }

    /// A tariff that does not parse must not take the amount down with it.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        amount = try? container.decodeIfPresent(Double.self, forKey: .amount)
        currentTariff = try? container.decodeIfPresent(RentedChargerTariff.self, forKey: .currentTariff)
        nextTariff = try? container.decodeIfPresent(RentedChargerTariff.self, forKey: .nextTariff)
    }
}

/// `TariffDto` (powerbank docs/mobile-api.md "GET /api/tariff/list").
struct RentedChargerTariff: Decodable {
    let id: String
    /// `FIXED`, `MINUTE_PER_MINUTE` or `DAILY`; kept as the wire string.
    let type: String
    let order: Int
    /// A decimal on the wire (e.g. `20.0`).
    let price: Double
    let priceName: String
    let title: String?
    /// Omitted entirely for `MINUTE_PER_MINUTE`.
    let duration: Int?

    private enum CodingKeys: String, CodingKey {
        case id, type, order, price, priceName, title, duration
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decodeIfPresent(String.self, forKey: .id)) ?? ""
        type = (try? container.decodeIfPresent(String.self, forKey: .type)) ?? ""
        order = (try? container.decodeIfPresent(Int.self, forKey: .order)) ?? 0
        price = (try? container.decodeIfPresent(Double.self, forKey: .price)) ?? 0
        priceName = (try? container.decodeIfPresent(String.self, forKey: .priceName)) ?? ""
        title = try? container.decodeIfPresent(String.self, forKey: .title)
        duration = try? container.decodeIfPresent(Int.self, forKey: .duration)
    }
}

/// The rent states the screens act on. Decoded with `try?` everywhere, so a
/// value outside these three reads as `nil`; `PowerBankRentState` carries the
/// full documented set.
enum RentedChargerState: String, Decodable {
    case rentScanned = "RENT_SCANNED"
    case rentStarted = "RENT_STARTED"
    case rentEnded = "RENT_ENDED"
}

/// `StateMessagedDto.state` as documented in powerbank docs/events.md
/// ("WebSocket / STOMP pushes"): NONE, BOOKING_STARTED, BOOKING_ENDED,
/// RENT_SCANNED, RENT_STARTED, RENT_NOT_STARTED, RENT_ENDED. Anything else the
/// backend may add later lands in `.unknown` with its wire value.
enum PowerBankRentState: Equatable {
    case none
    case bookingStarted
    case bookingEnded
    case rentScanned
    case rentStarted
    case rentNotStarted
    case rentEnded
    case unknown(String)

    init(rawValue: String) {
        switch rawValue {
        case "NONE": self = .none
        case "BOOKING_STARTED": self = .bookingStarted
        case "BOOKING_ENDED": self = .bookingEnded
        case "RENT_SCANNED": self = .rentScanned
        case "RENT_STARTED": self = .rentStarted
        case "RENT_NOT_STARTED": self = .rentNotStarted
        case "RENT_ENDED": self = .rentEnded
        default: self = .unknown(rawValue)
        }
    }

    init(_ state: RentedChargerState) {
        switch state {
        case .rentScanned: self = .rentScanned
        case .rentStarted: self = .rentStarted
        case .rentEnded: self = .rentEnded
        }
    }

    var rawValue: String {
        switch self {
        case .none: return "NONE"
        case .bookingStarted: return "BOOKING_STARTED"
        case .bookingEnded: return "BOOKING_ENDED"
        case .rentScanned: return "RENT_SCANNED"
        case .rentStarted: return "RENT_STARTED"
        case .rentNotStarted: return "RENT_NOT_STARTED"
        case .rentEnded: return "RENT_ENDED"
        case .unknown(let raw): return raw
        }
    }

    /// `data` is an `ActiveRent`.
    var isRent: Bool {
        switch self {
        case .rentScanned, .rentStarted, .rentNotStarted, .rentEnded: return true
        case .none, .bookingStarted, .bookingEnded, .unknown: return false
        }
    }

    /// `data` is a `Booking`.
    var isBooking: Bool {
        switch self {
        case .bookingStarted, .bookingEnded: return true
        case .none, .rentScanned, .rentStarted, .rentNotStarted, .rentEnded, .unknown: return false
        }
    }

    /// The state the screens switch on, or `nil` when they have nothing to do.
    var displayState: RentedChargerState? {
        switch self {
        case .rentScanned: return .rentScanned
        case .rentStarted: return .rentStarted
        case .rentEnded: return .rentEnded
        case .none, .bookingStarted, .bookingEnded, .rentNotStarted, .unknown: return nil
        }
    }
}

extension PowerBankRentState: Decodable {
    init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }
}
