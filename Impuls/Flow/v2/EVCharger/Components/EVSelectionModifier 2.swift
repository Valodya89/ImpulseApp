//
//  EVSelectionModifier.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 3/11/25.
//

import SwiftUI

struct EVSelectionModifier: ViewModifier {
    var isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack(alignment: .topTrailing) {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.evbrandCyan80, lineWidth: 2)
                        
                        Rectangle()
                            .fill(Color.evbrandCyan80)
                            .clipShape(EVTriangle(radius: 8, angleShape: .rightTrianglelTopTrailing))
                            .frame(width: 23, height: 20)
                        
                        Image("chackMark")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color.white)
                            .frame(width: 7, height: 7)
                            .padding(.trailing, 3)
                            .padding(.top, 3)
                    }
                }
            )
    }
}

extension View {
    func withSelectionStyle(isSelected: Bool) -> some View {
        self.modifier(EVSelectionModifier(isSelected: isSelected))
    }
}
