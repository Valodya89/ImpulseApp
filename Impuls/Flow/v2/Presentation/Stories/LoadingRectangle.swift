//
//  LoadingRectangle.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.12.23.
//

import SwiftUI

struct LoadingRectangle: View {
    
    var progress: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .foregroundColor(Color.black.opacity(0.2))
                    .cornerRadius(4)

                Rectangle()
                    .frame(width: geometry.size.width * self.progress, height: nil, alignment: .leading)
                    .foregroundColor(Color.mimoYellow500)
                    .cornerRadius(4)
            }
        }
    }
}
