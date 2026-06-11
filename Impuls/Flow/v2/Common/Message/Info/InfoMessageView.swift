//
//  InfoMessageView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 20.05.24.
//

import SwiftUI

struct InfoMessageView: View {
    
    let message: InfoMessage
    let action: () -> Void

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundColor(.black)
                .background(.thickMaterial)
                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height + 50)
                .opacity(0.45)
            
            ZStack {
                VStack(spacing: 0) {
                    Image(systemName: "info.square")
                        .resizable()
                        .frame(width: 80, height: 80, alignment: .center)
                        .foregroundColor(.warningColor)
                        .padding(.top, 32)
                    
                    Text(message.title)
                        .foregroundColor(Color.gray9)
                        .font(.system(size: 18, weight: .bold))
                        .padding(.top, 32)
                    
                    Text(attributedBody())
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                    
                    Divider()
                        .padding(.top, 20)
                    
                    Button {
                        action()
                    } label: {
                        Text("SCOOTER_start_ride_message_action_title".localized())
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.gray8)
                    }
                    .frame(height: 56)
                }
                .padding(.horizontal, 20)
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
            .padding(.horizontal, 48)
        }
        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
    }
    
    func attributedBody() -> AttributedString {
        let string = message.body
        var attributedString = AttributedString(string)
        attributedString.font = .system(size: 15, weight: .regular)
        attributedString.foregroundColor = .gray9
        if let range = attributedString.range(of: "P") {
            attributedString[range].backgroundColor = .brandYellow
            attributedString[range].underlineStyle = .single
        }
        
        return attributedString
    }
}
