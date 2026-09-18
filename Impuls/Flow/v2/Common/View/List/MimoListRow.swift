//
//  MimoListRow.swift
//  Impuls
//
//  The redesign's standard list row: a tinted icon well, title, optional
//  supporting text, and a trailing slot (chevron by default). Rows stack
//  inside a `.mimoCard()` with `MimoRowDivider` between them.
//

import SwiftUI

struct MimoListRow<Trailing: View>: View {

    enum Tone {
        case standard
        case destructive
    }

    let icon: Image?
    let title: String
    let subtitle: String?
    let tone: Tone
    let trailing: Trailing

    init(icon: Image? = nil,
         title: String,
         subtitle: String? = nil,
         tone: Tone = .standard,
         @ViewBuilder trailing: () -> Trailing) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.tone = tone
        self.trailing = trailing()
    }

    var body: some View {
        HStack(spacing: 12) {
            if let icon {
                icon
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(tone == .destructive ? .errorRed : .appSecondaryLabel)
                    .frame(width: 36, height: 36)
                    .background(tone == .destructive ? Color.redTint : Color.appFill)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.robotoMedium15)
                    .foregroundColor(tone == .destructive ? .errorRed : .appLabel)
                    .lineLimit(1)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.robotoRegular12)
                        .foregroundColor(.gray5)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            trailing
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}

extension MimoListRow where Trailing == MimoChevron {
    init(icon: Image? = nil, title: String, subtitle: String? = nil, tone: Tone = .standard) {
        self.init(icon: icon, title: title, subtitle: subtitle, tone: tone) { MimoChevron() }
    }
}

struct MimoChevron: View {
    var body: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.gray5)
    }
}

/// Inset hairline between rows.
struct MimoRowDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.dividerColor)
            .frame(height: 1)
            .padding(.leading, 64)
    }
}

/// Uppercase section label above a card.
struct MimoSectionLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.robotoMedium12)
            .kerning(0.4)
            .foregroundColor(.gray5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }
}
