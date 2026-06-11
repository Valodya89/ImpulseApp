//
//  ChooseConnectorChargeOptionView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 02.03.25.
//

import SwiftUI

struct ChooseConnectorChargeOptionView: View {
    
    let icon: ImageResource
    let title: String
    var isSelected: Bool = false
    
    var body: some View {
        
        VStack(spacing: 8) {
            Image(icon)
                .resizable()
                .frame(width: 60, height: 60)
            Text(title)
                .font(.robotoBold14)
                .foregroundColor(.black60)
        }
        .padding(.vertical, 15)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .borderRoundedStateView(isSelected: isSelected)
        .background(Color.white.cornerRadius(8, corners: .allCorners))
    }
}   
