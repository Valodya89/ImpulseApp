//
//  EVChargingPriceView.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 3/8/25.
//

import SwiftUI

struct EVChargingPriceView: View {
    @State var price: String = ""
    @State var backgroundColor: Color = Color.evBgColor4
    
    var body: some View {
        VStack(spacing: 8) {
            Text("PRICE")
                .font(.robotoBold12)
                .foregroundColor(Color.evGray8)
            
            Text(price)
                .font(.robotoMedium24)
                .foregroundColor(Color.evGray12)
            
            Text("Rates may differ based on the provider.")
                .font(.robotoLight14)
                .foregroundColor(Color.evGray8)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(backgroundColor)
        .clipShape(RoundedCorner(radius: 10))
    }
}
