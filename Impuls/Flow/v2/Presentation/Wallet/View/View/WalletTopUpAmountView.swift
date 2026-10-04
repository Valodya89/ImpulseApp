//
//  WalletTopUpAmountView.swift
//  Impuls
//
//  Amount entry for a top-up: one large figure with the wallet currency, an
//  underline that lights up while editing, and quick amount chips so the
//  common cases are a single tap. Six whole digits and two decimals at most;
//  ',' and '.' are both accepted as the decimal separator, so a pre-filled
//  debt such as 150.5 can be paid as typed.
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
                    .keyboardType(.decimalPad)
                    .font(.robotoBold32)
                    .foregroundColor(.appLabel)
                    .multilineTextAlignment(.leading)
                    .focused(isFocused)
                    .onReceive(Just(amount)) { _ in
                        let sanitised = Self.sanitise(amount)
                        if sanitised != amount {
                            amount = sanitised
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
                isSelected: { MimoWalletViewModel.parseAmount(amount) == $0 },
                action: { value in
                    VibrateManager.vibrate()
                    amount = MimoWalletViewModel.amountText(value)
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

    /// Keeps the field a decimal amount: digits, one decimal separator (',' or
    /// '.', kept as typed), at most six whole digits and two decimals. Anything
    /// else - letters, a second separator, extra digits - is dropped as typed.
    static func sanitise(_ text: String) -> String {
        var whole = ""
        var fraction = ""
        var separator: Character?

        for character in text {
            if character.isNumber {
                if separator == nil {
                    if whole.count < 6 { whole.append(character) }
                } else if fraction.count < 2 {
                    fraction.append(character)
                }
            } else if (character == "." || character == ","), separator == nil {
                separator = character
            }
        }

        guard let separator else { return whole }
        return (whole.isEmpty ? "0" : whole) + String(separator) + fraction
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
