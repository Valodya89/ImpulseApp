//
//  MimoButtonView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.09.23.
//

import SwiftUI

struct MimoButton: ButtonStyle {
    
    var isEnabled: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(isEnabled ? Color(UIColor.mimoYellow500) : .label025)
            .foregroundColor(Color.onBrandLabel)
            .clipShape(Capsule())
            .font(Font.custom(Constant.Font.robotoBold, size: 15))
            .padding(.horizontal, 20)
            .scaleEffect(configuration.isPressed ? 1.03 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .shadow(color: .black015, radius: 5)
    }
}

/// The quiet half of a button pair: same pill, hairline instead of yellow, so a
/// screen keeps exactly one primary action.
struct MimoSecondaryButton: ButtonStyle {

    enum Tone { case neutral, destructive }

    var tone: Tone = .neutral
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(background)
            .foregroundColor(foreground)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(tone == .destructive ? Color.clear : Color.appSeparator, lineWidth: 1)
            )
            .font(Font.custom(Constant.Font.robotoBold, size: 15))
            .scaleEffect(configuration.isPressed ? 1.03 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }

    private var background: Color {
        guard isEnabled else { return .label025 }

        return tone == .destructive ? .errorRed : .appBackground
    }

    private var foreground: Color {
        guard isEnabled else { return .appSecondaryLabel }

        return tone == .destructive ? .alwaysWhite : .appLabel
    }
}
