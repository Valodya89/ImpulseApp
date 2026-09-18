//
//  MimoCardModifier.swift
//  Impuls
//
//  Card surface of the redesign: adaptive surface colour, radius 12, one soft
//  shadow. Also the sheet header and the status badge the cards use.
//

import SwiftUI

struct MimoCardModifier: ViewModifier {
    var radius: CGFloat = 12
    var padding: CGFloat = 0
    var fill: Color = .appBackground

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Color.alwaysBlack.opacity(0.10), radius: 8, x: 0, y: 2)
    }
}

extension View {
    /// Wraps the view in the standard card surface.
    func mimoCard(radius: CGFloat = 12, padding: CGFloat = 0, fill: Color = .appBackground) -> some View {
        modifier(MimoCardModifier(radius: radius, padding: padding, fill: fill))
    }
}

/// Header for modally presented v2 screens: close on the left, centred title.
struct MimoSheetHeader: View {
    let title: String
    var systemImage: String = "xmark"
    let action: () -> Void

    var body: some View {
        ZStack {
            HStack {
                Button(action: action) {
                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.appLabel)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
            .padding(.horizontal, 6)

            Text(title)
                .font(.robotoBold17)
                .foregroundColor(.appLabel)
                .lineLimit(1)
                .padding(.horizontal, 56)
        }
        .frame(height: 52)
        .background(Color.appSecondaryBackground)
        .overlay(
            Rectangle().fill(Color.dividerColor).frame(height: 1),
            alignment: .bottom
        )
    }
}

/// Small pill used for statuses (Debt, Pending, Failed, a card's last digits).
struct MimoBadge: View {
    enum Tone { case green, amber, red, gray, yellow }

    let title: String
    let tone: Tone

    var body: some View {
        Text(title)
            .font(.robotoMedium12)
            .foregroundColor(foreground)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(Capsule().fill(background))
    }

    private var foreground: Color {
        switch tone {
        case .green: return .successGreen
        case .amber: return .warningColor
        case .red: return .errorRed
        case .gray: return .appSecondaryLabel
        case .yellow: return .onBrandLabel
        }
    }

    private var background: Color {
        switch tone {
        case .green: return .greenTint
        case .amber: return .amberTint
        case .red: return .redTint
        case .gray: return .appFill
        case .yellow: return .brandYellow
        }
    }
}
