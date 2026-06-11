//
//  NotifyMeView.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/23/25.
//

import SwiftUI
import Combine
import SwiftMessages

struct NotifyMeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel: NotifyMeViewModel
    @State var errorMessage: ErrorMessage?
    
    init(viewModel: NotifyMeViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            if viewModel.isSubscribedNews {
                successView
            } else {
                formView
            }
        }
        .navigationTitle("EVUP")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonTitleHidden()
        .clipped()
        .background(Color.clearVision.ignoresSafeArea())
        .onReceive(viewModel.$isLoading) { isLoading in
            if isLoading {
                MILoader.show()
            } else {
                MILoader.hide()
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
       
    private var formView: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(UIColor.mimoYellow500)
                
                Image("ev_envelope")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 94, height: 94)
            }
            .frame(width: 160, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .padding(.top, 40)
            
            Text("MOBILE_notifyMe_title".localized())
                .font(.robotoBold24)
                .foregroundColor(.gray8)
                .padding(.top, 40)
                .padding(.horizontal, 16)
            
            AttributedBoldText(
                input:"MOBILE_notityMe_subTtile".localized(),
                font: .robotoRegular16,
                boldFont: .robotoBold16
            )
            .foregroundColor(.gray6)
            .multilineTextAlignment(.center)
            .padding(.top, 20)
            .padding(.horizontal, 34)
            
            MimoTextField(title: "MOBILE_notifyMe_inputField_title".localized(),
                          placeholder: "MOBILE_notifyMe_inputField_placeholder".localized(),
                          text: $viewModel.email)
                .keyboardType(.emailAddress)
                .frame(height: 63)
                .padding(.top, 40)
                .padding(.horizontal, 20)
            
            Spacer()
            
            Button {
                viewModel.submitEmail()
            } label: {
                HStack(spacing: 8) {
                    Image("ev_envelope_open")
                    Text("MOBILE_notifyMe_button_title".localized())
                }
            }
            .buttonStyle(MimoButton(isEnabled: viewModel.isValid()))
            .disabled(!viewModel.isValid())
            .padding(.bottom, 20)
        }
    }
       
    private var successView: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(UIColor.mimoYellow500)
                
                Image("ev_envelope")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 94, height: 94)
                
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
            .padding(.top, 40)
            
            Text("MOBILE_notifyMe_success_title".localized())
                .font(.robotoBold24)
                .foregroundColor(.gray8)
                .padding(.top, 40)
                .padding(.horizontal, 16)
            
            Text("MOBILE_notifyMe_success_subTitle".localized())
                .font(.robotoRegular16)
                .foregroundColor(.gray6)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
                .padding(.horizontal, 34)
            
            Spacer()
            
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Text("MOBILE_notifyMe_success_button_title".localized())
            }
            .buttonStyle(MimoButton())
            .padding(.bottom, 20)
        }
    }
}
