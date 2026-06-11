//
//  RateView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 20.04.25.
//

import SwiftUI

struct ChargingView: View {
    @State private var height: CGFloat = 0
    var percentage: CGFloat
    var isLoading: Bool = true   // toggle skeleton on/off
    
    init(percentage: Double) {
        self.percentage = CGFloat(percentage)
    }
    
    var color: Color {
        switch percentage {
        case 1...30:     return .red      // 0–30
        case 30..<60:    return .yellow   // 30–<60
        default:         return Color(hex: "#34C759")    // 60–100
        }
    }
    
    
    var body: some View {
        ZStack {
            // ---- Original charging content ----
            VStack(spacing: 0) {
                Rectangle()
                    .fill(LinearGradient.evBrandCyanGradientVertical)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                
                Rectangle()
                    .fill(color)
                    .frame(maxWidth: .infinity, alignment: .bottom)
                    .frame(height: (percentage == 0 ? height : (height * percentage / 100)) + 20)
            }
            .cornerRadius(12)
            .background(
                GeometryReader { geo in
                    Color.clear.onAppear { height = geo.size.height }
                }
            )
            .overlay(
                Group {
                    if percentage > 0 {
                        textPercentage
                    }
                },
                alignment: .center
            )

            // ---- Vertical skeleton overlay ----
            if isLoading {
                VerticalSkeleton()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .allowsHitTesting(false)
            }
        }
    }

    private var textPercentage: some View {
        Text("\(Int(percentage)) %")
            .foregroundColor(.evbrandCyan80.opacity(0.7))
            .font(.robotoBold32)
    }
}

#Preview {
    ChargingView(percentage: 72)
        .frame(height: 220)
        .padding()
}

private struct VerticalSkeleton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1   // -1 → 1 loop

    var baseColor: Color = .gray.opacity(0.18)
    var highlight: Color = .gray.opacity(0.35)
    var duration: Double = 1.4
    var bandHeightFraction: CGFloat = 0.35   // relative size of highlight band

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let band = h * bandHeightFraction

            ZStack {
                // Base background
                Rectangle().fill(baseColor)

                // Moving vertical highlight band
                LinearGradient(
                    gradient: Gradient(colors: [
                        baseColor.opacity(0.0),
                        highlight,
                        baseColor.opacity(0.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: band)
                .offset(y: offsetY(containerHeight: h, bandHeight: band))
                .blendMode(.plusLighter)
                .accessibilityHidden(true)
            }
            .onAppear {
                guard !reduceMotion else { return }
                // animate from top to bottom and back
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: true)) {
                    phase = 1
                }
            }
        }
    }

    private func offsetY(containerHeight h: CGFloat, bandHeight band: CGFloat) -> CGFloat {
        // travel distance so the band moves fully through the view
        let travel = h + band
        // map phase [-1,1] to [0,1]
        let t = (phase + 1) / 2
        return -travel/2 + t * travel
    }
}
