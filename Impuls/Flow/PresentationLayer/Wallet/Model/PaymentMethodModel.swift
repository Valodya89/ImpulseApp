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
    case conversBank = "CONVERSE_BANK"
    case idBank = "ID_BANK"
    case tinkoff = "TINKOFF"
    case idram = "IDRAM"
    case telcell = "TELCELL"
    case cryptoCloud = "CRYPTO_CLOUD"
    case inecopay = "INECOPAY"
    case fastshift = "FASTSHIFT"
    case easypay = "EASYPAY"
    case mimo = "MIMO"
    case myameria = "MYAMERIA_PAY"
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
