//
//  SectionTopView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 05.07.25.
//

import SwiftUI

struct SectionTopViewModifier: ViewModifier {
    
    let icon: String?
    let label: String
    let labelValue: String?
    
    func body(content: Content) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 7) {
                Group {
                    if let icon {
                        Image(systemName: icon)
                            .frame(width: 12, height: 12)
                    }
                    Text(label)
                        .font(.robotoMedium12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let labelValue {
                        Text(labelValue)
                            .font(.robotoRegular12)
                    }
                }
                .foregroundColor(Color(hex: "#9EAFBE"))
            }
            content
        }
    }
}
