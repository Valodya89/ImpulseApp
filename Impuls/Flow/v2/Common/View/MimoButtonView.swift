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
            .background(isEnabled ? Color(UIColor.mimoYellow500) : .black025)
            .foregroundColor(Color.black)
            .clipShape(Capsule())
            .font(Font.custom(Constant.Font.robotoBold, size: 15))
            .padding(.horizontal, 20)
            .scaleEffect(configuration.isPressed ? 1.03 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
            .shadow(color: .black015, radius: 5)
    }
}
