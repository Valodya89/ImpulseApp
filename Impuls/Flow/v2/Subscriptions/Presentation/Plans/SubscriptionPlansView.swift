//
//  SubscriptionPlansView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 09.06.24.
//

import SwiftUI
import SwiftMessages

struct SubscriptionPlansView: View {

    @ObservedObject private var viewModel: SubscriptionPlansViewModel

    @State var errorMessage: ErrorMessage?

    var config: SwiftMessages.Config {
        var config = SwiftMessages.defaultConfig
        config.presentationStyle = .center
        config.duration = .forever
        config.interactiveHide = false
        config.dimMode = .color(color: UIColor.black.withAlphaComponent(0.3), interactive: false)

        return config
    }

    init(viewModel: SubscriptionPlansViewModel) {
        self.viewModel = viewModel
    }

    private func presentSuccess(_ message: SubscriptionSuccess) {
        let host = UIHostingController(rootView: SubscriptionSuccessView(message: message))
        host.view.backgroundColor = .clear
        SwiftMessages.show(config: config, view: host.view)
    }

    private func presentCancel(_ message: SubscriptionCancel) {
        let host = UIHostingController(rootView: SubscriptionCancelView(message: message))
        host.view.backgroundColor = .clear
        SwiftMessages.show(config: config, view: host.view)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.plans, id: \.id) { plan in
                        SubscriptionPlanItemView(plan: plan, isSelected: plan.id == viewModel.selectedPlan?.id)
                            .allowsHitTesting(viewModel.activePlan?.subscriptionPlanId != plan.id)
                            .opacity(viewModel.activePlan?.subscriptionPlanId == plan.id ? 0.7 : 1)
                            .onTapGesture {
                                viewModel.selectedPlan = plan
                            }
                    }
                    
                    Divider()
                    
                    Text("MOBILE_subscriptions_plans_hint".localized())
                        .font(.system(size: 14, weight: .light))
                        .foregroundColor(.gray8)
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
            }
            
            if let selectedPlan = viewModel.selectedPlan {
                Button(action: {
                    MILoader.show()
                    viewModel.activatePlan(id: selectedPlan.id)
                }, label: {
                    Text(viewModel.activePlan != nil ? "MOBILE_subscriptions_button_change_to_plan".localized().replacingOccurrences(of: "%@", with: selectedPlan.name)
                         : "MOBILE_subscriptions_button_pay_and_subscribe".localized())
                })
                .buttonStyle(MimoButton(isEnabled: viewModel.selectedPlan != nil))
                .padding(.bottom, (viewModel.activePlan?.cancelled ?? false) ? 10 : 0)
            }
            
            if let activePlan = viewModel.activePlan, !activePlan.cancelled {
                Button {
                    presentCancel(SubscriptionCancel(
                        id: activePlan.subscriptionPlanId,
                        keepAction: {
                            SwiftMessages.hide()
                        },
                        cancelAction: {
                            MILoader.show()
                            viewModel.cancelActivePlan()
                        }
                    ))
                } label: {
                    ZStack {
                        Text("MOBILE_subscriptions_button_cancel".localized())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.gray8)
                    }
                    .frame(height: 48)
                    .frame(maxWidth: .infinity)
                    .background(Capsule().stroke(Color.gray8, lineWidth: 1))
                }
                .padding(.bottom, 20)
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("MOBILE_subscriptions_navigation_title".localized())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonTitleHidden()
        .clipped()
        .background(Color.grayBackgroundV2.ignoresSafeArea(edges: .bottom))
        .onAppear {
            viewModel.loadData()
        }
        .onReceive(viewModel.$errorMessage) { error in 
            if let errorMessage = error {
                MILoader.hide()
                self.errorMessage = ErrorMessage(title: "MOBILE__global_attention".localized(), body: errorMessage.localized())
            }
        }
        .onReceive(viewModel.$activated) { activated in
            MILoader.hide()
            if activated {
                presentSuccess(SubscriptionSuccess(
                    name: viewModel.selectedPlan?.name ?? "-",
                    action: {
                        viewModel.loadData()
                        viewModel.activated = false
                        viewModel.selectedPlan = nil
                        SwiftMessages.hide()
                    }
                ))
            }
        }
        .onReceive(viewModel.$canceld) { canceld in
            MILoader.hide()
            if canceld {
                viewModel.loadData()
                viewModel.canceld = false
                viewModel.selectedPlan = nil
                SwiftMessages.hide()
            }
        }
        .swiftMessage(message: $errorMessage)
    }
}

extension View {

  func navigationBarBackButtonTitleHidden() -> some View {
    self.modifier(NavigationBarBackButtonTitleHiddenModifier())
  }
}

struct NavigationBarBackButtonTitleHiddenModifier: ViewModifier {

    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

  @ViewBuilder @MainActor func body(content: Content) -> some View {
    content
      .navigationBarBackButtonHidden(true)
      .navigationBarItems(
        leading: Button(action: { presentationMode.wrappedValue.dismiss() }) {
          Image(systemName: "chevron.left")
            .foregroundColor(.black)
          .imageScale(.large) })
      .contentShape(Rectangle()) // Start of the gesture to dismiss the navigation
      .gesture(
        DragGesture(coordinateSpace: .local)
          .onEnded { value in
            if value.translation.width > .zero
                && value.translation.height > -30
                && value.translation.height < 30 {
                presentationMode.wrappedValue.dismiss()
            }
          }
      )
  }
}
