//
//  ProductSelectionView.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/23/25.
//

import SwiftUI
import SwiftMessages

struct ProductSelectionView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var viewModel: ProductSelectionViewModel
    @State var errorMessage: ErrorMessage?
    
    init(viewModel: ProductSelectionViewModel) {
        self.viewModel = viewModel
    }
    
    private let numberColumns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
     ]
    
    var body: some View {

        VStack {
            LazyVGrid(columns: numberColumns, spacing: 20) {
                ForEach(viewModel.availableProducts, id: \.service) { product in
                    ProductCardView(product: product)
                        .onTapGesture {
                            viewModel.toggleSelection(for: product)
                        }
                }
            }
            .padding(.top, 40)
            .padding(.horizontal, 20)
            
            Spacer()
            
            Button {
                viewModel.save()
            } label: {
                Text("MOBILE_products_screen_save".localized())
            }
            .buttonStyle(MimoButton(isEnabled: viewModel.isValid()))
            .padding(.bottom, 20)
            .disabled(!viewModel.isValid())
        }
        .navigationTitle("MOBILE_products_screen_title".localized())
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonTitleHidden()
        .clipped()
        .background(Color.clearVision.ignoresSafeArea(edges: .bottom))
        .onReceive(viewModel.$isLoading) { isLoading in
            if isLoading {
                MILoader.show()
            } else {
                MILoader.hide()
            }
        }
        .onReceive(viewModel.$shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                presentationMode.wrappedValue.dismiss()
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
}
