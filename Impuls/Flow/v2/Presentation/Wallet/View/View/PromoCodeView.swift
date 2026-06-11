//
//  PromoCodeView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.04.24.
//

import SwiftUI

struct PromoCodeView: View {
    
    @Binding var promoCode: String
    let submitAction: (String) -> Void
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 5) {
                Text("MOBILE_promo_code".localized())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.gray6)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    TextField("XXXXXX", text: $promoCode)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.mimoDarkGray)
                        .multilineTextAlignment(.leading)
                    
                    Button(action: {
                        submitAction(promoCode)
                    }, label: {
                        Text("MOBILE_global_submit".localized())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.gray9)
                            .opacity(promoCode.isEmpty ? 0.55 : 1)
                    })
                    .disabled(promoCode.isEmpty)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(height: 64)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray4, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
}
