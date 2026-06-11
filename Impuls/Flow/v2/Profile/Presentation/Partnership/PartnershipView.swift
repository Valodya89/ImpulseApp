//
//  PartnershipView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.10.23.
//

import SwiftUI

struct PartnershipView: View {
    
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State var isCountryCodePresented: Bool = false
    
    @ObservedObject private var viewModel = PartnershipViewModel(worker: Resolver.resolve(), locationManager: Resolver.resolve())
    
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
                
                Text("MOBILE_partnership_application_title".localized())
                    .font(.robotoBold17)
                    .foregroundColor(.black)
            }
            .frame(height: 54)
            .background(Color.white)
            
            ScrollView(.vertical) {
                
                Spacer(minLength: 30)
                
                VStack(spacing: 15) {
                    MimoTextField(title: "MOBILE_partnership_fullName".localized(), placeholder: "MOBILE_partnership_fullName".localized(), text: $viewModel.fullName)
                        .frame(height: 63)
                    
                    MimoTextField(title: "MOBILE_partnership_email".localized(), placeholder: "MOBILE_partnership_email".localized(), text: $viewModel.email)
                        .frame(height: 63)
                    
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
                    
                    MimoTextField(title: "MOBILE_partnership_location".localized(), placeholder: "MOBILE_partnership_location".localized(), text: $viewModel.location)
                        .frame(height: 63)
                }
                .padding(.horizontal, 20)
            }
            
            Button {
                MILoader.show()
                viewModel.submit()
            } label: {
                Text("MOBILE_global_submit".localized())
            }
            .buttonStyle(MimoButton(isEnabled: viewModel.isValid()))
            .padding(.bottom, 20)
            .padding(.top, 30)

        }
        .background(Color.grayBackground.ignoresSafeArea())
        .sheet(isPresented: $isCountryCodePresented) {
            CountryCodeView(code: $viewModel.selectedCountry)
        }
        .alert(isPresented: $viewModel.applicationSubmited) {
            Alert(title: Text("MOBILE_partnership_success_message".localized()), dismissButton: .default(Text("MOBILE_global_ok".localized()), action: {
                MILoader.hide()
                presentationMode.wrappedValue.dismiss()
            }))
        }
        .onReceive(viewModel.$errorMessage) { error in
            if error != nil {
                MILoader.hide()
            }
        }
        .onReceive(viewModel.$applicationSubmited) { _ in
            MILoader.hide()
        }
    }
}

#Preview {
    PartnershipView()
}
