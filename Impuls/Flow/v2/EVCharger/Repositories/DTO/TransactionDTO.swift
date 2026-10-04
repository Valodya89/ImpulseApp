//
//  TransactionDTO.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/31/25.
//

import Foundation

/// One `TransactionDto` of ipay `GET /api/transactions` (ipay
/// docs/mobile-api.md "GET /api/transactions", commit
/// 644cafc841d1f76a656daadd95f01f132bb463fa): `id`, `amount` (`BigDecimal`),
/// `date` (epoch millis), `status` (`WAITING, CHARGE, REJECT, DEBT, REFUND`),
/// `type` (`TransactionType`, open-ended), `currency`.
///
/// Decoding is lenient: a row never fails the page. Missing text is empty,
/// a missing amount or date is 0, a missing currency falls back to the wallet
/// currency when shown, and a `type` this build does not know is kept as
/// `.other(raw)`.
struct TransactionDTO: Decodable {
    let id: String
    let amount: Double
    let currency: String
    let status: String
    let type: TransactionProvider
    let date: Int
}

extension TransactionDTO {

    private enum CodingKeys: String, CodingKey {
        case id, amount, currency, status, type, date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let document = "TransactionDto"

        amount = container.decodeLenientDouble(forKey: .amount, in: document) ?? 0
        currency = container.decodeLenient(String.self, forKey: .currency, in: document, default: "")
        status = container.decodeLenient(String.self, forKey: .status, in: document, default: "")
        date = container.decodeLenientInt(forKey: .date, in: document) ?? 0

        let rawType = container.decodeLenient(String.self, forKey: .type, in: document) ?? ""
        type = TransactionProvider(rawValue: rawType)
        if case .other = type {
            LenientDecoding.report(document: document, field: "type", detail: "unknown value \(rawType)")
        }

        // Rows are keyed by id in the lists; a row without one gets a key
        // derived from what it is so it still renders and does not collide.
        if let id = container.decodeLenient(String.self, forKey: .id, in: document), !id.isEmpty {
            self.id = id
        } else {
            LenientDecoding.report(document: document, field: "id", detail: "missing")
            id = "\(rawType)_\(date)_\(amount)"
        }
    }

    /// Currency to print next to the amount. `GET /api/transactions` returns a
    /// raw `Currency` code, which is translated here the same way every other
    /// amount in the app is; when a row carries no currency it falls back to the
    /// signed-in user's wallet currency, so an amount is never shown bare.
    var currencyTitle: String {
        currency.currencyNameOrCode ?? UserManager.walletCurrencyTitle
    }
}

/// ipay `TransactionType`. The backend's list is open-ended ("see the full
/// list in model/lcp/TransactionType.java", e.g. `CONVERSE_DEPOSIT`,
/// `MERCADO_PAGO_DEPOSIT`), so a value this build does not know is kept as
/// `.other(raw)`: the row shows a generic label and name-based filters (the
/// `*_CARD_ATTACHMENT` rows the history hides) keep working on `rawValue`.
enum TransactionProvider: Equatable, Hashable {
    case mimoPay
    case mimoWithdrawalLocal
    case mimoDepositLocal
    case evocaCardAttachment
    case idCardAttachment
    case idCardAttachmentMir
    case ameriaCardAttachment
    case evocaDepositBinding
    case idDepositBinding
    case idDepositBindingMir
    case ameriaDepositBinding
    case evocaDeposit
    case tinkoffCardAttachment
    case tinkoffDeposit
    case tinkoffDepositBinding
    case idDeposit
    case idDepositMir
    case ameriaDeposit
    case idramDeposit
    case idramDepositTerminal
    case telcellDeposit
    case easypayDeposit
    case cryptoCloudDeposit
    case telcellTerminalDeposit
    case inecoDeposit
    case fastshiftDepositTerminal
    case mimoBonus
    /// A type this build does not know, with the value the backend sent.
    case other(String)

    private static let known: [TransactionProvider] = [
        .mimoPay, .mimoWithdrawalLocal, .mimoDepositLocal,
        .evocaCardAttachment, .idCardAttachment, .idCardAttachmentMir, .ameriaCardAttachment,
        .evocaDepositBinding, .idDepositBinding, .idDepositBindingMir, .ameriaDepositBinding,
        .evocaDeposit, .tinkoffCardAttachment, .tinkoffDeposit, .tinkoffDepositBinding,
        .idDeposit, .idDepositMir, .ameriaDeposit, .idramDeposit, .idramDepositTerminal,
        .telcellDeposit, .easypayDeposit, .cryptoCloudDeposit, .telcellTerminalDeposit,
        .inecoDeposit, .fastshiftDepositTerminal, .mimoBonus
    ]

    init(rawValue: String) {
        self = Self.known.first { $0.rawValue == rawValue } ?? .other(rawValue)
    }

    var rawValue: String {
        switch self {
        case .mimoPay: return "MIMO_PAY"
        case .mimoWithdrawalLocal: return "MIMO_WITHDRAWAL_LOCAL"
        case .mimoDepositLocal: return "MIMO_DEPOSIT_LOCAL"
        case .evocaCardAttachment: return "EVOCA_CARD_ATTACHMENT"
        case .idCardAttachment: return "ID_CARD_ATTACHMENT"
        case .idCardAttachmentMir: return "ID_CARD_ATTACHMENT_MIR"
        case .ameriaCardAttachment: return "AMERIA_CARD_ATTACHMENT"
        case .evocaDepositBinding: return "EVOCA_DEPOSIT_BINDING"
        case .idDepositBinding: return "ID_DEPOSIT_BINDING"
        case .idDepositBindingMir: return "ID_DEPOSIT_BINDING_MIR"
        case .ameriaDepositBinding: return "AMERIA_DEPOSIT_BINDING"
        case .evocaDeposit: return "EVOCA_DEPOSIT"
        case .tinkoffCardAttachment: return "TINKOFF_CARD_ATTACHMENT"
        case .tinkoffDeposit: return "TINKOFF_DEPOSIT"
        case .tinkoffDepositBinding: return "TINKOFF_DEPOSIT_BINDING"
        case .idDeposit: return "ID_DEPOSIT"
        case .idDepositMir: return "ID_DEPOSIT_MIR"
        case .ameriaDeposit: return "AMERIA_DEPOSIT"
        case .idramDeposit: return "IDRAM_DEPOSIT"
        case .idramDepositTerminal: return "IDRAM_DEPOSIT_TERMINAL"
        case .telcellDeposit: return "TELCELL_DEPOSIT"
        case .easypayDeposit: return "EASYPAY_DEPOSIT"
        case .cryptoCloudDeposit: return "CRYPTO_CLOUD_DEPOSIT"
        case .telcellTerminalDeposit: return "TELCELL_TERMINAL_DEPOSIT"
        case .inecoDeposit: return "INECO_DEPOSIT"
        case .fastshiftDepositTerminal: return "FASTSHIFT_DEPOSIT_TERMINAL"
        case .mimoBonus: return "MIMO_BONUS"
        case .other(let raw): return raw
        }
    }
    
    var isIncomeing: Bool {
        switch self {
        case .mimoPay,
                .mimoWithdrawalLocal:
            return false
        case .mimoDepositLocal,
                .evocaCardAttachment,
                .idCardAttachment,
                .idCardAttachmentMir,
                .ameriaCardAttachment,
                .evocaDepositBinding,
                .idDepositBinding,
                .idDepositBindingMir,
                .ameriaDepositBinding,
                .evocaDeposit,
                .tinkoffCardAttachment,
                .tinkoffDeposit,
                .tinkoffDepositBinding,
                .idDeposit,
                .idDepositMir,
                .ameriaDeposit,
                .idramDeposit,
                .idramDepositTerminal,
                .telcellDeposit,
                .easypayDeposit,
                .cryptoCloudDeposit,
                .telcellTerminalDeposit,
                .inecoDeposit,
                .fastshiftDepositTerminal,
                .mimoBonus:
            return true
        case .other(let raw):
            // Unknown types are almost always a new deposit rail; only a
            // withdrawal names itself as spending.
            return !raw.contains("WITHDRAWAL")
        }
    }
}

extension TransactionProvider: Decodable {
    init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }
}
