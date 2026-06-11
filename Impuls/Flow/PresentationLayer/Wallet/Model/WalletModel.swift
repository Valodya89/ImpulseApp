//
//  WalletModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/2/21.
//

import Foundation

struct WalletModel: Decodable {
    let id: String
    let balance: Double
    let currency: String
//    let creationDate: Int
    let card: WalletCard?
    let hasOldCards: Bool
//    let debts: [UserDebtModel]?
}

struct WalletCard: Decodable {
    let cardId: String
    let cardMask: String
    let cardholder: String?
    let gateway: String
    let expiration: String
    let date: String
    
    var image: String {
        if self.cardMask.prefix(1) == "4" {
            return "card_visa"
        } else if self.cardMask.prefix(2) == "51" || self.cardMask.prefix(2) == "52" || self.cardMask.prefix(2) == "53" || self.cardMask.prefix(2) == "54" || self.cardMask.prefix(2) == "55" {
            return "card_master_card"
        } else if self.cardMask.prefix(2) == "34" || self.cardMask.prefix(2) == "37" {
            return "card_amex"
        } else if (Int(self.cardMask.prefix(4)) ?? 0) >= 2200 && (Int(self.cardMask.prefix(4)) ?? 0) <= 2204 {
            return "card_mir"
        } else {
            return "card_arca"
        }
    }
}

struct AttachCardModel: Decodable {
    var formUrl: URL
}

struct FastshiftFormModel: Decodable {
    var formUrl: String
}

struct MyAmeriaFormModel: Decodable {
    var paymentUrl: String
}

struct UserDebtModel: Codable {
    let sourceType: String?
    let sourceId: String?
    let amount: Double?
    let sourceSystem: String?
    let generatedAt: Double?
}

struct GatewayModel: Codable {
    let id: String?
    let type: String?
    let image: ImageObj?
}

struct GatewayFormModel: Codable {
    let formUrl: String?
}
