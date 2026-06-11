//
//  WalletTransferMoneyView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.04.24.
//

import SwiftUI

struct WalletTransferMoneyView: View {
    
    var body: some View {
        HStack(spacing: 10) {
            Image("wallet_arrow_circle")
                .resizable()
                .frame(width: 32, height: 32)
                .padding(.leading, 14)
            
            Text("Transfer Money")
                .font(.system(size: 15))
                .foregroundColor(.black)
            
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
