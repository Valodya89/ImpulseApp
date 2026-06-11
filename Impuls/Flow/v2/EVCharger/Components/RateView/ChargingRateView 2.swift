//
//  ChargingRateView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 14.03.25.
//

import SwiftUI

struct ChargingRateView: View {
    
    @Binding var heightOnchange: CGFloat
    @State private var height: CGFloat = .zero
    @State private var width: CGFloat = .zero
    
    @State var widthSlack: CGFloat = 120
    @State var heightSlack: CGFloat = 30
    @State var ispresentedSlack: Bool = false
    
    let maxKWate: CGFloat
    let priceKW: Double
    let currency: String
    
    var currentAmount: Double {
        Double(maxKWate * heightOnchange) * priceKW
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerSize: .zero)
                .fill(.white)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                self.height = geometry.frame(in: .global).height
                                self.width = geometry.frame(in: .global).width
                            }
                    }
                )
            RoundedRectangle(cornerSize: .zero)
                .fill(Color.evbrandCyan80)
                .frame(height: height * heightOnchange)
        }
        .cornerRadius(16)
        .gesture(
            DragGesture()
                .onChanged { drag in
                    ispresentedSlack = true
                    let rate = height - drag.location.y
                    if rate <= 0 {
                        heightOnchange = 0
                    } else if rate >= height {
                        heightOnchange = 1
                    } else {
                        heightOnchange = rate / height
                    }
                }
                .onEnded { _ in
                    ispresentedSlack = false
                }
        )
        .onChange(of: heightOnchange) { value in
            if heightOnchange < 0 {
                heightOnchange = 0
            } else if heightOnchange > 1 {
                heightOnchange = 1
            }
        }
        .overlay(superFastIcon, alignment: .center)
        .overlay(slack, alignment: .bottom)
        .overlay(plusMinus, alignment: .trailing)
        .overlay(amount, alignment: .leading)
        .overlay(wate, alignment: .trailing)
    }
    
    @ViewBuilder
    var superFastIcon: some View {
        if heightOnchange == 1 {
            Image(.evChargingTypeSuperFastCyan)
                .renderingMode(.template)
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
        }
    }
    
    @ViewBuilder
    var slack: some View {
        if ispresentedSlack {
            HStack(spacing: 10) {
                VStack(alignment: .trailing, spacing: 6) {
                     Text("\(Int(currentAmount)) \(Currency.amd.symbol)")
                        .font(.robotoBold15)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    Text("\(Int(maxKWate * heightOnchange))" + "EV_CHARGER_kw".localized())
                        .font(.robotoBold15)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                Rectangle()
                    .fill(Color.evbrandCyan80)
                    .frame(width: 9, height: 18)
                    .clipShape(EVTriangle(radius: 0, angleShape: .isoscelesTriangleTrailing))
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            self.heightSlack = geometry.frame(in: .global).height
                            self.widthSlack = geometry.frame(in: .global).width
                        }
                }
            )
            .offset(x: (-width / 2) - (widthSlack / 2 + 3),
                    y: heightSlack / 2 - height * heightOnchange)
        }
    }
    
    @ViewBuilder
    var plusMinus: some View {
        if !ispresentedSlack {
            VStack(spacing: 60) {
                Image(systemName: "plus")
                    .foregroundColor(Color.evbrandCyan80)
                    .frame(width: 30, height: 30)
                    .background(Color.evbrandCyan80.opacity(0.1))
                    .clipShape(Circle())
                    .onTapGesture {
                        heightOnchange += 0.1
                    }
                    .disabled(heightOnchange >= 1)
                
                Image(systemName: "minus")
                    .foregroundColor(Color.evbrandCyan80)
                    .frame(width: 30, height: 30)
                    .background(Color.evbrandCyan80.opacity(0.1))
                    .clipShape(Circle())
                    .onTapGesture {
                        heightOnchange -= 0.1
                    }
                    .disabled(heightOnchange <= 0)
            }
            .offset(x: 40)
        }
    }
    
    @ViewBuilder
    var amount: some View {
        if !ispresentedSlack {
            Text("\(Int(currentAmount)) \(Currency.amd.symbol)")
                .font(.robotoBold15)
                .lineLimit(1)
                .frame(width: 100, alignment: .trailing)
                .offset(x: -110)
        }
    }
    
    @ViewBuilder
    var wate: some View {
        if !ispresentedSlack {
            Text("\(Int(maxKWate * heightOnchange))" + "EV_CHARGER_kw".localized())
                .font(.robotoBold15)
                .lineLimit(1)
                .frame(width: 100, alignment: .leading)
                .offset(x: 110)
        }
    }
}
