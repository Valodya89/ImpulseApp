//
//  RoundedBorder.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 05.07.25.
//

import SwiftUI

struct RoundedBorder: ViewModifier {
    
    let radius: CGFloat
    let color: Color
    let lineWidth: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(radius)
            .overlay(
                RoundedRectangle(cornerRadius: radius)
                    .stroke(color, lineWidth: lineWidth)
            )
    }
}

