//
//  TransactionDTO.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/31/25.
//

import Foundation

struct TransactionDTO: Decodable {
    let id: String
    let amount: Double
    let currency: String
    let status: String
    let type: TransactionProvider
    let date: Int
}

enum TransactionProvider: String, Decodable {
    case mimoPay = "MIMO_PAY"
    case mimoWithdrawalLocal = "MIMO_WITHDRAWAL_LOCAL"
    case mimoDepositLocal = "MIMO_DEPOSIT_LOCAL"
    case evocaCardAttachment = "EVOCA_CARD_ATTACHMENT"
    case idCardAttachment = "ID_CARD_ATTACHMENT"
    case idCardAttachmentMir = "ID_CARD_ATTACHMENT_MIR"
    case ameriaCardAttachment = "AMERIA_CARD_ATTACHMENT"
    case evocaDepositBinding = "EVOCA_DEPOSIT_BINDING"
    case idDepositBinding = "ID_DEPOSIT_BINDING"
    case idDepositBindingMir = "ID_DEPOSIT_BINDING_MIR"
    case ameriaDepositBinding = "AMERIA_DEPOSIT_BINDING"
    case evocaDeposit = "EVOCA_DEPOSIT"
    case tinkoffCardAttachment = "TINKOFF_CARD_ATTACHMENT"
    case tinkoffDeposit = "TINKOFF_DEPOSIT"
    case tinkoffDepositBinding = "TINKOFF_DEPOSIT_BINDING"
    case idDeposit = "ID_DEPOSIT"
    case idDepositMir = "ID_DEPOSIT_MIR"
    case ameriaDeposit = "AMERIA_DEPOSIT"
    case idramDeposit = "IDRAM_DEPOSIT"
    case idramDepositTerminal = "IDRAM_DEPOSIT_TERMINAL"
    case telcellDeposit = "TELCELL_DEPOSIT"
    case easypayDeposit = "EASYPAY_DEPOSIT"
    case cryptoCloudDeposit = "CRYPTO_CLOUD_DEPOSIT"
    case telcellTerminalDeposit = "TELCELL_TERMINAL_DEPOSIT"
    case inecoDeposit = "INECO_DEPOSIT"
    case fastshiftDepositTerminal = "FASTSHIFT_DEPOSIT_TERMINAL"
    case mimoBonus = "MIMO_BONUS"
    
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
        }
    }
}
