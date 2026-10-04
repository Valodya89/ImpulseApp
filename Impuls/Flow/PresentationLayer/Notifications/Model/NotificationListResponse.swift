//
//  NotificationListResponse.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 11.08.21.
//
//  One row of accounts `GET /api/notification`, the push payload both a push
//  and a row carry, and the single router that turns that payload into a
//  screen (accounts docs/push-notifications.md, "Routing table").
//

import Foundation

struct NotificationListResponse: Codable {
    var id: String?
//    var users: [String]?
    /// Delivery kind - `UNICAST` / `MULTICAST` / `BROADCAST`. Not the route.
    var type: String?
    var metadata: Metadata?
    var content: NotificationContent?
    var date: Double?
    /// Notification domain - `general`, `wallet`, `accounts`, `evup`, `scooter`,
    /// `sharing`, `powerbank`. Omitted on documents that predate the field, so
    /// it is optional. Used only to pick the row's badge, never for routing.
    var context: String?
}


/// `Notification.metadata` is a `Map<string,string>`; the FCM data payload of
/// the matching push is the same map plus `context`, so a row and a push
/// carry the same routing keys (accounts docs/push-notifications.md, "Data
/// payload contract").
struct Metadata: Codable {
    /// Legacy routing marker (`wallet`, `account`) kept for old app versions.
    var action: String?
    /// Drives routing: an event type on template pushes or an `OPEN_*` screen
    /// target picked by the operator; absent when no target was chosen.
    var type: String?
    /// Id of the entity the notification is about, present where `type` needs it.
    var referenceId: String?
    /// Extra key on EV charging pushes.
    var stationId: String?
}

struct Message: Codable {
    var title: String
    var content: String
}

struct NotificationContent: Codable {
    var en: Message?
    var ru: Message?
    var hy: Message?
}

// MARK: - Push routing

/// The routing keys of one push, read either from the FCM data payload (a
/// system notification tap) or from a notification row's `metadata`.
struct PushPayload: Equatable {
    static let contextKey = "context"
    static let typeKey = "type"
    static let referenceIdKey = "referenceId"
    static let stationIdKey = "stationId"
    static let actionKey = "action"

    let context: String?
    let type: String?
    let referenceId: String?
    let stationId: String?
    let action: String?

    init(context: String? = nil, type: String? = nil, referenceId: String? = nil, stationId: String? = nil, action: String? = nil) {
        self.context = context
        self.type = type
        self.referenceId = referenceId
        self.stationId = stationId
        self.action = action
    }

    /// The data map of a received push. FCM data values are always strings;
    /// anything else (APS, FCM bookkeeping keys) is ignored.
    init(userInfo: [AnyHashable: Any]) {
        func string(_ key: String) -> String? {
            let value = userInfo[key]
            if let text = value as? String { return text }
            if let number = value as? NSNumber { return number.stringValue }
            return nil
        }

        self.init(context: string(Self.contextKey),
                  type: string(Self.typeKey),
                  referenceId: string(Self.referenceIdKey),
                  stationId: string(Self.stationIdKey),
                  action: string(Self.actionKey))
    }

    /// A row of the in-app notification list.
    init(metadata: Metadata?, context: String?) {
        self.init(context: context,
                  type: metadata?.type,
                  referenceId: metadata?.referenceId,
                  stationId: metadata?.stationId,
                  action: metadata?.action)
    }

    /// The legacy `action: wallet` marker: old apps refreshed the balance on
    /// it, and this one keeps doing so next to the `type` route.
    var refreshesBalance: Bool {
        action?.lowercased() == "wallet" || context?.lowercased() == "wallet"
    }
}

/// Where a push or a notification row leads.
enum PushRoute: Equatable {
    /// The wallet screen.
    case wallet
    /// The wallet with the top-up in focus. Impulse tops up on the wallet
    /// screen itself, so it is presented the same way; the case is kept so the
    /// callers read like the routing table.
    case walletTopUp
    /// The in-app notification list - the safe fallback for anything unknown.
    case notificationList
}

/// The one router for push taps (cold start, background, foreground) and for
/// rows of the notification list, keyed on the payload `type`. Impulse has no
/// EV charging and no scooters, so only the types whose target is the wallet
/// resolve here; everything else falls back to the notification list.
enum PushRouter {

    /// Types whose tap target is the wallet screen.
    static let walletTypes: Set<String> = ["WALLET_TRANSFER_RECEIVED", "OPEN_WALLET"]
    /// Types whose tap target is the wallet top-up screen.
    static let walletTopUpTypes: Set<String> = ["OPEN_WALLET_TOPUP", "SCOOTER_LOW_BALANCE", "EV_CHARGING_PAYMENT_FAILED"]

    /// The screen a payload resolves to, or nil when its `type` is unknown or
    /// absent. Notification rows use this to decide whether they are tappable.
    static func destination(for payload: PushPayload) -> PushRoute? {
        guard let type = payload.type?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(), !type.isEmpty else {
            return nil
        }

        if walletTypes.contains(type) { return .wallet }
        if walletTopUpTypes.contains(type) { return .walletTopUp }
        return nil
    }

    /// The screen to open on a tap: the resolved destination, or the
    /// notification list when nothing matches - never nothing.
    static func route(for payload: PushPayload) -> PushRoute {
        destination(for: payload) ?? .notificationList
    }
}
