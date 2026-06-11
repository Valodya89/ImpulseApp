//
//  SelectAmountView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 25.03.25.
//

import SwiftUI
import UIKit

struct SelectAmountView: View {

    @ObservedObject var viewModel: SelectAmountViewModel
    @State var errorMessage: ErrorMessage?

    // ✅ Haptics
    @State private var lastHapticStep: Int = -1
    private let selectionFeedback = UISelectionFeedbackGenerator()

    // ✅ Prevent haptic when you change value in code (not user drag)
    @State private var isProgrammaticHeightChange = false

    var body: some View {
        VStack(spacing: 0) {

            EVSelectedConnectorCardView(connector: viewModel.connector)
                .padding(.top, 20)

            ChargingRateView(
                heightOnchange: $viewModel.heightOnChanged,
                maxKWate: CGFloat(viewModel.maxValue),
                priceKW: viewModel.priceKW,
                currency: viewModel.currency
            )
            .padding(.horizontal, 112)
            .frame(height: 300)
            .padding(.top, 63)
            .onChange(of: viewModel.heightOnChanged) { value in

                // ✅ HAPTIC HERE (every 0.1)
                fireStepHapticIfNeeded(for: value)

                // your logic
                if value < 1 {
                    viewModel.selectedOption = false
                } else {
                    viewModel.selectedOption = true
                }
            }

            PickerSegmentedView(selectedOption: $viewModel.selectedOption)
                .padding(.top, 32)
                .onChange(of: viewModel.selectedOption) { value in
                    if value {
                        // prevent haptic for programmatic jump
                        isProgrammaticHeightChange = true
                        viewModel.heightOnChanged = 1

                        // reset flag next runloop
                        DispatchQueue.main.async {
                            isProgrammaticHeightChange = false
                        }
                    }
                }

            Spacer()

            FooterButton {
                viewModel.startCharging()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(Color.evMainBgBlue.ignoresSafeArea())
        .compactNavigationView(title: "EV_CHARGER_select_amount_title".localized(), backAction: {
            viewModel.back()
        })
        .onAppear {
            viewModel.onAppear()

            // ✅ Prepare for less latency
            selectionFeedback.prepare()

            // init last step based on initial value (optional)
            lastHapticStep = stepIndex(for: viewModel.heightOnChanged)
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
                    Color.black.opacity(0.3).ignoresSafeArea()
                    ProgressView().scaleEffect(1.5)
                }
            }
        }
        .alert(isPresented: $viewModel.showAttentionAlert) {
            Alert(
                title: Text("EV_CHARGER_attention_alert_title".localized()),
                message: Text("EV_CHARGER_attention_alert_message".localized()),
                dismissButton: .cancel(Text("EV_CHARGER_ok".localized())) {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.prepare()
                    generator.impactOccurred()
                    viewModel.attetionOkTapped()
                }
            )
        }
    }

    // MARK: - Haptic helpers

    private func fireStepHapticIfNeeded(for rawValue: CGFloat) {
        // don’t vibrate for programmatic changes
        guard !isProgrammaticHeightChange else { return }

        let step = stepIndex(for: rawValue)
        guard step != lastHapticStep else { return }

        lastHapticStep = step
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare()
    }

    /// Converts 0...1 value into a step index for 0.1 steps: 0...10
    private func stepIndex(for rawValue: CGFloat) -> Int {
        let v = max(0, min(1, Double(rawValue))) // clamp 0...1
        return Int((v / 0.1).rounded(.down))
    }
}

struct EVSelectedConnectorCardView: View {
    let connector: EVChargingConnector
    
    var body: some View {
        HStack(spacing: 12) {
            leftView
            centerView
            middleLine
            rightView
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var leftView: some View {
        VStack(alignment: .center, spacing: 8) {
            Image(connector.type.iconName)
                .resizable()
                .foregroundColor(.gray)
                .frame(width: 50, height: 50)
        }
    }
    
    private var centerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("EV_CHARGER_connector".localized() + " N\(connector.id)")
                    .font(.robotoMedium15)
                Text(connector.type.title)
                    .font(.robotoRegular12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
        
    private var middleLine: some View {
        Rectangle()
            .fill(Color.black60)
            .frame(width: 2, height: 60)
            
    }
    
    private var rightView: some View {
        VStack(alignment: .center, spacing: 8) {
            
            Text(connector.power.stringValue + " " + "EV_CHARGER_kw".localized())
                .font(.robotoMedium14)
                .foregroundColor(.evGray12)
            
            Text("\(connector.pricePerKW.description) AMD/KW")
                .font(.robotoRegular12)
                .foregroundColor(.evGray8)
        }
    }
}
