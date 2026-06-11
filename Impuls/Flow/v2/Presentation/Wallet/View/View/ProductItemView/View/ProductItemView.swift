//
//  ProductItemView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 04.07.25.
//

import SwiftUI

struct ProductItemView: View {
    
    @ObservedObject private var viewModel: ProductItemViewModel
    
    init(viewModel: ProductItemViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        HStack(spacing: 10) {
            
            Image(viewModel.image)
                .frame(width: 32, height: 32)
            
            Text(viewModel.text)
                .font(.robotoRegular15)
                .foregroundColor(.evText9)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .trailing, spacing: 10) {
                Text(viewModel.value)
                    .font(.robotoMedium15)
                    .foregroundColor(.evText9)
                
                Text(viewModel.valueLabel)
                    .font(.robotoRegular12)
                    .foregroundColor(.evText6)  
            }
        }
    }
}

#Preview {
    ProductItemView(viewModel: ProductItemViewModel(productType: .bike, value: "10", valueLabel: "chgidem"))
}
