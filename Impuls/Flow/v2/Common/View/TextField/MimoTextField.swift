//
//  MimoTextField.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.09.23.
//

import SwiftUI

struct MimoTextField: View {
    
    var title: String
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        ZStack {
            Color.appBackground
            
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(title)
                        .font(.robotoLight13)
                    
                    Spacer()
                }
                
                TextField(placeholder, text: $text)
                    .font(.robotoRegular17)
                    .foregroundColor(.label075)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.appLabel, lineWidth: 0.5)
        )
        .frame(height: 63)
        .frame(maxWidth: .infinity)
    }
}
