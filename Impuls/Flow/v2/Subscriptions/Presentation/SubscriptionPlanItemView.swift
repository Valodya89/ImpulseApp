//
//  SubscriptionPlanItemView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 09.06.24.
//

import SwiftUI

struct SubscriptionPlanItemView: View {
    
    private let plan: SubscriptionPlan
    private let subtitle: String?
    private let isSelected: Bool
    
    init(plan: SubscriptionPlan, subtitle: String? = nil, isSelected: Bool = false) {
        self.plan = plan
        self.subtitle = subtitle
        self.isSelected = isSelected
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                HStack {
                    Text(plan.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black08)
                    
                    Spacer()
                    
                    Text("\(String(format: "%.0f", plan.price)) AMD")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black08)
                }
                
                Divider()
                
                Text(subtitle ?? plan.description)
                    .foregroundColor(.black)
                    .font(.system(size: 14, weight: .light))
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 16)
        }
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.brandYellow, lineWidth: isSelected ? 4 : 0)
        )
        .overlay(
            ZStack {
                Triangle()
                    .fill(Color.brandYellow)
                    .frame(width: 40, height: 40)
                    .rotationEffect(Angle(degrees: 35))
                    .padding(.top, -24)
                    .padding(.trailing, -24)
                    .overlay(
                        Image(systemName: "checkmark")
                            .resizable()
                            .font(.title.bold())
                            .foregroundColor(.black)
                            .frame(width: 7.7, height: 7)
                            .padding(.bottom, 3)
                    )
            }.opacity(isSelected ? 1 : 0)
            , alignment: .topTrailing
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
}
