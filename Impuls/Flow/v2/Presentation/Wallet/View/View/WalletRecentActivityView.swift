//
//  WalletRecentActivityView.swift
//  Impuls
//
//  The last few transactions, inline on the wallet, with a way into the full
//  list. Rows are `TransactionRowView`, the same one the list draws, so the
//  preview and the list read as one thing.
//

import SwiftUI

struct WalletRecentActivityView: View {

    let transactions: [TransactionDTO]
    let onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center) {
                MimoSectionLabel(title: "MOBILE_wallet_recent_activity".localized(fallback: "Recent activity"))

                Button {
                    VibrateManager.vibrate()
                    onSeeAll()
                } label: {
                    HStack(spacing: 2) {
                        Text("MOBILE_wallet_see_all".localized(fallback: "See all"))
                            .font(.robotoMedium13)
                            .foregroundColor(.appSecondaryLabel)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gray5)
                    }
                    .padding(.horizontal, 4)
                    .frame(height: 32)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(transactions.enumerated()), id: \.element.id) { index, item in
                    TransactionRowView(item: item)

                    if index < transactions.count - 1 {
                        MimoRowDivider()
                    }
                }
            }
            .mimoCard()
        }
    }
}
