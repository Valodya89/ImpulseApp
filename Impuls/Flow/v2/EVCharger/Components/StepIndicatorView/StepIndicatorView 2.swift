//
//  StepIndicatorView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 09.03.25.
//

import SwiftUI

struct StepIndicatorView: View {
    
    @State private var weightOfIndicator: CGFloat = 0
    var partOfIndicator: CGFloat?
    
    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color.white)
                .frame(maxWidth: .infinity)
                .background(GeometryReader(content: { geometry in
                    Color.white.onAppear(perform: {
                        weightOfIndicator = geometry.frame(in: .global).width
                    })
                }))
            
            Capsule()
                .fill(LinearGradient.evBrandGradientHorizontal)
                .frame(width: partOfIndicator != nil ? weightOfIndicator * partOfIndicator! : 0)
        }
        .frame(height: 7)
    }
}

//#Preview {
//    StepIndicatorView()
//}
