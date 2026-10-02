//
//  TransferAmountFieldView.swift
//  Impuls
//
//  Amount entry of the transfer flow: one large figure with the wallet
//  currency next to it, an underline, and the quick amount chips below.
//

import SwiftUI

struct TransferAmountFieldView: View {

    let title: String
    let currency: String
    @Binding var amount: String
    @Binding var isEditing: Bool

    var body: some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.robotoLight14)
                .foregroundColor(.gray5)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                TextField("0", text: $amount, onEditingChanged: { editing in
                    isEditing = editing
                })
                .font(.robotoBold32)
                .foregroundColor(.appLabel)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: true, vertical: false)

                Text(currency)
                    .font(.robotoMedium17)
                    .foregroundColor(.appSecondaryLabel)
                    .lineLimit(1)
            }
            .frame(minHeight: 44)
            .padding(.top, 12)

            Rectangle()
                .fill(isEditing ? Color.brandYellow : Color.dividerColor)
                .frame(height: 1)
                .padding(.top, 8)
                .animation(.easeOut(duration: 0.2), value: isEditing)
        }
    }
}

/// Quick amounts: one tap fills the field. The selected chip is the only
/// yellow element in this region.
struct TransferQuickAmountsView: View {

    let amounts: [Double]
    let title: (Double) -> String
    let isSelected: (Double) -> Bool
    let action: (Double) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(amounts, id: \.self) { value in
                Button(action: { action(value) }) {
                    Text(title(value))
                        .font(.robotoMedium14)
                        .foregroundColor(isSelected(value) ? .onBrandLabel : .appSecondaryLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            Capsule().fill(isSelected(value) ? Color.brandYellow : Color.appFill)
                        )
                        .overlay(
                            Capsule().stroke(isSelected(value) ? Color.clear : Color.appSeparator, lineWidth: 1)
                        )
                }
            }
        }
    }
}
