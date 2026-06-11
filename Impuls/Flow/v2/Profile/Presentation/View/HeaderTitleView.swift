//
//  HeaderTitleView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 14.04.24.
//

import SwiftUI

struct HeaderTitleView: View {
    
    let title: String
    
    var body: some View {
        
        Text(title)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.headerTitleColor)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
