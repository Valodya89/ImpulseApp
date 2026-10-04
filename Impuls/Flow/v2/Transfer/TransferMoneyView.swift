//
//  TransferMoneyView.swift
//  Impuls
//
//  "Transfer money to a friend", redesigned. Replaces the storyboard pair
//  TransferViewController + TransferToFriendViewController with one modal
//  screen in two steps: find the recipient (phone number, address book or a
//  recent recipient), then enter the amount and send. Presented through
//  `TransferHostingController`.
//

import SwiftUI
import SwiftMessages

struct TransferMoneyView: View {

    @ObservedObject var viewModel: TransferMoneyViewModel
    let onClose: () -> Void

    @State private var isCountryCodePresented = false
    @State private var isPhoneEditing = false
    @State private var isAmountEditing = false

    var body: some View {
        VStack(spacing: 0) {
            MimoSheetHeader(title: "MOBILE_wallet_transfer_money".localized(),
                            systemImage: showsBackChevron ? "chevron.left" : "xmark") {
                if showsBackChevron {
                    viewModel.backToSearch()
                } else {
                    onClose()
                }
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    switch viewModel.step {
                    case .findRecipient:
                        findRecipientStep
                    case .amount:
                        amountStep
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
            }
            .onTapGesture {
                UIApplication.shared.dismissKeyboard()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSecondaryBackground.ignoresSafeArea())
        .onAppear { viewModel.loadRecentRecipients() }
        .sheet(isPresented: $isCountryCodePresented) {
            CountryCodeView(code: $viewModel.selectedCountry)
        }
        .alert(isPresented: Binding(get: { viewModel.invitePhoneNumber != nil },
                                    set: { if !$0 { viewModel.invitePhoneNumber = nil } })) {
            Alert(
                title: Text("MOBILE_transfer_invite".localized() + " " + (viewModel.invitePhoneNumber ?? "")),
                message: Text("MOBILE_transfer_invite_or_not".localized()),
                primaryButton: .default(Text("MOBILE_transfer_invite".localized())) {
                    viewModel.inviteConfirmed()
                },
                secondaryButton: .cancel(Text("MOBILE_global_cancel".localized()))
            )
        }
        .swiftMessage(message: Binding(get: { viewModel.successMessage },
                                       set: { viewModel.successMessage = $0 }))
        .swiftMessage(message: Binding(get: { viewModel.errorMessage },
                                       set: { viewModel.errorMessage = $0 }))
        .onReceive(viewModel.$didTransfer) { didTransfer in
            guard didTransfer else { return }

            // Leave the success toast on screen long enough to be read before
            // the sheet goes away.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                onClose()
            }
        }
    }

    /// The amount step returns to the search step, unless the flow opened
    /// straight on it (paying a debt to a known rider).
    private var showsBackChevron: Bool {
        viewModel.step == .amount && !viewModel.startedOnAmount
    }

    // MARK: - Step 1: find the recipient

    @ViewBuilder
    private var findRecipientStep: some View {
        TransferPhoneNumberField(
            title: "MOBILE_sign_in_phone_number".localized().replacingOccurrences(of: "\n", with: ""),
            flag: viewModel.selectedCountry?.flag,
            dialCode: viewModel.selectedCountry?.dial_code ?? "",
            placeholder: viewModel.exampleNumber ?? "",
            text: $viewModel.phoneNumber,
            isEditing: $isPhoneEditing,
            onPickCountry: { isCountryCodePresented = true }
        )

        MimoListRow(
            icon: Image("ic_contacts"),
            title: "MOBILE_wallet_find_from_contacts".localized()
        )
        .mimoCard()
        .onTapGesture {
            VibrateManager.vibrate()
            UIApplication.shared.dismissKeyboard()
            // Presented with UIKit, not a `.sheet`: the system picker
            // dismisses itself after a pick, and inside a SwiftUI sheet that
            // closed this whole screen instead of just the picker.
            TransferContactPicker.present { numbers in
                viewModel.contactPicked(phoneNumbers: numbers)
            }
        }
        .confirmationDialog(
            "MOBILE_transfer_select_number".localized(fallback: "Select a phone number"),
            isPresented: Binding(get: { !viewModel.contactPhoneChoices.isEmpty },
                                 set: { if !$0 { viewModel.contactPhoneChoices = [] } }),
            titleVisibility: .visible
        ) {
            ForEach(viewModel.contactPhoneChoices) { choice in
                Button(choice.number) { viewModel.contactNumberChosen(choice.number) }
            }

            Button("MOBILE_global_cancel".localized(), role: .cancel) {
                viewModel.contactPhoneChoices = []
            }
        }

        Button {
            UIApplication.shared.dismissKeyboard()
            viewModel.findTapped()
        } label: {
            Text("MOBILE_transfer_find_user".localized())
        }
        .buttonStyle(MimoButton(isEnabled: viewModel.canFind))
        .disabled(!viewModel.canFind)
        .padding(.top, 6)

        if !viewModel.recentRecipients.isEmpty {
            MimoSectionLabel(title: "MOBILE_transfer_recent".localized(fallback: "Recent"))
                .padding(.top, 14)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.recentRecipients.enumerated()), id: \.offset) { index, recipient in
                    TransferRecipientCardView(recipient: recipient, size: 40)
                        .onTapGesture {
                            VibrateManager.vibrate()
                            UIApplication.shared.dismissKeyboard()
                            viewModel.recentRecipientTapped(recipient)
                        }

                    if index < viewModel.recentRecipients.count - 1 {
                        MimoRowDivider()
                    }
                }
            }
            .mimoCard()
        } else if viewModel.recentRecipientsLoaded {
            // No transfers yet: fill the space where the Recent card would be
            // instead of leaving the screen blank under the search block.
            VStack(spacing: 16) {
                Image("ic_empty_data")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 164, height: 164)
                    .accessibilityHidden(true)
                Text("MOBILE_transfer_no_recent".localized(fallback: "No transfers yet"))
                    .font(.robotoRegular16)
                    .foregroundColor(.appSecondaryLabel)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
            .padding(.top, 40)
        }
    }

    // MARK: - Step 2: amount

    @ViewBuilder
    private var amountStep: some View {
        if let recipient = viewModel.recipient {
            TransferRecipientCardView(recipient: recipient)
                .mimoCard()
        }

        HStack(spacing: 10) {
            Text("MOBILE_profile_page_wallet_payment_balance".localized())
                .font(.robotoRegular15)
                .foregroundColor(.appSecondaryLabel)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(viewModel.formattedBalance)
                .font(.robotoBold17)
                .foregroundColor(.appLabel)

            Text(viewModel.currency)
                .font(.robotoLight13)
                .foregroundColor(.gray5)
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .mimoCard()

        TransferAmountFieldView(
            title: "MOBILE_global_insert_amount".localized(),
            currency: viewModel.currency,
            amount: $viewModel.amount,
            isEditing: $isAmountEditing
        )
        .padding(.horizontal, 40)
        .padding(.top, 24)

        TransferQuickAmountsView(
            amounts: TransferMoneyViewModel.quickAmounts,
            title: { viewModel.formattedQuickAmount($0) },
            isSelected: { viewModel.isQuickAmountSelected($0) },
            action: { viewModel.quickAmountTapped($0) }
        )
        .padding(.top, 20)

        Button {
            UIApplication.shared.dismissKeyboard()
            viewModel.transferTapped()
        } label: {
            Text("MOBILE_transfer_send_money".localized())
        }
        .buttonStyle(MimoButton(isEnabled: viewModel.canTransfer))
        .disabled(!viewModel.canTransfer)
        .padding(.top, 28)
    }
}
