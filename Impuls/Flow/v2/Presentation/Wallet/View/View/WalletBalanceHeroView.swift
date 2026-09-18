//
//  WalletBalanceHeroView.swift
//  Impuls
//
//  The wallet's opening card: the balance as the one large figure on the
//  screen, a status badge, and the three things a rider comes here to do -
//  top up, send money, see history - as quick actions under it.
//

import SwiftUI

struct WalletBalanceHeroView: View {

    let balance: String
    let currency: String
    let isNegative: Bool
    /// Masked number of the attached card, shown as a quiet badge so the rider
    /// knows what a top-up will charge without scrolling.
    let attachedCardMask: String?

    let onTopUp: () -> Void
    let onSend: () -> Void
    let onHistory: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                Text("MOBILE_mimo_balance".localized())
                    .font(.robotoRegular13)
                    .foregroundColor(.gray5)
                    .lineLimit(1)

                Spacer(minLength: 8)

                if isNegative {
                    MimoBadge(title: "MOBILE_wallet_debt_badge".localized(fallback: "Debt"), tone: .red)
                } else if let attachedCardMask {
                    MimoBadge(title: Self.shortMask(attachedCardMask), tone: .gray)
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(balance)
                    .font(.robotoBold36)
                    .foregroundColor(isNegative ? .errorRed : .appLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                Text(currency)
                    .font(.robotoMedium16)
                    .foregroundColor(isNegative ? .errorRed : .appSecondaryLabel)
                    .lineLimit(1)
            }
            .padding(.top, 6)

            if isNegative {
                Text("MOBILE_wallet_debt_hero_hint".localized(fallback: "Top up to clear the debt and keep riding."))
                    .font(.robotoRegular13)
                    .foregroundColor(.appSecondaryLabel)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 6)
            }

            HStack(spacing: 10) {
                WalletQuickActionTile(
                    title: "MOBILE_wallet_top_up".localized(fallback: "Top up"),
                    systemImage: "plus",
                    isPrimary: true,
                    action: onTopUp
                )

                WalletQuickActionTile(
                    title: "MOBILE_wallet_send".localized(fallback: "Send"),
                    systemImage: "arrow.up.right",
                    isPrimary: false,
                    action: onSend
                )

                WalletQuickActionTile(
                    title: "MOBILE_profile_history".localized(),
                    systemImage: "clock.arrow.circlepath",
                    isPrimary: false,
                    action: onHistory
                )
            }
            .padding(.top, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .mimoCard(padding: 20)
    }

    /// "•••• 1234" from whatever mask the gateway sends ("4083 **** **** 1234",
    /// "408300******1234", ...). Falls back to the mask itself when it does not
    /// end in digits.
    static func shortMask(_ mask: String) -> String {
        let tail = mask.suffix(4)
        guard tail.count == 4, tail.allSatisfy({ $0.isNumber }) else { return mask }
        return "•••• " + tail
    }
}

/// One quick action: a round icon well over a caption. Only the primary tile
/// (top up) is yellow, so the card keeps a single accent.
struct WalletQuickActionTile: View {

    let title: String
    let systemImage: String
    let isPrimary: Bool
    let action: () -> Void

    var body: some View {
        Button {
            VibrateManager.vibrate()
            action()
        } label: {
            VStack(spacing: 8) {
                Circle()
                    .fill(isPrimary ? Color.brandYellow : Color.appFill)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(isPrimary ? .onBrandLabel : .appLabel)
                    )

                Text(title)
                    .font(.robotoMedium12)
                    .foregroundColor(.appSecondaryLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(WalletQuickActionButtonStyle())
    }
}

private struct WalletQuickActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
