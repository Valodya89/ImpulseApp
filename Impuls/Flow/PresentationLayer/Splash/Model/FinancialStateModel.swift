//
//  FinancialStateModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/21/21.
//

import Foundation

enum FinancialState: String, Decodable {
    case Success = "SUCCESS"
    case ProfileIncomplete = "PROFILE_INCOMPLETE"
    case Debt = "DEBT"
    case DebtOnDevice = "DEBT_ON_DEVICE"
    case DebtOnCard = "DEBT_ON_CARD"
    case NoMinimalAmount = "NO_MINIMAL_AMOUNT"

}

struct FinancialStateModel: Decodable {
    var state: FinancialState
    let message: String?
    let additional: Double?
    let wallets: [WalletDebts]?
}

struct  WalletDebts: Codable {
    let walletId: String?
    let debtSum: Double?
}
