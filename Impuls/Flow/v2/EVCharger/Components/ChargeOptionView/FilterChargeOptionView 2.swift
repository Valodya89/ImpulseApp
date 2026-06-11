//
//  FilterChargeOptionView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 07.02.25.
//

import SwiftUI

struct FilterChargeOptionView: View {
    @ObservedObject var item: EVStationFilterItem
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(item.image)
                .resizable()
                .frame(width: 24, height: 24)
            Text(item.title)
                .font(.robotoRegular14)
                .foregroundColor(.evText8)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.evMainBg2.cornerRadius(8))
        .withSelectionStyle(isSelected: item.isSelected)
    }
}

struct RoundedStateView: View {
    
    var isSelected: Bool = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if isSelected {
                
                RoundedRectangle(cornerRadius: 8).stroke(LinearGradient.evBrandGradientHorizontal, lineWidth: 2).cornerRadius(8)
                
                Rectangle()
                    .fill(LinearGradient.evBrandGradientHorizontal)
                    .clipShape(EVTriangle(radius: 8, angleShape: .rightTrianglelTopTrailing))
                    .frame(width: 23, height: 20)
                
                Image("chackMark")
                    .resizable()
                    .frame(width: 7, height: 7)
                    .padding(.trailing, 3)
                    .padding(.top, 3)
            }
        }
    }
}

extension View {
    func borderRoundedStateView(isSelected: Bool) -> some View {
        return self.overlay(RoundedStateView(isSelected: isSelected))
    }
}
