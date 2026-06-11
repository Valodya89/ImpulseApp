//
//  RemovablePaymentMethodView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.05.24.
//

import SwiftUI

struct RemovablePaymentMethodView: View {
    
    let card: WalletCard
    let isSelected: Bool
    let onDelete: () -> Void
    
    init(card: WalletCard, isSelected: Bool, onDelete: @escaping () -> Void) {
        self.card = card
        self.isSelected = isSelected
        self.onDelete = onDelete
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Image(card.image)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .padding(.leading, 14)
            
            Text(card.cardMask)
                .font(.system(size: 15))
                .foregroundColor(.black)
            
            Spacer()
            
            Image(systemName: "xmark")
                .resizable()
                .foregroundColor(.black)
                .frame(width: 10, height: 10)
                .padding(.trailing, 20)
                .onTapGesture {
                    onDelete()
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.brandYellow : Color.gray4, lineWidth: isSelected ? 4 : 0.5)
        )
        .overlay(
            ZStack {
                Triangle()
                    .fill(Color.brandYellow)
                    .frame(width: 40, height: 40)
                    .rotationEffect(Angle(degrees: 35))
                    .padding(.top, -24)
                    .padding(.trailing, -24)
                    .overlay(
                        Image(systemName: "checkmark")
                            .resizable()
                            .font(.title.bold())
                            .foregroundColor(.black)
                            .frame(width: 7.7, height: 7)
                            .padding(.bottom, 3)
                    )
            }.opacity(isSelected ? 1 : 0)
            , alignment: .topTrailing
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
