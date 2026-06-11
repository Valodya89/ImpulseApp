//
//  EVRangedSliderView.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 3/9/25.
//

import SwiftUI

struct EVRangedSliderView: View {
    @Binding var lowerValue: CGFloat
    @Binding var upperValue: CGFloat
    let minValue: CGFloat
    let maxValue: CGFloat
    private let circleSize: CGFloat = 28
    private let tapAreaSize: CGFloat = 44
    
    var body: some View {
        GeometryReader { geometry in
            let sliderWidth = geometry.size.width
            let normalizedLower = normalizeValue(lowerValue)
            let normalizedUpper = normalizeValue(upperValue)
            
            ZStack(alignment: .leading) {
                // Track (full width)
                Capsule()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: sliderWidth, height: 4)
                
                // Selected Range
                Capsule()
                    .fill(Color.evbrandCyan80)
                    .frame(width: sliderWidth * (normalizedUpper - normalizedLower), height: 4)
                    .offset(x: sliderWidth * normalizedLower)
                
                // Lower Thumb (use tapAreaSize for offset)
                DonutThumbView(circleSize: circleSize, tapAreaSize: tapAreaSize)
                    .offset(x: sliderWidth * normalizedLower - tapAreaSize / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newValue = denormalizeValue(value.location.x / sliderWidth)
                                let minDistance = circleSize / sliderWidth
                                lowerValue = min(max(newValue, minValue), upperValue - (minDistance * (maxValue - minValue)))
                            }
                    )
                
                // Upper Thumb (use tapAreaSize for offset)
                DonutThumbView(circleSize: circleSize, tapAreaSize: tapAreaSize)
                    .offset(x: sliderWidth * normalizedUpper - tapAreaSize / 2)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newValue = denormalizeValue(value.location.x / sliderWidth)
                                let minDistance = circleSize / sliderWidth
                                upperValue = min(max(newValue, lowerValue + (minDistance * (maxValue - minValue))), maxValue)
                            }
                    )
            }
        }
        .frame(height: 44)
    }
    
    private func normalizeValue(_ value: CGFloat) -> CGFloat {
        return (value - minValue) / (maxValue - minValue)
    }
    
    private func denormalizeValue(_ value: CGFloat) -> CGFloat {
        return value * (maxValue - minValue) + minValue
    }
}

struct DonutThumbView: View {
    let circleSize: CGFloat
    let tapAreaSize: CGFloat
    
    var body: some View {
        ZStack {
            // Transparent tap area
            Circle()
                .fill(Color.clear)
                .frame(width: tapAreaSize, height: tapAreaSize)
            
            // Visible thumb
            Circle()
                .fill(Color.evbrandCyan80)
                .frame(width: circleSize, height: circleSize)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: circleSize - 12, height: circleSize - 12)
                )
                .shadow(color: Color.evGray8.opacity(0.3), radius: 6, x: 0, y: 4)
        }
    }
}
