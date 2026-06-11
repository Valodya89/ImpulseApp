//
//  ChargerSpeedView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 04.03.25.
//

import SwiftUI

struct ChargerSpeedView: View {
    @State private var progres: CGFloat = 0

    @State private var angle: Angle = .zero
    @State private var startLocation: CGPoint = .zero

    @State private var centerX: CGFloat = .zero
    @State private var centerY: CGFloat = .zero

    private var widthCirle: CGFloat = 60
    private var heightCirle: CGFloat = 60
    @State private var centerOfCircle: CGPoint = .zero

    private var heightSlack: CGFloat = 90

    
    var body: some View {
        ZStack {
            ZStack(alignment: .center) {
                Circle()
                    .trim(from: 0.0, to: 0.75)
                    .stroke(style: StrokeStyle(lineWidth: 42.0, lineCap: .butt, lineJoin: .round))
                    .fill(Color.gray)
                    .opacity(0.3)
                
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(self.progres * 0.6, 0.75)))
                    .stroke(style: StrokeStyle(lineWidth: 42.0, lineCap: .butt, lineJoin: .round))
                    .fill(LinearGradient.evBrandGradientHorizontal)
            }
            .rotationEffect(Angle(degrees: 135))
            .frame(width: 280)
            
            ZStack(alignment: .center, content: {
                Circle()
                    .stroke(.gray, lineWidth: 1)
                    .frame(width: widthCirle, height: heightCirle)
                    .offset(y: 22)
//                    .background(GeometryReader(content: { geometry in
//                        Color.clear
//                            .onAppear(perform: {
//                                centerX = geometry.frame(in: .global).origin.x
//                                centerY = geometry.frame(in: .global).origin.y
//                                centerOfCircle = CGPoint(x: centerX / 2 - widthCirle / 2, y: centerY / 2 - heightCirle / 2)
//                                print(geometry.frame(in: .global).origin.y, "y")
//                            })
//                    }))
                
                Image(.speedSlack)
                    .frame(height: heightSlack)
                    .rotationEffect(Angle(degrees: 12))
                    .rotationEffect(Angle(degrees: angle.degrees - 135), anchor: UnitPoint(x: 0.45, y: 0.95))
                    .offset(x: 2, y: -heightCirle / 2 + 7) // x should deleete when slack will
            })
            .overlay(
                Color.red
                    .opacity(0.001)
                    .frame(maxWidth: .infinity)
                    .gesture(
                        DragGesture()
                            .onChanged({ drag in
                                print(drag.location.x)
                            })
                    )
            )
            
           
        }
    }
}

#Preview {
    ChargerSpeedView()
}
