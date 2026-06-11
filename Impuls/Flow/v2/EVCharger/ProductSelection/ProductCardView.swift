//
//  ProductCardView.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/26/25.
//

import SwiftUI

struct ProductCardView: View {
    var product: ProductCardViewModel
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0))
                .cornerRadius(10)
            
            Image(product.imageName)
                .resizable()
                .scaledToFit()
                .padding()
        }
        .frame(height: 93)
        .background(
            RoundedStateView(isSelected: product.isSelected)
                .background(Color.white.cornerRadius(8, corners: .allCorners))
        )
    }
}
