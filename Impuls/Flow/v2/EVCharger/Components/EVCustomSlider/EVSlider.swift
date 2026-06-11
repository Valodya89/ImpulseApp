//
//  EVSlider.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 10.02.25.
//

import SwiftUI

struct EVSlider: View {
    
    @State private var sliderWidth: CGFloat = 0
    @State private var approvedValue: CGFloat = 0
    @State private var stepWidth: CGFloat = 0

    var stepsCount: CGFloat
    @Binding var step: CGFloat
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .center, content: {
                HStack(spacing: 0) {
                    Capsule()
                        .fill(LinearGradient.evBrandGradientHorizontal)
                        .frame(maxWidth: .infinity, maxHeight: 4)
                    Capsule()
                        .frame(maxWidth: .infinity, maxHeight: 4)
                        .foregroundColor(stepsCount == step ? .evBrandBlue : .evGray4)
                }
                ZStack(alignment: .leading) {
                    Capsule()
                        .frame(maxWidth: .infinity, maxHeight: 4)
                        .foregroundColor(.evGray4)
                        .background(
                            GeometryReader(content: { geometry in
                                Color.clear
                                    .onAppear {
                                        self.sliderWidth = geometry.frame(in: .global).width
                                    }
                            })
                        )
                    
                    Capsule()
                        .fill(LinearGradient.evBrandGradientHorizontal)
                        .frame(maxWidth: approvedValue + CircleSlider.SizeSlider.halfWithBottomCircle.rawValue, maxHeight: 4)
                    
                    HStack(spacing: stepWidth - CircleSlider.SizeSlider.halfWithBottomCircle.rawValue + 4) {
                        ForEach(0...(max(0, Int(stepsCount))), id: \.self) { index in
                            Circle()
                                .frame(width: 10)
                                .foregroundColor(CGFloat(index) <= step ? .evBrandBlue : .evGray4)
                        }
                    }
                    .padding(.leading, CircleSlider.SizeSlider.halfWithBottomCircle.rawValue - 5)
                    
                    
                    HStack {
                        // MARK: Circle of slider
                        CircleSlider()
                            .offset(x: approvedValue)
                            .gesture(
                                DragGesture()
                                    .onChanged({ drag in
                                        approvedValue = drag.location.x - CircleSlider.SizeSlider.halfWithBottomCircle.rawValue
                                        step = approvedValue / stepWidth
                                        if step.truncatingRemainder(dividingBy: 1) >= 0.5 {
                                            step = step < stepsCount ? CGFloat(Int(step + 1)) : stepsCount
                                        } else {
                                            step = step > 0 ? CGFloat(Int(step)) : 0
                                        }
                                        if step > stepsCount { step = stepsCount }
                                        if step >= 0 { approvedValue = stepWidth * step }
                                        if approvedValue < 0 { approvedValue = 0 }
                                        if approvedValue > sliderWidth - CircleSlider.SizeSlider.withBottomCircle.rawValue { approvedValue = sliderWidth - CircleSlider.SizeSlider.withBottomCircle.rawValue }
                                    })
                            )
                        Spacer()
                    }
                    
                }
                .padding(.horizontal, 5)
            })
            
//            stepWidth - CircleSlider.SizeSlider.halfWithBottomCircle.rawValue + 4
            HStack(spacing: stepWidth - CircleSlider.SizeSlider.halfWithBottomCircle.rawValue - 14) {
                ForEach(0...(max(0, Int(stepsCount))), id: \.self) { index in
                   Text("W\(10 * index)")
                        .font(.footnote)
                        .foregroundColor(.black60)
                }
            }
            .padding(.leading, CircleSlider.SizeSlider.halfWithBottomCircle.rawValue - 5)
        }
        .onAppear(perform: { viewDidLoad() })
    }
    
    func viewDidLoad() {
        stepWidth = (sliderWidth - CircleSlider.SizeSlider.withBottomCircle.rawValue) / stepsCount
    }
}

struct CircleSlider: View {
    enum SizeSlider: CGFloat {
        case withBottomCircle = 28
        case withTopCircle = 16
        case halfWithBottomCircle = 14
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient.evBrandGradientHorizontal)
                .frame(width: SizeSlider.withBottomCircle.rawValue)
            Circle()
                .frame(width: SizeSlider.withTopCircle.rawValue)
                .foregroundColor(.white)
        }
    }
}



#Preview {
    struct EVSlider_Preview: View {
        @State var step: CGFloat = 0
        var body: some View {
            VStack {
                EVSlider(stepsCount: 10, step: $step)
                    .padding(.horizontal)
                    .onChange(of: step) { newValue in
                        print(newValue)
                    }
            }
            
        }
    }
    
    return EVSlider_Preview()
}
