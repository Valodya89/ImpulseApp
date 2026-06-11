//
//  PaymentMethodView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.04.24.
//

import SwiftUI
import Kingfisher

struct PaymentMethodView: View {
    
    let paymentMethod: PaymentMethodModel
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            KFImage(paymentMethod.logo?.imageURL)
                .resizable()
                .scaledToFit()
                .padding(7)
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


struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))

        return path
    }
}
