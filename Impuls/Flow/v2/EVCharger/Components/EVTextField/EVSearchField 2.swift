//
//  EVSearchField.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 01.03.25.
//

import SwiftUI

struct EVTextField<RightView: View>: View {
    
    @Binding var text: String
    var placeholder: String
    
    @ViewBuilder var rightview: () -> (RightView)
    
    var body: some View {
        HStack(spacing: 3) {
            Image(.icLocation)
                .frame(width: 24, height: 24)
            TextField(placeholder, text: $text)
                .font(.robotoRegular17)
                .foregroundColor(.black075)
            
            Spacer()
            
            rightview()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 12).stroke(Color.evGray8, lineWidth: 1))
        .frame(maxWidth: .infinity)
    }
}
