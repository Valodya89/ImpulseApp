//
//  ProfilePaymentView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 14.04.24.
//

import SwiftUI

struct ProfilePaymentView: View {
    
    let freeMinutes: String
    let currency: String
    let balance: String
    let isBalanceNegative: Bool
    let replanishAction: (() -> Void)?
    
    init(freeMinutes: String, currency: String, balance: String, isBalanceNegative: Bool, replanishAction: (() -> Void)? = nil) {
        self.freeMinutes = freeMinutes
        self.currency = currency
        self.balance = balance
        self.isBalanceNegative = isBalanceNegative
        self.replanishAction = replanishAction
    }
    
    var body: some View {
        ZStack {
            HStack {
                ZStack {
                    HStack(spacing: 8) {
                        ZStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MOBILE_gloobal_free_minutes".localized())
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundColor(.black05)
                                
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text(freeMinutes)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.black05)
                                    
                                    Text("SCOOTER_global_minute".localized())
                                        .font(.system(size: 13, weight: .light))
                                        .foregroundColor(.black075)
                                }
                            }
                        }
                        .background(Color.white)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
                        
                        ZStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MOBILE_profile_page_wallet_payment_balance".localized())
                                    .font(.system(size: 12, weight: .light))
                                    .foregroundColor(.black05)
                                
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text(balance)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(isBalanceNegative ? .red : .black)
                                    
                                    Text(currency)
                                        .font(.system(size: 13, weight: .light))
                                        .foregroundColor(.black075)
                                }
                            }
                        }
                        .background(Color.white)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
                    }
                    
                    Rectangle()
                        .fill(Color.black025)
                        .frame(width: 0.5)
                        .padding(.trailing, 8)
                }
                .background(Color.white)
                
                if let replanishAction {
                    Button(action: replanishAction) {
                        Circle()
                            .fill(Color.mimoYellow500)
                            .overlay(
                                Image(systemName: "plus")
                                    .resizable()
                                    .frame(width: 15, height: 15)
                                    .foregroundColor(.black)
                            )
                    }
                    .frame(width: 38, height: 38)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 17)
        }
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
    }
}
