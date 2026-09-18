//
//  WalletPaymentMethodRow.swift
//  Impuls
//
//  One way to pay, as a list row: the provider's logo in a well, its name, an
//  optional supporting line, and a trailing slot. Selectable rows end in a
//  `WalletSelectionIndicator`; the selected row is tinted so the choice reads
//  at a glance instead of by hunting for a corner mark.
//

import SwiftUI
import Kingfisher

struct WalletPaymentMethodRow<Trailing: View>: View {

    enum Logo {
        case asset(String)
        case remote(URL?)
    }

    let logo: Logo
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let trailing: Trailing

    init(logo: Logo,
         title: String,
         subtitle: String? = nil,
         isSelected: Bool = false,
         @ViewBuilder trailing: () -> Trailing) {
        self.logo = logo
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            logoWell

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.robotoMedium15)
                    .foregroundColor(.appLabel)
                    .lineLimit(1)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.robotoRegular12)
                        .foregroundColor(.gray5)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 60)
        .background(isSelected ? Color.yellowTint : Color.clear)
        .animation(.easeOut(duration: 0.2), value: isSelected)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var logoWell: some View {
        Group {
            switch logo {
            case .asset(let name):
                Image(name)
                    .resizable()
                    .scaledToFit()
            case .remote(let url):
                KFImage(url)
                    .resizable()
                    .scaledToFit()
            }
        }
        .padding(6)
        .frame(width: 44, height: 40)
        // Provider logos are drawn for a light ground; keep it under them in dark too.
        .background(Color.alwaysWhite)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 0.5)
        )
    }
}

extension WalletPaymentMethodRow where Trailing == WalletSelectionIndicator {
    init(logo: Logo, title: String, subtitle: String? = nil, isSelected: Bool) {
        self.init(logo: logo, title: title, subtitle: subtitle, isSelected: isSelected) {
            WalletSelectionIndicator(isSelected: isSelected)
        }
    }
}

/// Radio-style mark: a hairline ring that fills yellow with a check when chosen.
struct WalletSelectionIndicator: View {

    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray4, lineWidth: 1.5)
                .opacity(isSelected ? 0 : 1)

            Circle()
                .fill(Color.brandYellow)
                .scaleEffect(isSelected ? 1 : 0.4)
                .opacity(isSelected ? 1 : 0)

            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.onBrandLabel)
                .opacity(isSelected ? 1 : 0)
        }
        .frame(width: 22, height: 22)
        .animation(.easeOut(duration: 0.2), value: isSelected)
        .accessibilityLabel(isSelected ? "Selected" : "Not selected")
    }
}
