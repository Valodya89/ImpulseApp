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
            HStack {
                Spacer()
                
                Button {
                    ProfileRouter(navigationController: navigationController).showEditProfileScreen(user: viewModel.user)
                } label: {
                    Image(systemName: "pencil.line")
                        .resizable()
                        .foregroundColor(Color.black075)
                }
                .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 20)
            .frame(height: 32)
            .background(Color.profileBackground)
            .alert(isPresented: $showActiveTripAlert) {
                Alert(
                    title: Text("MOBILE_you_have_active_trip".localized()).foregroundColor(.mimoDarkGray),
                    dismissButton: .cancel(Text("Ok").foregroundColor(.black)))
            }
            
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .center, spacing: 0) {
                    VStack(spacing: 0) {
                        if viewModel.avatarURL != nil {
                            KFImage(viewModel.avatarURL)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 106, height: 106)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.black075, lineWidth: 1)
                                )
                        } else {
                            ZStack {
                                Image(systemName: "person")
                                    .resizable()
                                    .font(.title.weight(.ultraLight))
                                    .frame(width: 58, height: 58)
                                    .foregroundColor(.black075)
                            }
                            .frame(width: 106, height: 106)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.black075, lineWidth: 1.5)
                            )
                        }
                        
                        Text(viewModel.name)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.top, 20)
                        
                        Text(viewModel.phoneNumber)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.black05)
                            .padding(.top, 6)
                    }
//
//                    HStack {
//                        ZStack {
//                            VStack {
//                                HStack {
//                                    Image("profile_distance")
//                                    
//                                    Text("\(viewModel.distance) \("MOBILE_global_km".localized())")
//                                }
//                                
//                                Text("MOBILE_global_distance".localized())
//                                    .font(.system(size: 15, weight: .light))
//                                    .foregroundColor(.black05)
//                            }
//                        }
//                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
//                        
//                        ZStack {
//                            VStack {
//                                HStack {
//                                    Image("profile_ccal")
//                                    
//                                    Text("\(viewModel.calories) \("MOBILE_global_ccal".localized())")
//                                }
//                                
//                                Text("MOBILE_global_calories".localized())
//                                    .font(.system(size: 15, weight: .light))
//                                    .foregroundColor(.black05)
//                            }
//                        }
//                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
//                        
//                        ZStack {
//                            VStack {
//                                HStack {
//                                    Image("profile_carbon")
//                                    
//                                    Text(viewModel.carbon)
//                                }
//                                
//                                Text("MOBILE_global_carbon".localized())
//                                    .font(.system(size: 15, weight: .light))
//                                    .foregroundColor(.black05)
//                            }
//                        }
//                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
//                    }
//                    .frame(height: 44)
//                    .padding(.top, 25)
//                    .padding(.horizontal, 10)

//                    if !viewModel.isEmailVerified {
//                        ProfileRowView(icon: "profile_verify_mail", title: "Verify your email")
//                            .clipShape(RoundedRectangle(cornerRadius: 8))
//                            .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
//                            .padding(.top, 20)
//                            .onTapGesture {
//                                if let email = viewModel.user?.email {
//                                    ProfileRouter(navigationController: navigationController).showEmailVerifyScreen(email: email)
//                                } else {
//                                    ProfileRouter(navigationController: navigationController).showEditProfileScreen(user: viewModel.user)
//                                }
//                            }
//                    }
                    
//                    HeaderTitleView(title: "MOBILE_profile_page_wallet_payment".localized())
//                        .padding(.top, 18)
//                    
//                    ProfilePaymentView(
//                        freeMinutes: viewModel.freeMinutes,
//                        currency: viewModel.currency,
//                        balance: viewModel.balance,
//                        isBalanceNegative: viewModel.isBalanceNegative,
//                        replanishAction: {
//                            showWalletScreen = true
//                        }
//                    )
//                    .padding(.top, 6)
//                    
//                    if let package = viewModel.package {
//                        HStack {
//                            ProfilePackageView(
//                                title: package.name.uppercased(),
//                                startDate: DateFormatter.fullDateFormatter.string(from: package.startDate),
//                                endDate: DateFormatter.fullDateFormatter.string(from: package.endDate)
//                            )
//                        }
//                        .padding(.top, 8)
//                        .onTapGesture {
//                            ProfileRouter(navigationController: navigationController).showPackagesScreen()
//                        }
//                    }
//                    
//                    ZStack {
//                        VStack(spacing: 0) {
//                            ForEach([ProfilePaymentRows.subscriptions]) { item in
//                                ProfileRowView(icon: item.icon, title: item.name)
//                                    .onTapGesture {
//                                        showSubscriptionScreen = true
//                                    }
//                                
//                                if item != ProfilePaymentRows.allCases.last {
//                                    Divider()
//                                }
//                            }
//                        }
//                    }
//                    .background(Color.white)
//                    .clipShape(RoundedRectangle(cornerRadius: 8))
//                    .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
//                    .padding(.top, 12)
                    
                    HeaderTitleView(title: "MOBILE_profile_support_settings".localized().uppercased())
                        .padding(.top, 18)
                    
                    ZStack {
                        VStack(spacing: 0) {
                            ForEach(ProfileSettingsRows.allCases) { item in
                                ProfileRowView(icon: item.icon, title: item.name, type: item.isDestuctive ? .destructive : .standard, isArrowVisible: !item.isDestuctive)
                                    .onTapGesture {
                                        settingsAction(for: item)
                                    }
                                
                                if item != ProfileSettingsRows.allCases.last {
                                    Divider()
                                }
                            }
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.1), radius: 8, y: 2)
                    .padding(.top, 6)
                    
                    Text(appVersion)
                        .font(.subheadline)
                        .foregroundColor(.black05)
                        .padding(.top, 8)
                    
                    Spacer()
                }
                .frame(alignment: .center)
                .padding(.top, 3)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                // Both logout and delete-account confirmations are driven by a
                // single `.alert(item:)` so they can't clobber each other.
                .alert(item: $activeAlert) { alert in
                    switch alert {
                    case .logout:
                        return Alert(title: Text("MOBILE__profile_log_out_message".localized()).foregroundColor(.mimoDarkGray),
                                     primaryButton: .destructive(
                                        Text("MOBILE__confirmation_yes".localized()),
                                        action: {
                                            MILoader.show()
                                            viewModel.logout()
                                        }),
                                     secondaryButton: .cancel(Text("MOBILE__confirmation_no".localized()).foregroundColor(.black))
                        )
                    case .deleteAccount:
                        return Alert(title: Text("MOBILE_profice_deleete_confirm".localized()).foregroundColor(.mimoDarkGray),
                                     primaryButton: .destructive(
                                        Text("MOBILE__confirmation_yes".localized()),
                                        action: {
                                            MILoader.show()
                                            viewModel.deleteAccount()
                                        }),
                                     secondaryButton: .cancel(Text("MOBILE__confirmation_no".localized()).foregroundColor(.black))
                        )
                    }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .background(Color.profileBackground.ignoresSafeArea(edges: .all))
        .onAppear {
            viewModel.loadData()
        }
        .sheet(isPresented: $showWalletScreen, content: {
            WalletView(viewModel: MimoWalletViewModel(worker: Resolver.resolve()))
        })
        .sheet(isPresented: $showSubscriptionScreen, content: {
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
//            if UserManager.share.isHaveBikeTrip || UserManager.share.isHaveScooterTrip {
//                showActiveTripAlert = true
//            } else {
                activeAlert = .logout
//            }
        case .deleteAccount:
//            if UserManager.share.isHaveBikeTrip || UserManager.share.isHaveScooterTrip {
//                showActiveTripAlert = true
//            } else {
                activeAlert = .deleteAccount
//            }
        }
    }
}
