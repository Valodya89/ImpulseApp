//
//  WalletOrderCardView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.04.24.
//

import SwiftUI

struct WalletOrderCardView: View {
    
    var body: some View {
        HStack(spacing: 10) {
            Image("wallet_order_card")
                .resizable()
                .frame(width: 32, height: 32)
                .padding(.leading, 14)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("MOBILE_wallet_Mimo_Card".localized())
                    .font(.system(size: 15))
                    .foregroundColor(.black)
                
                Text("MOBILE_wallet_order_card_for_free".localized())
                    .font(.system(size: 13))
                    .foregroundColor(.black05)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .resizable()
                .foregroundColor(.black)
                .frame(width: 8, height: 12)
                .padding(.trailing, 20)
        }
        .frame(maxHeight: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray4, lineWidth: 0.5)
        )
    }
}
