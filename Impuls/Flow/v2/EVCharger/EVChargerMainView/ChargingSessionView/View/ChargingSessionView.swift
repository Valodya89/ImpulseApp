//
//  ChargingSessionView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 06.04.25.
//

import SwiftUI

struct ChargingSessionView: View {
    @Environment(\.openURL) var openURL

    @ObservedObject var viewModel: ChargingSessionViewModel
    @State private var errorMessage: ErrorMessage?

    var body: some View {
        Group {
            if viewModel.sessions.isEmpty {
                if viewModel.isInitialLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    Text("EV_CHARGER_no_active_chargings".localized())
                        .font(.robotoMedium16)
                        .foregroundColor(Color.init(hex: "#666666"))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                VStack(spacing: 12) {
                    TabView(selection: $viewModel.currentIndex) {
                        ForEach(Array(viewModel.sessions.enumerated()), id: \.element.id) { index, session in
                            ChargingSessionCard(session: session)
                                .tag(index)
                                .padding(.horizontal, 16)
                                .padding(.top)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: viewModel.sessions.count > 1 ? .always : .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))

                    if let current = viewModel.currentSession {
                        SlideToFinishForSession(session: current) {
                            viewModel.completeSlider(for: current.id)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    }
                }
            }
        }
        .mapNavigationView(
            value: 0.00,
            subTitle: "MOBILE_mimo_balance".localized(),
            backAction: { viewModel.back() },
            plusAction: { viewModel.wallet() },
            bellAction: { viewModel.notifications() }
        )
        .background(Color.init(hex: "#F2F2F2").ignoresSafeArea())
        .onAppear {
            viewModel.onAppear()
        }
        .onDisappear {
            viewModel.onDisappear()
        }
        .onReceive(viewModel.$errorMessage) { error in
            if let errorMessage = error {
                MILoader.hide()
                self.errorMessage = ErrorMessage(
                    title: "MOBILE__global_attention".localized(),
                    body: errorMessage.localized()
                )
            }
        }
        .swiftMessage(message: $errorMessage)
        .overlay {
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()

                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
    }
}

private struct SlideToFinishForSession: View {
    @ObservedObject var session: ChargingSessionItem
    let onComplete: () -> Void

    var body: some View {
        SlideToFinishView(isLoading: Binding(
            get: { session.isFinishing },
            set: { _ in }
        )) {
            onComplete()
        }
    }
}

private struct ChargingSessionCard: View {
    @ObservedObject var session: ChargingSessionItem
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            VStack {
                HStack(spacing: 12) {
                    Image(.contactSmsCircle)
                        .frame(width: 16, height: 13)
                        .background(Color.white)
                    VStack(alignment: .leading, spacing: 5) {
                        Text("MOBILE_mimo_support".localized())
                    }

                    Spacer()

                    Image(.arrowRight)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .background(Color.init(hex: "#F2F2F2"))
                .cornerRadius(12, corners: .allCorners)
                .onTapGesture {
                    if let telegramURL = URL(string: "tg://resolve?domain=MimoReview") {
                        openURL(telegramURL)
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .center, spacing: 5) {
                        Text("EV_CHARGER_connector".localized())
                            .font(.robotoRegular16)

                        Text(session.connectorId)
                            .foregroundColor(Color.init(hex: "#666666"))
                            .font(.robotoSemibold40)
                    }

                    Spacer()

                    VStack(alignment: .center, spacing: 5) {
                        Text(session.connectorType)
                        Image(session.connectorTypeImageName)
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .background(Color.init(hex: "#F2F2F2"))
                .cornerRadius(12, corners: .allCorners)

                HStack(alignment: .top, spacing: 16) {
                    ChargingView(percentage: session.percent)

                    VStack(spacing: 16) {
                        Group {
                            VStack(spacing: 8) {
                                Text("EV_CHARGER_price".localized())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(Color.init(hex: "#666666"))
                                    .font(.robotoRegular16)
                                Text(session.priceKWt)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.evbrandCyan80)
                                    .font(.robotoMedium16)
                            }

                            VStack(spacing: 8) {
                                Text("EV_CHARGER_charger_speed".localized())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(Color.init(hex: "#666666"))
                                    .font(.robotoRegular16)
                                Text(session.speed)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.evbrandCyan80)
                                    .font(.robotoMedium16)
                            }

                            VStack(spacing: 8) {
                                Text("EV_CHARGER_charged".localized())
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(Color.init(hex: "#666666"))
                                    .font(.robotoRegular16)
                                Text(session.kwtsCharged)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .foregroundColor(.evbrandCyan80)
                                    .font(.robotoMedium16)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .background(Color.init(hex: "#F2F2F2"))
                        .cornerRadius(12, corners: .allCorners)
                    }
                    .frame(maxHeight: .infinity)
                }

                HStack {
                    Text("EV_CHARGER_session_total".localized())
                        .foregroundColor(Color.init(hex: "#666666"))
                        .font(.robotoRegular16)

                    Spacer()

                    Text(session.totalPrice)
                        .foregroundColor(.evbrandCyan80)
                        .font(.robotoMedium16)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 18)
                .background(Color.init(hex: "#F2F2F2"))
                .cornerRadius(12, corners: .allCorners)

                HStack() {
                    Image(.evChargingTypeSuperFastCyan)
                        .foregroundColor(.evbrandCyan80)

                    Text("\(session.chargingType) " + "EV_CHARGER_connector_state_charging".localized())
                        .font(.robotoMedium16)
                        .foregroundColor(.evbrandCyan80)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
    }
}
