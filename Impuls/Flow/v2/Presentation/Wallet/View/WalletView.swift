//
//  WalletView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.04.24.
//

import SwiftUI
import SwiftMessages

struct WalletView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State var deleteCardAlert: Bool = false
    @State var attachMirCardAlert: Bool = false
    @State var attachCardAlertMessage: String = ""
    @State var successMessage: SuccessMessage?
    @State var errorMessage: ErrorMessage?
    @State var showTransactions: Bool = false
    @ObservedObject private var viewModel: MimoWalletViewModel
    
    init(viewModel: MimoWalletViewModel) {
        self.viewModel = viewModel
        
        viewModel.loadData()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .foregroundColor(.black)
                            .frame(width: 18, height: 18)
                            .padding(8)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 15)
                
                Text("MOBILE_global_mimo_wallet".localized())
                    .font(.robotoBold17)
                    .foregroundColor(.black)
            }
            .frame(height: 48)
            .background(Color.white)
            .alert(isPresented: $attachMirCardAlert) {
                Alert(title: Text("MOBILE_global_warning".localized()).foregroundColor(.mimoDarkGray),
                      message: Text(attachCardAlertMessage).foregroundColor(.mimoDarkGray),
                      primaryButton: .default(
                        Text("MOBILE_global_continue".localized()),
                        action: {
                            viewModel.attachCard()
                        }),
                      secondaryButton: .cancel(Text("MOBILE_global_cancel".localized()).foregroundColor(.black))
                )
            }
            
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    
                    TitleValueView(title: "MOBILE_mimo_balance".localized(), value: viewModel.balance, currency: viewModel.currency)
                        .frame(height: 60)
                        .sectionTopContent(label: "wallet".uppercased())
                        .padding(.top, 20)
                    
                    
                    IconTitleView(title: "MOBILE_profile_transactions".localized())
                        .frame(height: 60)
                        .padding(.top, 10)
                        .onTapGesture {
                            showTransactions = true
                        }
                    
                    PromoCodeView(
                        promoCode: $viewModel.promoCode,
                        submitAction: { promoCode in
                            MILoader.show()
                            viewModel.submit(promoCode: promoCode)
                        }
                    )
                    .padding(.top, 10)
                    
                    if let currency = viewModel.wallet?.currency.currencyName {
                        WalletAmountView(amount: $viewModel.amount, currency: currency)
                            .padding(.horizontal, 60)
                            .padding(.top, 32)
                    }
                    
                    HStack(alignment: .center) {
                        HeaderTitleView(title: "MOBILE_wallet_my_payment_methods".localized().uppercased())
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            ForEach(["card_master_card", "card_visa", "card_amex", "card_arca"], id: \.self) { card in
                                Image(card)
                                    .resizable()
                                    .frame(width: 32, height: 21)
                            }
                        }
                    }
                    .frame(height: 21)
                    .padding(.top, 32)
                    
                    if let card = viewModel.wallet?.card {
                        RemovablePaymentMethodView(
                            card: card,
                            isSelected: viewModel.selectedPaymentMethod?.id == PaymentMethod.attachedCard(card).id,
                            onDelete: {
                                deleteCardAlert = true
                            }
                        )
                        .frame(height: 60)
                        .padding(.top, 12)
                        .onTapGesture {
                            VibrateManager.vibrate()
                            viewModel.selectedPaymentMethod = .none
                        }
                    } else {
                        ForEach(viewModel.cardPaymentMethods) { paymentMethod in
                            IconTitleView(title: paymentMethod.description, imageURL: paymentMethod.logo?.imageURL)
                                .frame(height: 60)
                                .padding(.top, 12)
                                .onTapGesture {
                                    if let popup = paymentMethod.popup {
                                        attachCardAlertMessage = popup
                                        attachMirCardAlert = true
                                    } else {
                                        viewModel.attachCard(provider: paymentMethod.provider)
                                    }
                                }
                        }
                    }
                    
                    HeaderTitleView(title: "MOBILE_wallet_other_payment_methods".localized().uppercased())
                        .padding(.top, 32)
                    
                    PaymentMethodGridView(paymentMethods: viewModel.otherPaymentMethods, selectedMethod: $viewModel.selectedPaymentMethod)
                        .padding(.top, 12)
                    
                    Rectangle()
                        .fill(Color.dividerColor)
                        .frame(height: 1)
                        .padding(.top, 16)
                    
                    IconTitleView(title: "MOBILE__transfer_money".localized(), image: "wallet_arrow_circle")
                        .frame(height: 60)
                        .padding(.top, 12)
                        .onTapGesture {
                            if UserManager.share.isHaveBikeTrip || UserManager.share.isHaveScooterTrip {
                                errorMessage = ErrorMessage(title: "MOBILE__global_attention".localized(), body: "MOBILE_have_active_trip".localized())
                            } else {
                                let transferVC = TransferViewController.initFromStoryboard(name: Constant.Storyboards.transfer)
                                transferVC.avatarUrl = viewModel.user?.avatar?.getURL()?.absoluteString
                                transferVC.wallet = viewModel.wallet
                                
                                let nc = UINavigationController(rootViewController: transferVC)
                                UIApplication.shared.topMostViewController()?.present(nc, animated: true, completion: nil)
                            }
                        }
                    
//                    Divider()
//                        .padding(.vertical)
                    
//                   productItemGroup
                    
//                    WalletOrderCardView()
//                        .frame(height: 60)
//                        .padding(.top, 12)
//                        .onTapGesture {
//                            let orderCardVC = OrderCardViewController.initFromStoryboard(name: Constant.Storyboards.orderCard)
//                            UIApplication.shared.topMostViewController()?.present(orderCardVC, animated: true)
//                        }
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color.grayBackgroundV2.ignoresSafeArea(edges: .bottom))
            .padding(.bottom, 8)
            .alert(isPresented: $deleteCardAlert) {
                Alert(title: Text("MOBILE_global_warning".localized()).foregroundColor(.mimoDarkGray),
                      message: Text("MOBILE_delete_own_card".localized()).foregroundColor(.mimoDarkGray),
                      primaryButton: .destructive(
                        Text("MOBILE_global_continue".localized()),
                        action: {
                            viewModel.deleteAttachedCard()
                        }),
                      secondaryButton: .cancel(Text("MOBILE_global_cancel".localized()).foregroundColor(.black))
                )
            }
            
            Button {
                viewModel.deposit()
            } label: {
                Text("MOBILE_wallet_pay_proceed_to_payment".localized())
            }
            .buttonStyle(MimoButton())
            .padding(.bottom, 12)
        }
        .background(Color.grayBackgroundV2.ignoresSafeArea(edges: .bottom))
        .ignoresSafeArea(.keyboard)
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
                MILoader.hide()
            }
        }
        .swiftMessage(message: $successMessage)
        .swiftMessage(message: $errorMessage)
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
