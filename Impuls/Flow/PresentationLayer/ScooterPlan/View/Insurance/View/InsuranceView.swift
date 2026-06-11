//
//  InsuranceView.swift
//  MimoBike
//
//  Created by Yurka Babayan on 19.09.25.
//

import SwiftUI

struct InsuranceView: View {
    @State private var errorMessage: String?
    @ObservedObject var viewModel: InsuranceViewModel
    @Environment(\.dismiss) private var dismiss
    var onAction: () -> Void
    var onDismiss: (() -> Void)?
    
    init(viewModel: InsuranceViewModel, onAction: @escaping () -> Void = {}) {
            self.viewModel = viewModel
            self.onAction = onAction
        }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                insuranceIconView
                
                Text("SCOOTER_insurance_name".localized())
                    .foregroundColor(Color.black)
                    .font(.robotoBold17)
            }
            .padding(.top, 12)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(viewModel.attributes, id: \.self) { attribute in
                    atriputedLinkTextView(attribute: attribute)
                }
                .padding(.bottom)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("SCOOTER_insurance_terms_title".localized())
                        .foregroundColor(Color.black)
                        .font(.robotoBold14)
                    
                    HStack(spacing: 10) {
                        Image(viewModel.termsCheckIsSelected ? "ic_checkBox_filled" : "ic_checkBox_empty")
                            .onTapGesture {
                                viewModel.termsCheckIsSelected.toggle()
                            }
                        
                        Text(viewModel.attributesTermsText)
                            .foregroundColor(Color.gray)
                            .font(.robotoMedium15)
                    }
                }
            }
            
            Spacer()
            
            Button {
                if viewModel.termsCheckIsSelected {
                    viewModel.activateInsurance { result in
                        switch result {
                        case .success(let data):
                            print(data)
                            onAction()
                            self.dismiss()
                        case .failure(let error):
                            print(error)
                            errorMessage = error.localizedDescription.localized()
                        }
                    }
                }
            } label: {
                Text("OK")
                    .font(.robotoBold14)
                    .foregroundColor(Color.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.termsCheckIsSelected ? Color.mimoYellow500 : Color.gray4.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 16)
            }
            
        }
        .padding(.all, 16)
        .onDisappear {
                    print("SheetView is closing")
                    onDismiss?()
        }
        .showErrorAlertMessage($errorMessage)
    }
    
    func atriputedLinkTextView(attribute: AttributedString) -> some View {
        HStack(spacing: 16) {
            Circle()
                .foregroundColor(Color.black)
                .frame(width: 7, height: 7)
            
            Text(attribute)
                .font(.robotoMedium15)
            
            Spacer()
        }
    }
    
    var insuranceIconView: some View {
        switch StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.preferredLanguages[0].prefix(2)) {
        case "en":
            Image("insurance_ic_en")
                .resizable()
                .frame(width : 42, height: 42)
        case "ru":
            Image("insurance_ic_am")
                .resizable()
                .frame(width : 42, height: 42)
        default:
            Image("insurance_ic_am")
                .resizable()
                .frame(width : 42, height: 42)
        }
    }
}

struct ErrorAlertModifier: ViewModifier {
    
    @Binding var errorMessage: String?
    
    func body(content: Content) -> some View {
        content
            .alert("MOBILE_global_warning".localized(), isPresented: Binding(
                get: { errorMessage != nil },
                set: { _ in errorMessage = nil }
            )) {
                Button("MOBILE_global_ok".localized(), role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "")
            }
    }
}

extension View {
    func showErrorAlertMessage(_ errorMessage: Binding<String?>) -> some View {
        self.modifier(ErrorAlertModifier(errorMessage: errorMessage))
    }
}
