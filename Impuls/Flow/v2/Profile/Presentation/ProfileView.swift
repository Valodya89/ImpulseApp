//
//  ProfileView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 14.04.24.
//

import SwiftUI
import Kingfisher

struct ProfileView: View {

    private var appVersion: String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return "v \(appVersion ?? "")"
    }

    @ObservedObject var viewModel: ProfileViewModel

    private let navigationController: UINavigationController

    @State var isHaveProfilePicture: Bool = false

    @State private var showActiveTripAlert = false
    @State private var activeAlert: ProfileAlert?
    @State private var showWalletScreen = false
    @State private var showSubscriptionScreen = false

    // A single source of truth for the confirmation alerts. Driving both from
    // one `.alert(item:)` avoids SwiftUI dropping one when multiple
    // `.alert(isPresented:)` modifiers share a view hierarchy.
    private enum ProfileAlert: Identifiable {
        case logout
        case deleteAccount

        var id: Int { hashValue }
    }

    init(viewModel: ProfileViewModel, navigationController: UINavigationController) {
        self.viewModel = viewModel
        self.navigationController = navigationController
    }

    var body: some View {
        VStack(spacing: 0) {
            // Edit bar. Sits in the top safe area like the old 32pt strip did,
            // but with a real 44pt target.
            HStack {
                Spacer()

                Button {
                    ProfileRouter(navigationController: navigationController).showEditProfileScreen(user: viewModel.user)
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.appSecondaryLabel)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 44)
            .alert(isPresented: $showActiveTripAlert) {
                Alert(
                    title: Text("MOBILE_you_have_active_trip".localized()),
                    dismissButton: .cancel(Text("MOBILE_global_ok".localized(fallback: "OK"))))
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    identityHeader

                    MimoSectionLabel(title: "MOBILE_profile_page_wallet_payment".localized())
                        .padding(.top, 10)

                    ProfilePaymentView(
                        currency: viewModel.currency,
                        balance: viewModel.balance,
                        isBalanceNegative: viewModel.isBalanceNegative,
                        replanishAction: {
                            showWalletScreen = true
                        }
                    )

                    if let package = viewModel.package {
                        ProfilePackageView(
                            title: package.name.uppercased(),
                            startDate: DateFormatter.fullDateFormatter.string(from: package.startDate),
                            endDate: DateFormatter.fullDateFormatter.string(from: package.endDate)
                        )
                        .onTapGesture {
                            ProfileRouter(navigationController: navigationController).showPackagesScreen()
                        }
                    }

                    // Subscriptions are offered per country through Remote Config
                    // (subscription_enabled_countries); unlisted markets never see
                    // the row. The plan catalogue itself is country/locale-driven
                    // by the backend (accounts GET /api/subscription-plan/list).
                    if SubscriptionAvailability.isEnabledForCurrentCountry {
                        MimoListRow(
                            icon: Image(ProfilePaymentRows.subscriptions.icon),
                            title: ProfilePaymentRows.subscriptions.name,
                            subtitle: subscriptionSubtitle
                        )
                        .mimoCard()
                        .onTapGesture {
                            VibrateManager.vibrate()
                            showSubscriptionScreen = true
                        }
                    }

                    MimoSectionLabel(title: "MOBILE_profile_support_settings".localized())
                        .padding(.top, 10)

                    VStack(spacing: 0) {
                        ForEach(ProfileSettingsRows.allCases) { item in
                            MimoListRow(
                                icon: Image(item.icon),
                                title: item.name,
                                tone: item.isDestuctive ? .destructive : .standard
                            ) {
                                if item.isDestuctive {
                                    EmptyView()
                                } else {
                                    MimoChevron()
                                }
                            }
                            .onTapGesture {
                                settingsAction(for: item)
                            }

                            if item != ProfileSettingsRows.allCases.last {
                                MimoRowDivider()
                            }
                        }
                    }
                    .mimoCard()

                    Text(appVersion)
                        .font(.robotoRegular12)
                        .foregroundColor(.gray5)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 100)
                // Both logout and delete-account confirmations are driven by a
                // single `.alert(item:)` so they can't clobber each other.
                .alert(item: $activeAlert) { alert in
                    switch alert {
                    case .logout:
                        return Alert(title: Text("MOBILE__profile_log_out_message".localized()),
                                     primaryButton: .destructive(
                                        Text("MOBILE__confirmation_yes".localized()),
                                        action: {
                                            MILoader.show()
                                            viewModel.logout()
                                        }),
                                     secondaryButton: .cancel(Text("MOBILE__confirmation_no".localized()))
                        )
                    case .deleteAccount:
                        return Alert(title: Text("MOBILE_profice_deleete_confirm".localized()),
                                     primaryButton: .destructive(
                                        Text("MOBILE__confirmation_yes".localized()),
                                        action: {
                                            MILoader.show()
                                            viewModel.deleteAccount()
                                        }),
                                     secondaryButton: .cancel(Text("MOBILE__confirmation_no".localized()))
                        )
                    }
                }
                .mimoRefreshable { done in
                    viewModel.reload(completion: done)
                }
            }
        }
        .background(Color.appSecondaryBackground.ignoresSafeArea(edges: .all))
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $showWalletScreen, content: {
            WalletView(viewModel: MimoWalletViewModel(worker: Resolver.resolve()))
        })
        .sheet(isPresented: $showSubscriptionScreen, onDismiss: {
            // A purchase, change or cancellation in the sheet changes
            // `activePlan` on the user (and the wallet balance): refresh the row.
            viewModel.loadData()
        }, content: {
            SubscriptionView(
                viewModel: SubscriptionInfoViewModel(
                    worker: Resolver.resolve()
                )
            )
        })
        .onReceive(viewModel.$isSuccessfullyLogout) { isSuccessfullyLogout in
            MILoader.hide()
            if let isSuccessfullyLogout, isSuccessfullyLogout {
                BaseRouter.shared.showSplashView()
            }
        }
    }

    /// Supporting line of the Subscriptions row: the day the active plan runs
    /// out, flagged when its renewal was cancelled. The active plan comes from
    /// GET /api/user `activePlan` (accounts docs/mobile-api.md); nil without one.
    private var subscriptionSubtitle: String? {
        guard let activePlan = viewModel.user?.activePlan else { return nil }

        let until = DateFormatter.dayMonthYearFormatter.string(
            from: Date(timeIntervalSince1970: TimeInterval(activePlan.activeUntil / 1000))
        )
        let key = activePlan.cancelled
            ? "MOBILE_subscriptions_row_cancelled_until"
            : "MOBILE_subscriptions_row_active_until"

        return key.localized().replacingOccurrences(of: "%@", with: until)
    }

    /// Avatar with the brand ring, name and phone. Left-aligned so it reads
    /// as the top of a list, not a centred hero.
    private var identityHeader: some View {
        HStack(spacing: 14) {
            Group {
                if viewModel.avatarURL != nil {
                    KFImage(viewModel.avatarURL)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "person")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(.gray5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.appFill)
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.brandYellow, lineWidth: 2))

            VStack(alignment: .leading, spacing: 3) {
                Text(viewModel.name)
                    .font(.robotoBold20)
                    .foregroundColor(.appLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(viewModel.phoneNumber)
                    .font(.robotoRegular14)
                    .foregroundColor(.gray5)
            }

            Spacer(minLength: 0)
        }
    }

    private func settingsAction(for type: ProfileSettingsRows) {
        VibrateManager.vibrate()

        let router = ProfileRouter(navigationController: navigationController)

        switch type {
        case .history:
            router.showHistoryScreen()
//        case .rate:
//            router.showRateScreen()
        case .support:
            router.showSupportScreen()
        case .howToUse:
            router.showHowToUseScreen()
        case .settings:
            router.showSettingsScreen()
        case .partnership:
            router.showPartnershipScreen()
        case .privacy:
            router.showPrivacyPolicyScreen()
        case .terms:
            router.showAgreementScreen()
        case .logOut:
            if UserManager.share.isHaveBikeTrip || UserManager.share.isHaveScooterTrip {
                showActiveTripAlert = true
            } else {
                activeAlert = .logout
            }
        case .deleteAccount:
            if UserManager.share.isHaveBikeTrip || UserManager.share.isHaveScooterTrip {
                showActiveTripAlert = true
            } else {
                activeAlert = .deleteAccount
            }
        }
    }
}
