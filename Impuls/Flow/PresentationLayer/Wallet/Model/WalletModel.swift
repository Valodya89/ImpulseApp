//
//  WalletModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/2/21.
//

import Foundation

/// Wallet of the signed-in user, ipay `GET /api/wallet` (`docs/mobile-api.md`,
/// heading "GET /api/wallet", commit 644cafc8). Every field the backend may
/// serialise as `null` is optional here, and the collections default to empty, so
/// one missing value (for example a Getnet card without an expiry) can never make
/// the whole wallet undecodable.
struct WalletModel: Decodable {
    let id: String
    let balance: Double
    let currency: String
    /// Epoch milliseconds; `long` on the backend, may be absent.
    let creationDate: Int?
    /// Attached card, `null` when none is attached.
    let card: WalletCard?
    /// `true` if the (never serialised) `removedCards` list is non-empty.
    let hasOldCards: Bool
    /// `List<Debt>`; empty when absent.
    let debts: [UserDebtModel]
    /// `Set<Lock>`; a non-empty set blocks `PATCH /api/wallet/transfer`.
    let locks: [WalletLock]

    /// `true` when ipay would refuse a transfer because of an active lock.
    var isTransferLocked: Bool { !locks.isEmpty }

    private enum CodingKeys: String, CodingKey {
        case id, balance, currency, creationDate, card, hasOldCards, debts, locks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        balance = try container.decode(Double.self, forKey: .balance)
        currency = try container.decode(String.self, forKey: .currency)
        creationDate = try container.decodeIfPresent(Int.self, forKey: .creationDate)
        card = try container.decodeIfPresent(WalletCard.self, forKey: .card)
        hasOldCards = try container.decodeIfPresent(Bool.self, forKey: .hasOldCards) ?? false
        debts = try container.decodeIfPresent([UserDebtModel].self, forKey: .debts) ?? []
        locks = try container.decodeIfPresent([WalletLock].self, forKey: .locks) ?? []
    }
}

/// Attached card of `GET /api/wallet` (`model/Card.java`). Only `cardId`,
/// `cardMask` and `gateway` are guaranteed; `expiration` is not reported by
/// Getnet and `cofTransactionId` is Getnet-only.
struct WalletCard: Decodable {
    let cardId: String
    let cardMask: String
    let cardholder: String?
    /// `PaymentProvider` value.
    let gateway: String
    /// `MM/YY`; `nil` when the gateway does not report it (Getnet).
    let expiration: String?
    /// Getnet-only card-scheme id of the first unattended charge; the app has no use for it.
    let cofTransactionId: String?
    /// ISO-8601 attach date, may be absent.
    let date: String?

    private enum CodingKeys: String, CodingKey {
        case cardId, cardMask, cardholder, gateway, expiration, cofTransactionId, date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cardId = try container.decode(String.self, forKey: .cardId)
        cardMask = try container.decode(String.self, forKey: .cardMask)
        cardholder = try container.decodeIfPresent(String.self, forKey: .cardholder)
        gateway = try container.decode(String.self, forKey: .gateway)
        expiration = try container.decodeIfPresent(String.self, forKey: .expiration)
        cofTransactionId = try container.decodeIfPresent(String.self, forKey: .cofTransactionId)
        date = try container.decodeIfPresent(String.self, forKey: .date)
    }

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

/// One entry of the wallet's `locks` set (`model/Lock.java`; ipay `docs/events.md`,
/// heading "`wallet.lock` — `LockListener`": `lockId: String`, `lockSystem: SourceSystem`).
/// `lockSystem` is one of `BIKE`, `SCOOTER`, `CHARGER`, `EV_CHARGER`, `PENALTY`.
struct WalletLock: Decodable, Hashable {
    let lockId: String?
    let lockSystem: String?
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
