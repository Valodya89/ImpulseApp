//
//  PaymentMethodModel.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 8/2/25.
//

import Foundation

struct PaymentMethodModel: Decodable, Identifiable {
    let id: String
    let currency: String
    let description: String
    let provider: PaymentMethodProvider
    let type: PaymentMethodType
    let logo: ImageDto?
    let popup: String?
}

enum PaymentMethodProvider: String, Decodable {
    case ameriaBank = "AMERIA_BANK"
    case evocaBank = "EVOCA_BANK"
    case idBank = "ID_BANK"
    case tinkoff = "TINKOFF"
    case idram = "IDRAM"
    case telcell = "TELCELL"
    case cryptoCloud = "CRYPTO_CLOUD"
    case inecopay = "INECOPAY"
    case fastshift = "FASTSHIFT"
    case mimo = "MIMO"
}

enum PaymentMethodType: String, Decodable {
    case card = "CARD"
    case eWallet = "E_WALLET"
    case crypto = "CRYPTO"
}

extension String {
    var currencyName: String {
        "IPAY_currency_\(self.lowercased())".localized()
    }
    
    var currencySymbol: String {
        "IPAY_currency_symbol_\(self.lowercased())".localized()
    }
}
