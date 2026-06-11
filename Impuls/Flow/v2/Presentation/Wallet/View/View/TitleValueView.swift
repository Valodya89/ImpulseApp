//
//  TitleValueView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 05.07.25.
//

import SwiftUI

struct TitleValueView: View {
    
    let title: String
    let value: String
    let currency: String
    
    init(title: String, value: String, currency: String) {
        self.title = title
        self.value = value
        self.currency = currency
    }
    
    var body: some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .padding(.leading, 14)
            
            Spacer()
            
            Text(value)
                .font(.robotoBold20)
                .foregroundColor(.evText9)
            
            Text(currency)
                .font(.robotoLight13)
                .padding(.trailing, 20)
                .foregroundColor(.evText9)
        }
        .frame(maxHeight: .infinity)
        .roundedBorderMedium()
    }
}

#Preview {
    TitleValueView(title: "dsfgh", value: "0", currency: "AMD")
}
