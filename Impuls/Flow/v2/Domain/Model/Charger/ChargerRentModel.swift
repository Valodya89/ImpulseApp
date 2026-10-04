//
//  ChargerRentModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 13.03.24.
//

import Foundation

/// A completed power-bank rent as `GET /api/rent` lists it (powerbank
/// docs/mobile-api.md "GET /api/rent"). Only `id` is required: a rent whose
/// `endStation` is null (bank never returned) or that predates a field must not
/// take the whole history page down with it.
struct ChargerRentModel: Decodable {
    let id: String
    /// `USER` for a rider-started rent; kept as the wire string.
    let initiator: String?
    let payment: ChargerRentPayment
    let user: String
    let startStation: String
    /// Null when the power bank was never returned.
    let endStation: String?
    /// The code printed on the cabinet - what the rider actually scanned. The
    /// station fields above are internal ids. Optional so the list still decodes
    /// if a rent predates the field.
    let startStationQR: String?
    let endStationQR: String?
    let powerBank: String
    let stationType: String?
    let managerRent: Bool
    let scan: Int64
    let end: Int
    let start: Int

    private enum CodingKeys: String, CodingKey {
        case id, initiator, payment, user, startStation, endStation, startStationQR, endStationQR, powerBank, stationType, managerRent, scan, end, start
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        initiator = try? container.decodeIfPresent(String.self, forKey: .initiator)
        payment = (try? container.decodeIfPresent(ChargerRentPayment.self, forKey: .payment)) ?? ChargerRentPayment()
        user = (try? container.decodeIfPresent(String.self, forKey: .user)) ?? ""
        startStation = (try? container.decodeIfPresent(String.self, forKey: .startStation)) ?? ""
        endStation = try? container.decodeIfPresent(String.self, forKey: .endStation)
        startStationQR = try? container.decodeIfPresent(String.self, forKey: .startStationQR)
        endStationQR = try? container.decodeIfPresent(String.self, forKey: .endStationQR)
        powerBank = (try? container.decodeIfPresent(String.self, forKey: .powerBank)) ?? ""
        stationType = try? container.decodeIfPresent(String.self, forKey: .stationType)
        managerRent = (try? container.decodeIfPresent(Bool.self, forKey: .managerRent)) ?? false
        scan = (try? container.decodeIfPresent(Int64.self, forKey: .scan)) ?? 0
        end = (try? container.decodeIfPresent(Int.self, forKey: .end)) ?? 0
        start = (try? container.decodeIfPresent(Int.self, forKey: .start)) ?? 0
    }
}

extension ChargerRentModel {

    /// Station as it should be shown to a rider: the QR code, never the internal id.
    var startStationCode: String {
        startStationQR ?? startStation
    }

    /// Empty when the bank was never returned.
    var endStationCode: String {
        endStationQR ?? endStation ?? ""
    }
}

/// `Rent.payment` (powerbank docs/mobile-api.md "GET /api/rent").
struct ChargerRentPayment: Decodable {
    let amount: Double?
    let billingAmount: Double?
    /// `WAITING`, `SUCCESS` or `FAILED`; `nil` for a value this build does not know.
    let status: ScooterPaymentProgress?
    let sources: [ChargerRentPaymentSource]

    private enum CodingKeys: String, CodingKey {
        case amount, billingAmount, status, sources
    }

    init(amount: Double? = nil, billingAmount: Double? = nil, status: ScooterPaymentProgress? = nil, sources: [ChargerRentPaymentSource] = []) {
        self.amount = amount
        self.billingAmount = billingAmount
        self.status = status
        self.sources = sources
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        amount = try? container.decodeIfPresent(Double.self, forKey: .amount)
        billingAmount = try? container.decodeIfPresent(Double.self, forKey: .billingAmount)
        status = try? container.decodeIfPresent(ScooterPaymentProgress.self, forKey: .status)
        sources = (try? container.decodeIfPresent([ChargerRentPaymentSource].self, forKey: .sources)) ?? []
    }
}

/// `Rent.payment.sources[]`.
struct ChargerRentPaymentSource: Decodable {
    let type: PaymentSourceType
    let minutes: Int?
    let date: Int64?

    private enum CodingKeys: String, CodingKey {
        case type, minutes, date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = (try? container.decodeIfPresent(PaymentSourceType.self, forKey: .type)) ?? .unknown("")
        minutes = try? container.decodeIfPresent(Int.self, forKey: .minutes)
        date = try? container.decodeIfPresent(Int64.self, forKey: .date)
    }
}

/// `sources[].type` (powerbank docs/mobile-api.md "GET /api/rent"): WALLET,
/// MINUTES, PACKAGE. A rent paid from a package must decode like any other;
/// anything newer lands in `.unknown` with its wire value.
enum PaymentSourceType: Equatable, Decodable {
    case wallet
    case minutes
    case package
    case unknown(String)

    init(rawValue: String) {
        switch rawValue {
        case "WALLET": self = .wallet
        case "MINUTES": self = .minutes
        case "PACKAGE": self = .package
        default: self = .unknown(rawValue)
        }
    }

    init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

    var rawValue: String {
        switch self {
        case .wallet: return "WALLET"
        case .minutes: return "MINUTES"
        case .package: return "PACKAGE"
        case .unknown(let raw): return raw
        }
    }
}
