//
//  EmailVerificationView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 03.10.23.
//

import SwiftUI

struct EmailVerificationView: View {
    
    @ObservedObject private var viewModel: EmailVerificationViewModel
    @Binding var isActive: Bool?
    @State var isMailAppNotInstalled: Bool = false
    @State var isMailSheetPresented: Bool = false
    public var email: String
    
    init(email: String, viewModel: EmailVerificationViewModel, isActive: Binding<Bool?>) {
        self.email = email
        self.viewModel = viewModel
        self._isActive = isActive
    }
    
    var body: some View {
        if viewModel.emailVerified {
            successView
        } else {
            verificationView
        }
    }
    
    @ViewBuilder
    private var verificationView: some View {
        VStack {
            ZStack {
                HStack {
                    Button {
                        isActive = false
                    } label: {
                        Image(systemName: "chevron.left")
                            .imageScale(.large)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black075)
                    }
                    
                    Spacer()
                }
                
                Text("")
                    .font(.robotoMedium20)
                    .foregroundColor(.black08)
            }
            .frame(height: 44)
            .padding(.horizontal, 20)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 30) {
                    ZStack {
                        Color(UIColor.mimoYellow500)
                        
                        Image(systemName: "envelope")
                            .resizable()
                            .foregroundColor(.black)
                            .font(Font.title.weight(.light))
                            .frame(width: 84, height: 64)
                    }
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    
                    Text("MOBILE_verify_please".localized())
                        .font(.robotoBold24)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 8) {
                        Text("MOBILE_verify_sent_email".localized())
                            .font(.robotoRegular16)
                            .foregroundColor(.black05)
                        
                        Text(email)
                            .font(.robotoBold16)
                            .accentColor(.black)
                            .foregroundColor(.black)
                            .disabled(true)
                    }
                    
                    VStack(spacing: 4) {
                        Text("Please click on the link provided in the email to finalize your signup. In case you cannot find the email, kindly check your")
                            .lineLimit(nil)
                            .multilineTextAlignment(.center)
                            .font(.robotoRegular16)
                            .foregroundColor(.black05)
                        
                        Text("spam folder")
                            .font(.robotoBold16)
                            .foregroundColor(.black)
                    }
                }
                .padding(.top, 60)
                .padding(.horizontal, 38)
            }
            
            Button {
                isMailSheetPresented = true
            } label: {
                Text("MOBILE_verify_successful_alert_bottom_text".localized())
            }
            .buttonStyle(MimoButton())
            .actionSheet(isPresented: $isMailSheetPresented, content: {
                ActionSheet(title: Text(""), buttons: [
                    .default(Text("Apple mail"), action: {
                        open(mailType: .appleMail)
                    }),
                    .default(Text("Gmail"), action: {
                        open(mailType: .gmail)
                    }),
                    .default(Text("Microsoft Outlook"), action: {
                        open(mailType: .outlook)
                    }),
                    .cancel()
                ])
            })
            
            Button {
                viewModel.resendCode()
            } label: {
                Text("MOBILE_verify_resend_button".localized())
                    .foregroundColor(.black)
                    .font(.robotoMedium15)
                    .underline()
            }
            .frame(height: 48)
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
        .onReceive(NotificationCenter.default.publisher(for: Constant.Notifications.emailVerificationCode)) { data in
            if let code = data.object as? String {
                viewModel.verifyEmail(code: code)
            }
        }
        .alert(isPresented: $isMailAppNotInstalled) {
            Alert(title: Text("This app is not installed"))
        }
    }
    
    @ViewBuilder
    private var successView: some View {
        VStack {
            ZStack {
                HStack {
                    Button {
                        
                    } label: {
                        Image(systemName: "chevron.left")
                            .imageScale(.large)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.black075)
                    }
                    
                    Spacer()
                }
                
                Text("")
                    .font(.robotoMedium20)
                    .foregroundColor(.black08)
            }
            .frame(height: 44)
            .padding(.horizontal, 20)
            .opacity(0)
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 30) {
                    ZStack {
                        Color(UIColor.mimoYellow500)
                        
                        Image(systemName: "envelope")
                            .resizable()
                            .foregroundColor(.black)
                            .font(Font.title.weight(.light))
                            .frame(width: 84, height: 64)
                        
                        ZStack {
                            Circle()
                                .fill(Color.white)
                            
                            Image(systemName: "checkmark")
                                .resizable()
                                .frame(width: 18, height: 18)
                                .foregroundColor(.black)
                        }
                        .frame(width: 38, height: 38)
                        .padding(.leading, 70)
                        .padding(.top, 40)
                    }
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 32))
                    
                    Text("MOBILE_email_address_verified".localized())
                        .lineLimit(nil)
                        .font(.robotoBold24)
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                    
                    Text("MOBILE_email_address_verified_description".localized())
                        .font(.robotoRegular16)
                        .foregroundColor(.black05)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                .padding(.horizontal, 38)
            }
            
            Button {
                (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.set(rootView: HomeView(
                    homeViewModel: MimoHomeViewModel(
                        worker: Resolver.resolve(),
                        locationManager: Resolver.resolve(),
                        messageServicce: Resolver.resolve(),
                        activeTrips: viewModel.activeTrips
                    )
                ).edgesIgnoringSafeArea(.all))
            } label: {
                Text("MOBILE_got_it".localized())
                    .foregroundColor(.black)
                    .font(.robotoMedium15)
                    .underline()
            }
            .buttonStyle(MimoButton())
            .padding(.bottom, 20)
        }
        .navigationBarHidden(true)
    }
}

extension EmailVerificationView {
    func open(mailType: EmailType) {
        switch mailType {
        case .appleMail:
            UIApplication.shared.open(URL(string: "message:")!, completionHandler: { self.isMailAppNotInstalled = !$0 })
        case .gmail:
            UIApplication.shared.open(URL(string: "googlegmail:")!, completionHandler: { self.isMailAppNotInstalled = !$0 })
        case .outlook:
            UIApplication.shared.open(URL(string: "ms-outlook:")!, completionHandler: { self.isMailAppNotInstalled = !$0 })
        }
    }
}
