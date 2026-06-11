//
//  ProgressBar.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 01.03.25.
//

import SwiftUI

struct ProgressBar: View {
    @Binding var progress: Float
    var color: Color = Color.evBrandBlue
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 12.0)
                .opacity(0.20)
                .foregroundColor(Color.gray)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 12.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 90))
                .animation(.easeInOut(duration: 2.0))
        }
    }
}
