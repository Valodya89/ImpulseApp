//
//  WalletTopUpAmountView.swift
//  Impuls
//
//  Amount entry for a top-up: one large figure with the wallet currency, an
//  underline that lights up while editing, and quick amount chips so the
//  common cases are a single tap. Six digits at most, as before.
//

import SwiftUI
import Combine

struct WalletTopUpAmountView: View {

    let currency: String
    let quickAmounts: [Double]
    @Binding var amount: String
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        VStack(spacing: 0) {
            Text("MOBILE_global_insert_amount".localized())
                .font(.robotoRegular13)
                .foregroundColor(.gray5)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                TextField("0", text: $amount)
                    .keyboardType(.numberPad)
                    .font(.robotoBold32)
                    .foregroundColor(.appLabel)
                    .multilineTextAlignment(.leading)
                    .focused(isFocused)
                    .onReceive(Just(amount)) { _ in
                        let digits = amount.filter { $0.isNumber }
                        let trimmed = String(digits.prefix(6))
                        if trimmed != amount {
                            amount = trimmed
                        }
                    }

                Text(currency)
                    .font(.robotoMedium17)
                    .foregroundColor(.appSecondaryLabel)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if !amount.isEmpty {
                    Button {
                        VibrateManager.vibrate()
                        amount = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundColor(.gray5)
                            .frame(width: 44, height: 44)
                    }
                    .transition(.opacity)
                }
            }
            .frame(minHeight: 44)
            .padding(.top, 4)
            .animation(.easeOut(duration: 0.2), value: amount.isEmpty)

            Rectangle()
                .fill(isFocused.wrappedValue ? Color.brandYellow : Color.dividerColor)
                .frame(height: isFocused.wrappedValue ? 2 : 1)
                .animation(.easeOut(duration: 0.2), value: isFocused.wrappedValue)

            WalletQuickAmountsView(
                amounts: quickAmounts,
                title: { MimoWalletViewModel.format(amount: $0) },
                isSelected: { Double(amount) == $0 },
                action: { value in
                    VibrateManager.vibrate()
                    amount = String(Int(value))
                }
            )
            .padding(.top, 16)
        }
        .mimoCard(padding: 16)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused.wrappedValue = true
        }
    }
}

/// A row of one-tap amount chips; the chip matching the typed amount is filled.
struct WalletQuickAmountsView: View {

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
