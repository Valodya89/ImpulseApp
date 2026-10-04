//
//  FinancialStateModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/21/21.
//

import Foundation

/// ipay `State`: `SUCCESS, PROFILE_INCOMPLETE, DEBT, DEBT_ON_DEVICE,
/// DEBT_ON_CARD` (ipay docs/mobile-api.md "GET /api/state", commit
/// 644cafc841d1f76a656daadd95f01f132bb463fa). `NO_MINIMAL_AMOUNT` is a legacy
/// value the screens still distinguish.
enum FinancialState: String, Decodable {
    case Success = "SUCCESS"
    case ProfileIncomplete = "PROFILE_INCOMPLETE"
    case Debt = "DEBT"
    case DebtOnDevice = "DEBT_ON_DEVICE"
    case DebtOnCard = "DEBT_ON_CARD"
    case NoMinimalAmount = "NO_MINIMAL_AMOUNT"

}

/// The `StateDto` of ipay `GET /api/state`: `state` always; `message` (a
/// `MessageCodes` value) only on non-SUCCESS states; `additional` (typed
/// `Object`, a `double`) only on DEBT; `wallets` (`{ walletId, debtSum }`) only
/// on DEBT_ON_DEVICE / DEBT_ON_CARD. Everything but `state` is optional and
/// decoded leniently; `additional` is accepted as a number or a numeric string.
struct FinancialStateModel: Decodable {
    var state: FinancialState
    let message: String?
    let additional: Double?
    let wallets: [WalletDebts]?
    let content: ErrorContent?
}

extension FinancialStateModel {

    private enum CodingKeys: String, CodingKey {
        case state, message, additional, wallets, content
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let document = "StateDto"

        let rawState = container.decodeLenient(String.self, forKey: .state, in: document)
        guard let rawState, let state = FinancialState(rawValue: rawState.uppercased()) else {
            // Every screen switches over the known states exhaustively; a state
            // this build does not know cannot be shown, so it is reported and
            // the document is refused - callers already treat a missing state
            // as "nothing to collect".
            LenientDecoding.report(document: document, field: "state", detail: "unknown value \(rawState ?? "null")")
            throw DecodingError.dataCorruptedError(forKey: .state, in: container,
                                                   debugDescription: "Unknown financial state \(rawState ?? "null")")
        }

        self.state = state
        message = container.decodeLenient(String.self, forKey: .message, in: document)
        additional = container.decodeLenientDouble(forKey: .additional, in: document)
        wallets = container.decodeLenient([WalletDebts].self, forKey: .wallets, in: document)
        content = container.decodeLenient(ErrorContent.self, forKey: .content, in: document)
    }
}

/// `WalletDebtDto`: `{ walletId, debtSum }`.
struct  WalletDebts: Codable {
    let walletId: String?
    let debtSum: Double?

    private enum CodingKeys: String, CodingKey {
        case walletId, debtSum
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let document = "WalletDebtDto"

        walletId = container.decodeLenient(String.self, forKey: .walletId, in: document)
        debtSum = container.decodeLenientDouble(forKey: .debtSum, in: document)
    }
}

struct ErrorContent: Codable {
    let state: String?
    let message: String?
}
