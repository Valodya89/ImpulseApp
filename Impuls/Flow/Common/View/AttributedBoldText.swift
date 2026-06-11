//
//  AttributedBoldText.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/24/25.
//

import SwiftUI

/// Make bold text inside **bold part**
struct AttributedBoldText: View {
    let input: String
    let font: Font
    let boldFont: Font

    var body: some View {
        buildFormattedText()
    }

    private func buildFormattedText() -> Text {
        let components = input.components(separatedBy: "**")
        var result = Text("")
        var isBold = false // Tracks whether the next component should be bold

        for component in components {
            if isBold {
                result = result + Text(component).font(boldFont)
            } else {
                result = result + Text(component).font(font)
            }
            isBold.toggle()
        }

        return result
    }
}
