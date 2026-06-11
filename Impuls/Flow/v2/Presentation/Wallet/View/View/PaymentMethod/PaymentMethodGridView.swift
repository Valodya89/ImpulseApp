//
//  PaymentMethodGridView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.04.24.
//

import SwiftUI

struct PaymentMethodGridView: View {
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    let paymentMethods: [PaymentMethodModel]
    
    @Binding var selectedMethod: PaymentMethodModel?
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(paymentMethods) { paymentMethod in
                PaymentMethodView(paymentMethod: paymentMethod, isSelected: paymentMethod.id == selectedMethod?.id)
                    .frame(height: 46)
                    .onTapGesture {
                        VibrateManager.vibrate()
                        selectedMethod = paymentMethod
                    }
            }
        }
    }
}
