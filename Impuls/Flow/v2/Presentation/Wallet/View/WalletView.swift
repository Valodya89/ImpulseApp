//
//  WalletView.swift
//  Impuls
//
//  Created by Razmik Mkhitaryan on 22.04.24.
//
//  The wallet, redesigned. Top to bottom: a balance hero with the three quick
//  actions (top up, send, history), the top-up amount with one-tap chips, one
//  "pay with" list where the attached card and the other providers are chosen
//  with a radio mark, the promo code as a disclosure, the newest transactions
//  with a way into the full list, and the card order behind its flag. A sticky
//  bottom button carries the amount it is about to pay. Every provider path,
//  alert and success toast is the same as before; only the drawing changed.
//

import SwiftUI
import SwiftMessages

struct WalletView: View {
    /// The "order a Mimo card" row is switched off until the card ships.
    private static let isCardOrderAvailable = false


    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

    @State private var deleteCardAlert: Bool = false
    @State private var attachMirCardAlert: Bool = false
    @State private var attachCardAlertMessage: String = ""
    @State private var attachCardPendingProvider: PaymentMethodProvider = .tinkoff
    @State private var successMessage: SuccessMessage?
    @State private var errorMessage: ErrorMessage?
    @State private var showTransactions: Bool = false
    @State private var isPromoExpanded: Bool = false
    @FocusState private var isAmountFocused: Bool

    @ObservedObject private var viewModel: MimoWalletViewModel

    private let amountAnchor = "wallet.amount"

    init(viewModel: MimoWalletViewModel) {
        self.viewModel = viewModel

        // SwiftUI rebuilds this struct on any parent change; only the first
        // build should start the load, later ones already have the wallet or a
        // load in flight.
        if viewModel.wallet == nil, !viewModel.isLoading {
            viewModel.loadData()
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            MimoSheetHeader(title: "MOBILE_global_mimo_wallet".localized()) {
                presentationMode.wrappedValue.dismiss()
            }
            .alert(isPresented: $attachMirCardAlert) {
                Alert(title: Text("MOBILE_global_warning".localized()),
                      message: Text(attachCardAlertMessage),
                      primaryButton: .default(
                        Text("MOBILE_global_continue".localized()),
                        action: {
                            viewModel.attachCard(provider: attachCardPendingProvider)
                        }),
                      secondaryButton: .cancel(Text("MOBILE_global_cancel".localized()))
                )
            }

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        if viewModel.wallet == nil {
                            if viewModel.loadFailed {
                                loadFailedState
                            } else {
                                skeleton
                            }
                        } else {
                            content(scrollProxy: proxy)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                    .mimoRefreshable { done in
                        viewModel.reload(completion: done)
                    }
                }
                .onTapGesture {
                    UIApplication.shared.dismissKeyboard()
                }
            }

            bottomBar
                .alert(isPresented: $deleteCardAlert) {
                    Alert(title: Text("MOBILE_global_warning".localized()),
                          message: Text("MOBILE_delete_own_card".localized()),
                          primaryButton: .destructive(
                            Text("MOBILE_global_continue".localized()),
                            action: {
                                viewModel.deleteAttachedCard()
                            }),
                          secondaryButton: .cancel(Text("MOBILE_global_cancel".localized()))
                    )
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSecondaryBackground.ignoresSafeArea())
        .sheet(
            item: $viewModel.attachCardURL,
            onDismiss: {
                Resolver.resolve(MessageServiceProtocol.self).publish(.balanceUpdated)
                viewModel.loadData()
            },
            content: { url in
                InAppWebView(
                    url: url.id
                )
            }
        )
        .sheet(isPresented: $showTransactions, content: {
            TransactionListView(viewModel: viewModel.transactionListViewModel)
        })
        .onReceive(viewModel.$errorMessage) { error in
            if let errorMessage = error {
                MILoader.hide()
                self.errorMessage = ErrorMessage(title: "MOBILE__global_attention".localized(), body: errorMessage.localized())
            }
        }
        .onReceive(viewModel.$depositSuccess) { isSuccess in
            if isSuccess {
                successMessage = SuccessMessage(title: "MOBILE_global_success_title".localized(), body: "MOBILE_wallet_successfully_replenished".localized())
                viewModel.amount = ""
                viewModel.depositSuccess = false
            }
        }
        .onReceive(viewModel.$telcellDepositSuccess) { isSuccess in
            if isSuccess {
                successMessage = SuccessMessage(title: "MOBILE_verify_successful_alert".localized(), body: "MOBILE__trip_sent_telcell".localized())
                viewModel.amount = ""
                viewModel.telcellDepositSuccess = false
            }
        }
        .onReceive(viewModel.$fastshiftDepositSuccess) { isSuccess in
            if isSuccess {
                successMessage = SuccessMessage(title: "MOBILE_verify_successful_alert".localized(), body: "MOBILE__trip_sent_telcell".localized())
                viewModel.amount = ""
                viewModel.fastshiftDepositSuccess = false
            }
        }
        .onReceive(viewModel.$myAmeriaDepositSuccess) { isSuccess in
            if isSuccess {
                successMessage = SuccessMessage(title: "MOBILE_verify_successful_alert".localized(), body: "MOBILE__trip_sent_telcell".localized())
                viewModel.amount = ""
                viewModel.myAmeriaDepositSuccess = false
            }
        }
        .onReceive(viewModel.$easyPayDepositSuccess) { isSuccess in
            if isSuccess {
                successMessage = SuccessMessage(title: "MOBILE_verify_successful_alert".localized(), body: "MOBILE__trip_sent_telcell".localized())
                viewModel.amount = ""
                viewModel.easyPayDepositSuccess = false
            }
        }
        .onReceive(viewModel.$promoCodeSuccess) { isSuccess in
            if isSuccess {
                successMessage = SuccessMessage(title: "MOBILE_global_success_title".localized(), body: "MOBILE_global_success".localized())
                viewModel.promoCodeSuccess = false
                viewModel.promoCode = ""
                withAnimation(.easeInOut(duration: 0.25)) {
                    isPromoExpanded = false
                }
                MILoader.hide()
            }
        }
        .swiftMessage(message: $successMessage)
        .swiftMessage(message: $errorMessage)
    }

    // MARK: - Content

    @ViewBuilder
    private func content(scrollProxy: ScrollViewProxy) -> some View {
        WalletBalanceHeroView(
            balance: viewModel.balance,
            currency: viewModel.currency,
            isNegative: viewModel.isBalanceNegative,
            attachedCardMask: viewModel.wallet?.card?.cardMask,
            onTopUp: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    scrollProxy.scrollTo(amountAnchor, anchor: .top)
                }
                isAmountFocused = true
            },
            onSend: openTransfer,
            onHistory: { showTransactions = true }
        )

        MimoSectionLabel(title: "MOBILE_wallet_top_up".localized(fallback: "Top up"))
            .padding(.top, 6)

        WalletTopUpAmountView(
            currency: viewModel.currency,
            quickAmounts: viewModel.quickAmounts,
            amount: $viewModel.amount,
            isFocused: $isAmountFocused
        )
        .id(amountAnchor)

        MimoSectionLabel(title: "MOBILE_wallet_pay_with".localized(fallback: "Pay with"))
            .padding(.top, 6)

        paymentMethodsCard

        if viewModel.isPromoAvailable {
            WalletPromoCodeCard(
                promoCode: $viewModel.promoCode,
                isExpanded: $isPromoExpanded,
                onApply: { code in
                    UIApplication.shared.dismissKeyboard()
                    MILoader.show()
                    viewModel.submit(promoCode: code)
                }
            )
            .padding(.top, 6)
        }

        if !viewModel.recentTransactions.isEmpty {
            WalletRecentActivityView(
                transactions: viewModel.recentTransactions,
                onSeeAll: { showTransactions = true }
            )
            .padding(.top, 6)
        }

        // Hidden until the physical card is ready; the "More" section holds
        // nothing else yet, so the label goes with it. Not remote-controlled
        // for now - flip the constant to bring the row back.
        if Self.isCardOrderAvailable {
            MimoSectionLabel(title: "MOBILE_wallet_more".localized(fallback: "More"))
                .padding(.top, 6)

            MimoListRow(
                icon: Image(systemName: "creditcard"),
                title: "MOBILE_wallet_Mimo_Card".localized(),
                subtitle: "MOBILE_wallet_order_card_for_free".localized()
            )
            .mimoCard()
            .onTapGesture {
                VibrateManager.vibrate()
                UIApplication.shared.dismissKeyboard()
                let orderCardVC = OrderCardViewController.initFromStoryboard(name: Constant.Storyboards.orderCard)
                UIApplication.shared.topMostViewController()?.present(orderCardVC, animated: true)
            }
        }
    }

    /// The attached card, the ways to attach one, and the other providers as
    /// one list. Rows with a radio mark select; the "add card" rows attach.
    private var paymentMethodsCard: some View {
        VStack(spacing: 0) {
            if let card = viewModel.wallet?.card {
                WalletPaymentMethodRow(
                    logo: .asset(card.image),
                    title: card.cardMask,
                    subtitle: "MOBILE_wallet_my_card".localized(fallback: "Bank card"),
                    isSelected: viewModel.selectedPaymentMethod == nil
                ) {
                    HStack(spacing: 4) {
                        Button {
                            VibrateManager.vibrate()
                            deleteCardAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.gray5)
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(Text("MOBILE_delete_own_card".localized()))

                        WalletSelectionIndicator(isSelected: viewModel.selectedPaymentMethod == nil)
                    }
                }
                .onTapGesture {
                    VibrateManager.vibrate()
                    viewModel.selectAttachedCard()
                }
            } else {
                ForEach(viewModel.cardPaymentMethods) { paymentMethod in
                    WalletPaymentMethodRow(
                        logo: .remote(paymentMethod.logo?.imageURL),
                        title: paymentMethod.description,
                        subtitle: "MOBILE_wallet_add_card_hint".localized(fallback: "Visa, Mastercard, ArCa, Amex")
                    ) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.appLabel)
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(Color.appFill))
                    }
                    .onTapGesture {
                        VibrateManager.vibrate()
                        if let popup = paymentMethod.popup {
                            attachCardAlertMessage = popup
                            attachCardPendingProvider = paymentMethod.provider
                            attachMirCardAlert = true
                        } else {
                            viewModel.attachCard(provider: paymentMethod.provider)
                        }
                    }

                    if paymentMethod.id != viewModel.cardPaymentMethods.last?.id || !viewModel.otherPaymentMethods.isEmpty {
                        MimoRowDivider()
                    }
                }
            }

            if viewModel.wallet?.card != nil, !viewModel.otherPaymentMethods.isEmpty {
                MimoRowDivider()
            }

            ForEach(Array(viewModel.otherPaymentMethods.enumerated()), id: \.element.id) { index, paymentMethod in
                WalletPaymentMethodRow(
                    logo: .remote(paymentMethod.logo?.imageURL),
                    title: paymentMethod.description,
                    isSelected: viewModel.selectedPaymentMethod?.id == paymentMethod.id
                )
                .onTapGesture {
                    VibrateManager.vibrate()
                    viewModel.select(paymentMethod)
                }

                if index < viewModel.otherPaymentMethods.count - 1 {
                    MimoRowDivider()
                }
            }
        }
        .mimoCard()
    }

    /// Sticky primary action. The title carries the amount so the rider sees
    /// what is about to be paid without looking back up.
    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.dividerColor)
                .frame(height: 1)

            Button {
                UIApplication.shared.dismissKeyboard()
                viewModel.deposit()
            } label: {
                Text(viewModel.proceedTitle)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 12)
            }
            .buttonStyle(MimoButton(isEnabled: viewModel.canProceed))
            .disabled(!viewModel.canProceed)
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
        .background(Color.appSecondaryBackground)
    }

    // MARK: - Loading and failure

    /// Placeholders in the shape of the real screen, so the layout does not
    /// jump when the wallet arrives.
    private var skeleton: some View {
        VStack(alignment: .leading, spacing: 10) {
            WalletBalanceHeroView(
                balance: "12 500",
                currency: "AMD",
                isNegative: false,
                attachedCardMask: nil,
                onTopUp: {},
                onSend: {},
                onHistory: {}
            )

            MimoSectionLabel(title: "MOBILE_wallet_top_up".localized(fallback: "Top up"))
                .padding(.top, 6)

            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appBackground)
                .frame(height: 150)

            MimoSectionLabel(title: "MOBILE_wallet_pay_with".localized(fallback: "Pay with"))
                .padding(.top, 6)

            VStack(spacing: 0) {
                ForEach(0..<3, id: \.self) { index in
                    WalletPaymentMethodRow(
                        logo: .asset("card_visa"),
                        title: "Payment method",
                        subtitle: "Placeholder",
                        isSelected: false
                    )

                    if index < 2 {
                        MimoRowDivider()
                    }
                }
            }
            .mimoCard()
        }
        .redacted(reason: .placeholder)
        .disabled(true)
        .accessibilityHidden(true)
    }

    private var loadFailedState: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34, weight: .regular))
                .foregroundColor(.gray5)

            Text("MOBILE_something_wrong".localized(fallback: "Something went wrong. Please try again."))
                .font(.robotoRegular15)
                .foregroundColor(.appSecondaryLabel)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                VibrateManager.vibrate()
                viewModel.reload()
            } label: {
                Text("MOBILE_try_again".localized(fallback: "Try again"))
                    .padding(.horizontal, 12)
            }
            .buttonStyle(MimoSecondaryButton())
            .frame(maxWidth: 200)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    // MARK: - Actions

    private func openTransfer() {
        UIApplication.shared.dismissKeyboard()
        if UserManager.share.isHaveBikeTrip || UserManager.share.isHaveScooterTrip {
            errorMessage = ErrorMessage(title: "MOBILE__global_attention".localized(), body: "MOBILE_have_active_trip".localized())
        } else {
            let transferVC = TransferHostingController(wallet: viewModel.wallet)
            UIApplication.shared.topMostViewController()?.present(transferVC, animated: true, completion: nil)
        }
    }
}

extension WalletView {
    var productItemGroup: some View {
        VStack {
            ForEach(viewModel.productItemViewModels, id: \.text) { item in
                ProductItemView(viewModel: item)

                Divider()
            }
        }
        .padding(.top, 6)
        .padding(.horizontal)
        .roundedBorderMedium()
        .sectionTopContent(icon: "gift", label: "Your Rewards".uppercased(), labelValue: "1 Mimo point = 1$")
    }
}
