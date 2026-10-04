//
//  PaymentMethodModel.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 8/2/25.
//

import Foundation

/// One `PaymentMethodDto` of ipay `GET /api/payment-methods` (ipay
/// docs/mobile-api.md "GET /api/payment-methods", commit
/// 644cafc841d1f76a656daadd95f01f132bb463fa): `id`, `provider`, `type`,
/// `currency`, `country`, `description` and `popup` (localized), `logo`
/// (`FileData`).
///
/// Decoding is lenient: `description`, `popup` and `logo` may be missing, a
/// provider or type this build does not know keeps its raw value instead of
/// failing the whole list, and an empty `popup` counts as no popup.
struct PaymentMethodModel: Decodable, Identifiable {
    let id: String
    let currency: String
    let description: String
    let provider: PaymentMethodProvider
    let type: PaymentMethodType
    let logo: ImageDto?
    let popup: String?
}

extension PaymentMethodModel {

    private enum CodingKeys: String, CodingKey {
        case id, currency, description, provider, type, logo, popup
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let document = "PaymentMethodDto"

        let rawProvider = container.decodeLenient(String.self, forKey: .provider, in: document) ?? ""
        let rawType = container.decodeLenient(String.self, forKey: .type, in: document) ?? ""

        provider = PaymentMethodProvider(rawValue: rawProvider)
        type = PaymentMethodType(rawValue: rawType)
        currency = container.decodeLenient(String.self, forKey: .currency, in: document, default: "")
        description = container.decodeLenient(String.self, forKey: .description, in: document, default: "")
        logo = container.decodeLenient(ImageDto.self, forKey: .logo, in: document)

        let popupText = container.decodeLenient(String.self, forKey: .popup, in: document)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        popup = (popupText?.isEmpty ?? true) ? nil : popupText

        // The list is keyed by id in the grid: a row without one still needs a
        // stable key, so it is derived from what identifies the method.
        if let id = container.decodeLenient(String.self, forKey: .id, in: document), !id.isEmpty {
            self.id = id
        } else {
            LenientDecoding.report(document: document, field: "id", detail: "missing")
            id = "\(rawProvider)_\(rawType)_\(currency)"
        }

        if case .unknown(let raw) = provider {
            LenientDecoding.report(document: document, field: "provider", detail: "unknown value \(raw)")
        }
        if case .unknown(let raw) = type {
            LenientDecoding.report(document: document, field: "type", detail: "unknown value \(raw)")
        }
    }
}

/// ipay `PaymentProvider`. `unknown` carries a value this build does not know
/// so the method still lists and its raw name still reaches the backend.
enum PaymentMethodProvider: Equatable, Hashable {
    case ameriaBank
    case evocaBank
    case conversBank
    case idBank
    case tinkoff
    case idram
    case telcell
    case cryptoCloud
    case inecopay
    case fastshift
    case easypay
    case mimo
    case myameria
    case unknown(String)

    private static let known: [PaymentMethodProvider] = [
        .ameriaBank, .evocaBank, .conversBank, .idBank, .tinkoff, .idram, .telcell,
        .cryptoCloud, .inecopay, .fastshift, .easypay, .mimo, .myameria
    ]

    init(rawValue: String) {
        self = Self.known.first { $0.rawValue == rawValue } ?? .unknown(rawValue)
    }

    var rawValue: String {
        switch self {
        case .ameriaBank: return "AMERIA_BANK"
        case .evocaBank: return "EVOCA_BANK"
        case .conversBank: return "CONVERSE_BANK"
        case .idBank: return "ID_BANK"
        case .tinkoff: return "TINKOFF"
        case .idram: return "IDRAM"
        case .telcell: return "TELCELL"
        case .cryptoCloud: return "CRYPTO_CLOUD"
        case .inecopay: return "INECOPAY"
        case .fastshift: return "FASTSHIFT"
        case .easypay: return "EASYPAY"
        case .mimo: return "MIMO"
        case .myameria: return "MYAMERIA_PAY"
        case .unknown(let raw): return raw
        }
    }
}

extension PaymentMethodProvider: Decodable {
    init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }
}

/// ipay `PaymentMethodType`: `CARD, E_WALLET, CRYPTO`; `unknown` keeps any
/// other value.
enum PaymentMethodType: Equatable, Hashable {
    case card
    case eWallet
    case crypto
    case unknown(String)

    private static let known: [PaymentMethodType] = [.card, .eWallet, .crypto]

    init(rawValue: String) {
        self = Self.known.first { $0.rawValue == rawValue } ?? .unknown(rawValue)
    }

    var rawValue: String {
        switch self {
        case .card: return "CARD"
        case .eWallet: return "E_WALLET"
        case .crypto: return "CRYPTO"
        case .unknown(let raw): return raw
        }
    }
}

extension PaymentMethodType: Decodable {
    init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }
}

extension String {
    var currencyName: String {
        "IPAY_currency_\(self.lowercased())".localized()
    }
    
    var currencySymbol: String {
        "IPAY_currency_symbol_\(self.lowercased())".localized()
    }

    /// Translated currency name, or the raw code when there is no translation -
    /// `localized()` hands back the lookup key in that case, which must never
    /// reach a label. nil for an empty code.
    var currencyNameOrCode: String? {
        guard !isEmpty else { return nil }

        let name = currencyName
        return name == "IPAY_currency_\(lowercased())" ? self : name
    }
}

extension UserManager {

    /// Currency to print next to an amount: the signed-in user's wallet currency,
    /// falling back to the app-wide default when no wallet is loaded yet.
    static var walletCurrencyTitle: String {
        UserManager.share.walletModel?.currency.currencyNameOrCode
            ?? "MOBILE_global_total_currency".localized()
    }

    /// Currency to print next to an amount the backend may or may not have priced:
    /// the currency it sent when there is one, the signed-in user's wallet
    /// currency otherwise. Never returns an empty string, and never assumes AMD.
    static func currencyTitle(_ currency: String?) -> String {
        currency?.currencyNameOrCode ?? walletCurrencyTitle
    }
}
