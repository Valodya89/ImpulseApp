//
//  FooterButton.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 09.03.25.
//

import SwiftUI

struct FooterButton: View {
    
    var `continue`: Action
    
    var body: some View {
        Button {
            `continue`()
        } label: {
            Text("MOBILE_global_continue".localized())
                .font(.robotoBold15)
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Capsule().fill(Color.evbrandCyan80))
        }   
    }
}
