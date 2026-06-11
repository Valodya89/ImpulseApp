//
//  WalletAmountView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 26.04.24.
//

import SwiftUI
import Combine

struct WalletAmountView: View {
    
    @Binding var amount: String
    let currency: String
    
    var body: some View {
        VStack(spacing: 0) {
            Text("MOBILE_global_insert_amount".localized())
                .font(.system(size: 17, weight: .light))
                .foregroundColor(.gray6)
                
            HStack(spacing: 6) {
                TextField("0,00", text: $amount)
                .keyboardType(.numberPad)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.gray8)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: true, vertical: false)
                .onReceive(Just(amount)) { _ in
                    if amount.count > 6 {
                        amount = String(amount.prefix(6))
                    }
                }
                
                Text(currency)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.gray8)
                    .multilineTextAlignment(.leading)
            }
            .padding(.top, 16)
            
            Rectangle()
                .fill(Color.gray8)
                .frame(height: 1)
                .padding(.top, 10)
        }
    }
}
