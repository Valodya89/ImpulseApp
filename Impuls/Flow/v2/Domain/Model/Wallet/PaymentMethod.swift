//
//  PaymentMethod.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.04.24.
//

import Foundation

enum PaymentMethod: Identifiable {
    
    var id: String {
        switch self {
        case .attachedCard(let card):
            return "attached_card_\(card.cardId)"
        case .iDram:
            return "idram"
        case .telcell:
            return "telcell"
        case .fastshift:
            return "fastshift"
        case .easypay:
            return "esypay"
        case .crypto:
            return "crypto"
        case .myameria:
            return "myameria"
        }
    }
    
    case attachedCard(WalletCard)
    case iDram
    case telcell
    case fastshift
    case easypay
    case crypto
    case myameria
    
    var image: String {
        switch self {
        case .attachedCard(let card):
            if card.cardMask.prefix(1) == "4" {
                return "card_visa"
            } else if card.cardMask.prefix(2) == "51" || card.cardMask.prefix(2) == "52" || card.cardMask.prefix(2) == "53" || card.cardMask.prefix(2) == "54" || card.cardMask.prefix(2) == "55" {
                return "card_master_card"
            } else if card.cardMask.prefix(2) == "34" || card.cardMask.prefix(2) == "37" {
                return "card_amex"
            } else if (Int(card.cardMask.prefix(4)) ?? 0) >= 2200 && (Int(card.cardMask.prefix(4)) ?? 0) <= 2204 {
                return "card_mir"
            } else {
                return "card_arca"
            }
        case .iDram:
            return "wallet_idram"
        case .telcell:
            return "wallet_telcell"
        case .fastshift:
            return "wallet_fastshift"
        case .easypay:
            return "wallet_esypay"
        case .crypto:
            return "wallet_crypto"
        case .myameria:
            return "wallet_myameria"
        }
    }
    
    var name: String {
        switch self {
        case .attachedCard(let walletCard):
            return walletCard.cardMask
        case .iDram:
            return "idram"
        case .telcell:
            return "telcell"
        case .fastshift:
            return "fastshift"
        case .easypay:
            return "easypay"
        case .crypto:
            return "Crypto"
        case .myameria:
            return "MyAmeria"
        }
    }
}
