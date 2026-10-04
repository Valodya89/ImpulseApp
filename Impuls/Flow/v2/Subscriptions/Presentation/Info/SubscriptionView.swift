//
//  SubscriptionView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 09.06.24.
//

import SwiftUI
import SwiftMessages

struct SubscriptionView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State private var activePageIndex: Int = 0
    @State private var showSubscriptionPlans: Bool = false
    
    @ObservedObject private var viewModel: SubscriptionInfoViewModel
    
    @State var errorMessage: ErrorMessage?
    
    init(viewModel: SubscriptionInfoViewModel) {
        self.viewModel = viewModel
    }
    
    let tileWidth: CGFloat = 220
    let tilePadding: CGFloat = 12
    let numberOfTiles: Int = 3
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ZStack {
                    VStack(spacing: 24) {
                        if let activePlan = viewModel.activePlan, 
                            let plan = viewModel.plans.first(where: { $0.id == activePlan.subscriptionPlanId }) {
                            
                            SubscriptionPlanItemView(
                                plan: plan,
                                subtitle: viewModel.activePlanDate(),
                                isSelected: true
                            )
                                .frame(height: 97)
                                .padding(.horizontal, 20)

                            // Renewal stopped (activePlan.cancelled): the plan
                            // still runs until activeUntil and is not charged again.
                            if viewModel.isActivePlanCancelled {
                                Text("MOBILE_subscriptions_cancelled_notice".localized()
                                        .replacingOccurrences(of: "%@", with: viewModel.activeUntilDate()))
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.warningColor)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 20)
                                    .padding(.top, -8)
                            }
                            
                        } else if viewModel.hasNoPlans {
                            // Nothing on sale for this country/locale: the
                            // backend answered with an empty catalogue.
                            Text("MOBILE_subscriptions_empty".localized())
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.gray8)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        } else {
                            Text("MOBILE_subscriptions_mimo_title".localized())
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.gray9)
                            
                            PagingScrollView(activePageIndex: self.$activePageIndex, tileWidth: self.tileWidth, tilePadding: self.tilePadding) {
                                ForEach(viewModel.plans, id: \.id) { plan in
                                    SubscriptionPlanItemView(plan: plan)
                                }
                            }
                            .frame(height: 97)
                        }
                    }
                    .padding(.vertical, 24)
                }
                .frame(height: viewModel.activePlan == nil ? 197 : (viewModel.isActivePlanCancelled ? 201 : 161))
                .frame(maxWidth: .infinity)
                .background(Color.clearVision)
                .overlay(
                    LinearGradient(gradient: Gradient(colors: [Color.clearVision, Color.clearVision.opacity(0.5), Color.clear]), startPoint: .leading, endPoint: .trailing)
                        .frame(width: 100)
                        .allowsHitTesting(false)
                        .opacity(viewModel.activePlan == nil ? 1 : 0)
                    , alignment: .leading)
                .overlay(
                    LinearGradient(gradient: Gradient(colors: [Color.clearVision, Color.clearVision.opacity(0.5), Color.clear]), startPoint: .trailing, endPoint: .leading)
                        .frame(width: 100)
                        .allowsHitTesting(false)
                        .opacity(viewModel.activePlan == nil ? 1 : 0)
                    , alignment: .trailing)
                
                ScrollView(.vertical) {
                    VStack(spacing: 24) {
                        Text("MOBILE_subscriptions_points_title".localized())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.gray8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            ForEach(viewModel.points, id: \.self) { point in
                                HStack(alignment: .top) {
                                    Image("subscription_checkmark")
                                        .resizable()
                                        .frame(width: 18, height: 18)
                                        .padding(.top, 2)
                                    
                                    Text(point.localized())
                                        .lineLimit(3)
                                        .font(.system(size: 16))
                                        .foregroundColor(.gray8)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.top, 32)
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)
                
                NavigationLink(isActive: $showSubscriptionPlans) {
                    SubscriptionPlansView(
                        viewModel: SubscriptionPlansViewModel(
                            worker: Resolver.resolve()
                        )
                    )
                } label: {
                    Button(action: {
                        guard !viewModel.hasNoPlans else { return }
                        showSubscriptionPlans = true
                    }, label: {
                        Text(viewModel.activePlan == nil ? "MOBILE_subscriptions_button_choose_period".localized() : "MOBILE_subscriptions_button_choose_another_period".localized())
                    })
                    .buttonStyle(MimoButton(isEnabled: !viewModel.hasNoPlans))
                    .disabled(viewModel.hasNoPlans)
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("MOBILE_subscriptions_navigation_title".localized())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .foregroundColor(.appLabel)
                            .frame(width: 18, height: 18)
                            .padding(8)
                    }
                }
            }
            .onReceive(viewModel.$errorMessage) { error in
                if let errorMessage = error {
                    MILoader.hide()
                    self.errorMessage = ErrorMessage(title: "MOBILE__global_attention".localized(), body: errorMessage.localized())
                }
            }
            .swiftMessage(message: $errorMessage)
        }
        .onAppear {
            viewModel.loadData()
        }
        .onChange(of: showSubscriptionPlans) { isShown in
            // Back from the plans screen: a purchase, change or cancellation
            // there must show here without reopening the sheet.
            if !isShown {
                viewModel.loadData()
            }
        }
    }
}
