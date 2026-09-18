//
//  WalletPromoCodeCard.swift
//  Impuls
//
//  Promo code entry as a disclosure row: collapsed it is one quiet line, open
//  it reveals the code field and an Apply button. Most riders never have a
//  code, so it should not take the space of a full form.
//

import SwiftUI

struct WalletPromoCodeCard: View {

    @Binding var promoCode: String
    @Binding var isExpanded: Bool
    let onApply: (String) -> Void

    @FocusState private var isFieldFocused: Bool

    private var trimmedCode: String {
        promoCode.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            MimoListRow(
                icon: Image("profile_promoCode"),
                title: "MOBILE_wallet_have_promo_code".localized(fallback: "Have a promo code?"),
                subtitle: isExpanded ? nil : "MOBILE_wallet_promo_code_hint".localized(fallback: "Apply it to get a bonus on your balance")
            ) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray5)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .onTapGesture {
                VibrateManager.vibrate()
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
                isFieldFocused = isExpanded
            }

            if isExpanded {
                HStack(spacing: 10) {
                    TextField("MOBILE_promo_code".localized(), text: $promoCode)
                        .font(.robotoMedium15)
                        .foregroundColor(.appLabel)
                        .textInputAutocapitalization(.characters)
                        .disableAutocorrection(true)
                        .submitLabel(.done)
                        .focused($isFieldFocused)
                        .onSubmit {
                            guard !trimmedCode.isEmpty else { return }
                            onApply(trimmedCode)
                        }
                        .padding(.leading, 14)
                        .frame(height: 44)

                    Button {
                        VibrateManager.vibrate()
                        isFieldFocused = false
                        onApply(trimmedCode)
                    } label: {
                        Text("MOBILE_global_submit".localized())
                            .font(.robotoBold14)
                            .foregroundColor(trimmedCode.isEmpty ? .appSecondaryLabel : .onBrandLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .padding(.horizontal, 16)
                            .frame(height: 36)
                            .background(Capsule().fill(trimmedCode.isEmpty ? Color.label025 : Color.brandYellow))
                    }
                    .disabled(trimmedCode.isEmpty)
                    .padding(.trailing, 4)
                }
                .background(Color.appFill)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isFieldFocused ? Color.brandYellow : Color.clear, lineWidth: 1.5)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .mimoCard()
    }
}
