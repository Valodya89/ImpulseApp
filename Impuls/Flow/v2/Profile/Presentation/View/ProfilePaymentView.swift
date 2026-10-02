//
//  ProfilePaymentView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 14.04.24.
//

import SwiftUI

/// Balance card on the profile: label, amount with currency, and the yellow
/// top-up button. Adaptive surface, no white hardcoded anywhere.
struct ProfilePaymentView: View {

    let currency: String
    let balance: String
    let isBalanceNegative: Bool
    let replanishAction: (() -> Void)?

    init(currency: String, balance: String, isBalanceNegative: Bool, replanishAction: (() -> Void)? = nil) {
        self.currency = currency
        self.balance = balance
        self.isBalanceNegative = isBalanceNegative
        self.replanishAction = replanishAction
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("MOBILE_profile_page_wallet_payment_balance".localized())
                    .font(.robotoRegular12)
                    .foregroundColor(.gray5)

                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(balance)
                        .font(.robotoBold24)
                        .foregroundColor(isBalanceNegative ? .errorRed : .appLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(currency)
                        .font(.robotoMedium12)
                        .foregroundColor(.gray5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let replanishAction {
                Button(action: replanishAction) {
                    Circle()
                        .fill(Color.brandYellow)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.onBrandLabel)
                        )
                }
                .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .mimoCard()
    }
}
