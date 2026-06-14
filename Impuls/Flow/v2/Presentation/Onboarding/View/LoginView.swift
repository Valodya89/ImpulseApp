//
//  LoginView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.09.23.
//

import SwiftUI
import SafariServices

struct LoginView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @ObservedObject var viewModel: LoginViewModel
    
    @State var isCountryCodePresented: Bool = false
    @State var countryCode: CountryCodeResponse? = ApplicationSettings.shared.countryCodes.first
    @State private var timeRemaining = 60
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            if viewModel.isAccountFullCompleted {
                HomeView(
                    homeViewModel: MimoHomeViewModel(
                        worker: Resolver.resolve(),
                        locationManager: Resolver.resolve(),
                        messageServicce: Resolver.resolve(),
                        activeTrips: viewModel.activeTrips
                    )
                ).ignoresSafeArea()
            } else {
                loginRootView
            }
            
            NavigationLink(
                destination: EmailVerificationView(
                    email: viewModel.email,
                    viewModel: EmailVerificationViewModel(worker: Resolver.resolve(),
                                                          activeTrips: viewModel.activeTrips), isActive: $viewModel.emailVerificationCodeSent),
                isActive: Binding<Bool>(get: { viewModel.emailVerificationCodeSent ?? false }, set: { viewModel.emailVerificationCodeSent = $0 })) {
                    Text("")
                }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarHidden(true)
        .navigationViewStyle(.stack)
        .onReceive(viewModel.$errorMessage) { errorMessage in
            if let errorMessage {
                let alert = MiAlertView()
                _ = alert.showError("MOBILE__global_attention".localized().localized(),
                                    subTitle: errorMessage.localized(),
                                    closeButtonTitle: "OK".localized(),
                                    animationStyle: .topToBottom)
                alert.dismissBlock = {
                    viewModel.errorMessage = nil
                }
            }
        }
    }
    
    @ViewBuilder
    private var loginRootView: some View {
        ZStack {
            Color.grayBackground.edgesIgnoringSafeArea(.all)
            
            VStack {
                ZStack {
                    HStack {
                        Button {
                            if !viewModel.previousStep() {
                                presentationMode.wrappedValue.dismiss()
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .imageScale(.large)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black075)
                        }
                        
                        Spacer()
                    }
                    
                    Text(viewModel.loginStep.title)
                        .font(.robotoMedium20)
                        .foregroundColor(.black08)
                }
                .frame(height: 44)
                .padding(.horizontal, 20)
                
                HStack(spacing: 0) {
                    
                    switch viewModel.loginStep {
                    case .phoneNumber:
                        Capsule()
                            .fill(Color.yellow)
                            .frame(maxWidth: .infinity)
                        
                        Spacer()
                            .frame(maxWidth: .infinity)
                        
                        Spacer()
                            .frame(maxWidth: .infinity)
                    case .otp:
                        Capsule()
                            .fill(Color.yellow)
                            .frame(maxWidth: .infinity)
                        
                        Capsule()
                            .fill(Color.yellow)
                            .frame(maxWidth: .infinity)
                            .padding(.leading, -5)
                        
                        Spacer()
                            .frame(maxWidth: .infinity)
                    case .personalInfo:
                        Capsule()
                            .fill(Color.yellow)
                            .frame(maxWidth: .infinity)
                        
                        Capsule()
                            .fill(Color.yellow)
                            .frame(maxWidth: .infinity)
                            .padding(.leading, -5)
                        
                        Capsule()
                            .fill(Color.yellow)
                            .frame(maxWidth: .infinity)
                            .padding(.leading, -5)
                        
                        Spacer()
                            .frame(maxWidth: .infinity)
                    case .preferedServices:
                        Capsule()
                            .fill(Color.yellow)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 7, alignment: .leading)
                .padding(.horizontal, 20)
                
                ZStack {
                    switch viewModel.loginStep {
                    case .phoneNumber:
                        phoneNumberView
                    case .otp:
                        otpView
                    case .personalInfo:
                        personalInfoView
                            .transition(.slide)
                    case .preferedServices:
                        availableServicesView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 30)
                
                Spacer()
                
                Button {
                    switch viewModel.loginStep {
                    case .phoneNumber:
                        MILoader.show()
                        viewModel.signIn()
                    case .otp:
                        viewModel.verifyDevice()
                    case .personalInfo:
                        viewModel.updatePersonalInfo()
                    case .preferedServices:
                        viewModel.updatePreferedServices()
                    }
                } label: {
                    Text(viewModel.loginStep.buttonTitle)
                }
                .buttonStyle(MimoButton(isEnabled: viewModel.isValid()))
                .padding(.bottom, 20)
                .disabled(!viewModel.isValid())
            }
        }
    }
    
    @ViewBuilder
    private var phoneNumberView: some View {
        VStack(spacing: 24) {
            ZStack {
                Color.white
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("MOBILE_sign_in_phone_number".localized().replacingOccurrences(of: "\n", with: ""))
                            .font(.robotoLight13)
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 0) {
                        HStack(spacing: 8) {
                            Image(viewModel.selectedCountry?.flag ?? "")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .fixedSize()
                            
                            Image(systemName: "chevron.down")
                                .resizable()
                                .foregroundColor(.black05)
                                .frame(width: 12, height: 7)
                                .fixedSize()
                        }
                        .onTapGesture {
                            isCountryCodePresented = true
                        }
                        
                        Text(viewModel.selectedCountry?.dial_code ?? "")
                            .font(.robotoBold17)
                            .foregroundColor(.black075)
                            .padding(.leading, 10)
                        
                        TextField(viewModel.exampleNumber ?? "", text: $viewModel.phoneNumber)
                            .font(.robotoRegular17)
                            .foregroundColor(.black075)
                            .padding(.leading, 5)
                            .keyboardType(.numberPad)
                        
                        Spacer()
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 15)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.black, lineWidth: 0.5)
            )
            .frame(height: 63)
            .frame(maxWidth: .infinity)
            
            HStack {
                Button {
                    viewModel.isTermsAccepted.toggle()
                } label: {
                    Image("ic_checkBox_\(viewModel.isTermsAccepted ? "filled" : "empty")")
                        .resizable()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.black05)
                }
                
                HStack(spacing: 0) {
                    Text("MOBILE_agree_Mimo_Agreement ".localized())
                        .font(.robotoLight13)
                        .foregroundColor(.black)
                        .underline()
                        .onTapGesture {
                            let language = viewModel.getLanguage()
                            let urlString = Constant.URLString.terms.replacingOccurrences(of: "<language>", with: language)
                            if let url = URL(string: urlString) {
                                let safariVC = SFSafariViewController(url: url)
                                safariVC.dismissButtonStyle = .close
                                safariVC.preferredControlTintColor = .mimoDarkGray
                                UIApplication.shared.topMostViewController()?.present(safariVC, animated: true)
                            }
                            
                            viewModel.isTermsAccepted = true
                        }
                }
                
                Spacer()
            }
            .padding(.horizontal, 15)
            
            HStack {
                Button {
                    viewModel.isPrivacyPoliceAccepted.toggle()
                } label: {
                    Image("ic_checkBox_\(viewModel.isPrivacyPoliceAccepted ? "filled" : "empty")")
                        .resizable()
                        .frame(width: 18, height: 18)
                        .foregroundColor(.black05)
                }
                
                HStack(spacing: 0) {
                    Text("MOBILE_agree_Mimo_Privacy_Policy".localized())
                        .font(.robotoLight13)
                        .foregroundColor(.black)
                        .underline()
                        .onTapGesture {
                            let language = viewModel.getLanguage()
                            let urlString = Constant.URLString.privacyPolicy.replacingOccurrences(of: "<language>", with: language)
                            if let url = URL(string: urlString) {
                                let safariVC = SFSafariViewController(url: url)
                                safariVC.dismissButtonStyle = .close
                                safariVC.preferredControlTintColor = .mimoDarkGray
                                UIApplication.shared.topMostViewController()?.present(safariVC, animated: true)
                            }
                            
                            viewModel.isPrivacyPoliceAccepted = true
                        }
                }
                
                Spacer()
            }
            .padding(.horizontal, 15)
            
//            VStack(spacing: 12) {
//                Text("\("MOBILE_login_agreement_transferred_to_child".localized())\n\n\("MOBILE_login_agreement_riding_more_than_one".localized())\n\n\("MOBILE_login_agreement_scooter_transfer_to_others".localized())")
//                    .lineLimit(nil)
//                    .font(.robotoLight14)
//                    .foregroundColor(Color.black075)
//                    .padding()
//                
//                HStack {
//                    Text("MOBILE_good_trip".localized())
//                        .font(.robotoSemibold16)
//                        .foregroundColor(.black)
//                    
//                    Image("Mimo_scooter_New")
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                        .frame(width: 30, height: 34)
//                }
//                .padding(.bottom, 20)
//            }
//            .background(Color(red: 0.98, green: 0.52, blue: 0.52).opacity(0.1))
//            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .sheet(isPresented: $isCountryCodePresented) {
            CountryCodeView(code: $viewModel.selectedCountry)
        }
        .onReceive(viewModel.$isDeviceVerifid) { isDeviceVerified in
            guard isDeviceVerified != nil else { return }

            MILoader.hide()
        }
    }
    
    @ViewBuilder
    private var otpView: some View {
        VStack(spacing: 15) {
            HStack(spacing: 3) {
                Text("MOBILE_sign_in_phone_number_which_received_code".localized().replacingOccurrences(of: " [phone num]", with: ""))
                    .font(.robotoRegular17)
                    .foregroundColor(.black025)
                Text(viewModel.formattedPhoneNumber)
                    .font(.robotoRegular17)
                    .foregroundColor(.black05)
            }
            .padding(.top, 10)
            
            OTPView(otpCode: $viewModel.otpCode, isValidCode: viewModel.isValidOTP)
                .frame(height: 64)
                .padding(.top, 40)
                .padding(.horizontal, 50)
                .onReceive(viewModel.$otpCode) { otpCode in
                    guard otpCode != nil else { return }
                    viewModel.isValidOTP = nil
                }
            
            if let isValidOTP = viewModel.isValidOTP, let otpCode = viewModel.otpCode, !isValidOTP, !otpCode.isEmpty {
                Text("ACCOUNTS__wrong_verification_code".localized())
                    .font(.robotoRegular15)
                    .foregroundColor(.mimoRed500)
            }
            
            if timeRemaining > 0 {
                HStack(spacing: 5) {
                    Text("MOBILE_sign_in_\(viewModel.otpMethod.rawValue)_duration".localized())
                        .foregroundColor(.black05)
                    Text("\(timeRemaining.timeString())")
                        .foregroundColor(.mimoRed500)
                }
                .font(.robotoRegular17)
                .onReceive(timer, perform: { _ in
                    if self.timeRemaining > 0 {
                        self.timeRemaining -= 1
                    } else {
                        self.timer.upstream.connect().cancel()
                    }
                })
            }
            
            Text(viewModel.otpMethod == .CALL ? ("\("MOBILE_fill_last_four_digit".localized())\n+7 (***) ***-12-34") : "MOBILE_sign_in_SMS_hint".localized())
                .lineLimit(nil)
                .font(.robotoRegular17)
                .foregroundColor(.black025)
                .multilineTextAlignment(.center)
            
            Spacer()
            
            if timeRemaining <= 0 {
                HStack {
                    Text("MOBILE_sign_in_didn't_get_the_code".localized())
                        .font(.robotoRegular17)
                        .foregroundColor(.black025)
                    
                    Spacer()
                    
                    Button {
                        timeRemaining = 60
                        viewModel.signIn()
                    } label: {
                        Text("MOBILE_sign_in_request_again".localized())
                            .underline()
                            .font(.robotoRegular17)
                            .foregroundColor(.black)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .onReceive(viewModel.$isDeviceVerifid) { isDeviceVerifid in
            guard isDeviceVerifid != nil else { return }

            MILoader.hide()
        }
    }
    
    @ViewBuilder
    private var personalInfoView: some View {
        ScrollView(.vertical) {
            VStack(spacing: 15) {
                MimoTextField(title: "MOBILE_registartion_first_name".localized(), placeholder: "MOBILE_registartion_first_name".localized(), text: $viewModel.name)
                    .frame(height: 63)
                
                MimoTextField(title: "MOBILE_registartion_last_name".localized(), placeholder: "MOBILE_registartion_last_name".localized(), text: $viewModel.surname)
                    .frame(height: 63)
                
                MimoDatePickerTextField(title: "MOBILE_registartion_dob".localized(), placeholder: "MOBILE_registartion_dob".localized(), date: $viewModel.bithday)
                    .frame(height: 63)
                
                MimoWheelPickerTextField(title: "MOBILE_registartion_sex".localized(), placeholder: "MOBILE_registartion_sex".localized(), items: LoginViewModel.Gender.allCases.map({ $0.title }), selectedItem: $viewModel.gender)
                    .frame(height: 63)
                
                HStack(alignment: .top) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.black025)
                    
                    Text("MOBILE_sign_in_personal_info_hint".localized())
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.black08)
                        .font(.robotoLight14)
                }
            }
            .padding(1)
        }
    }
    
    @ViewBuilder
    private var availableServicesView: some View {
        ScrollView(.vertical) {
            VStack(spacing: 15) {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 20),
                    GridItem(.flexible(), spacing: 20)
                 ], spacing: 20) {
                    ForEach(viewModel.availableProducts, id: \.service) { product in
                        ProductCardView(product: product)
                            .onTapGesture {
                                viewModel.toggleSelection(for: product)
                            }
                    }
                }
                
                HStack(alignment: .top) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.black025)
                    
                    Text("MOBILE_sign_in_onboarding_service_description".localized())
                        .lineLimit(nil)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(.black08)
                        .font(.robotoLight14)
                }
            }
            .padding(1)
        }
    }
    
    @ViewBuilder
    private var verifyEmailView: some View {
        VStack(spacing: 16) {
            MimoTextField(title: "MOBILE_registartion_email".localized(), placeholder: "MOBILE_registartion_email".localized(), text: $viewModel.email)
                .frame(height: 63)
            
            HStack(alignment: .top) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.black025)
                
                Text("MOBILE_sign_in_verify_email_hint_1".localized())
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.black08)
                    .font(.robotoLight14)
                
                Spacer()
            }
            
            HStack(alignment: .top) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.black025)
                
                Text("MOBILE_sign_in_verify_email_hint_2".localized())
                    .lineLimit(nil)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.black08)
                    .font(.robotoLight14)
                
                Spacer()
            }
        }
        .onReceive(viewModel.$emailVerificationCodeSent) { isSent in
            guard isSent != nil else { return }
            
            MILoader.hide()
        }
    }
}
