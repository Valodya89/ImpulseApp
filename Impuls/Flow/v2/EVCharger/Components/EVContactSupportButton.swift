//
//  EVContactSupportButton.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/27/25.
//

import SwiftUI

struct EVContactSupportButton: View {
    @Environment(\.openURL) var openURL
    
    var body: some View {
        Button {
            if let telegramURL = URL(string: "https://t.me/+bklXxIxjDA9iNjky") {
                openURL(telegramURL)
            }
        } label: {
            HStack(alignment: .center, spacing: 12) {
                Image(.contactSmsCircle)
                    .frame(width: 24, height: 24)
                
                Text("MOBILE_mimo_support".localized())
                    .font(.robotoMedium13)
                    .foregroundColor(Color.evGray8)
                
                Spacer(minLength: 0)
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Color.evGray8.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.evBgColor4)
            )
            .shadow(color: Color.evGray8.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}
