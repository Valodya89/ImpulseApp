//
//  EVBottomView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 24.02.25.
//

import SwiftUI

struct EVStaticBottomSheet<Content: View>: View {
    
    @ViewBuilder var content: () -> (Content)
    
    var body: some View {
        VStack(alignment: .center, spacing: 21) {
            
            Color.gray
                .frame(width: 38, height: 4)
                .clipShape(Capsule())
                .padding(.top, 13)
            
            content()
        }
        .padding(.bottom, 38)
        .background(Color.evSheetBgColor)
        .cornerRadius(18, corners: [.topLeft, .topRight])
    }
}

struct EVVerticalDoubleButtonView: View {
    
    var orderAction: Action? = nil
    var nearestStationAction: Action? = nil
    
    var body: some View {
        HStack(spacing: 10) {
//            Button {
//                orderAction?()
//            } label: {
//                Text("Order EVUP")
//                    .foregroundColor(Color.evBgDark)
//                    .font(.robotoBold15)
//                    .frame(maxWidth: .infinity)
//                    .padding(15)
//                    .clipShape(Capsule())
//                    .overlay(Capsule().stroke(Color.evBgDark, lineWidth: 1))
//            }

            Button {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                nearestStationAction?()
            } label: {
                Text("EV_CHARGER_map_nearest_stations".localized())
                    .foregroundColor(Color.white)
                    .font(.robotoBold15)
                    .frame(maxWidth: .infinity)
                    .padding(15)
                    .background(Color.evbrandCyan80)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
    }
}
