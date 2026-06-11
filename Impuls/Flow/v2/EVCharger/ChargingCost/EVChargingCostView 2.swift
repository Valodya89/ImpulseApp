//
//  EVChargingCostView.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/28/25.
//

import SwiftUI

struct EVChargingCostView: View {
    @ObservedObject private var viewModel: EVChargingCostViewModel
    
    @State private var showShareSheet = false
    @State private var snapshotImage: UIImage? = nil
    
    init(viewModel: EVChargingCostViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack {
            ScrollView(.vertical) {
                VStack {
                    titleView
                    infoView()
                }
            }
            
            rateTitleView
            rateView
            Spacer()
            FooterButton {
                viewModel.continue()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(Color.evMainBgBlue.ignoresSafeArea())
        .compactNavigationView(title: "EV_CHARGER_charging_summary".localized(), backAction: {
            viewModel.back()
        })
    }
    
    var titleView: some View {
        Text("Thanks for using Mimo EVUP!")
            .font(.robotoMedium20)
            .foregroundColor(Color.evGray8)
            .padding(.top, 32)
            .padding(.horizontal, 20)
    }
    
    @ViewBuilder private func infoView(isShowShareButton: Bool = true) -> some View {
        VStack(alignment: .center, spacing: 0) {
            Text("Your total is")
                .font(.robotoRegular16)
                .foregroundColor(Color.evGray8)
                .padding(.top, 24)
                .padding(.horizontal, 20)
            
            Text("150֏")
                .font(.robotoBold32)
                .foregroundColor(Color.evGray8)
                .padding(.top, 8)
                .padding(.horizontal, 20)
            
            VStack(alignment: .center, spacing: 16) {
                infoItemView(imageName: "ev_charger_id_gradient", title: "Charger ID", value: "PWB45600056")
                infoItemView(imageName: "ev_charger_type_gradient", title: "Type", value: "Type 2")
                infoItemView(imageName: "ev_clock_gradient", title: "Duration", value: "01:32:34")
                infoItemView(imageName: "ev_charger_speed_gradient", title: "Speed", value: "100 kW")
                infoItemView(imageName: "ev_price_gradient", title: "Price", value: "4500 AMD")
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 32)
            
            if isShowShareButton {
                Button {
                    snapshotImage = self.infoView(isShowShareButton: false).snapshot()
                    showShareSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image("ev_share_top_arrow")
                        Text("Share Results")
                            .font(.robotoBold15)
                    }
                    .foregroundColor(Color.evGray8)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        Capsule()
                            .stroke(Color.evGray8, lineWidth: 1)
                    )
                }
                .padding(.horizontal, 44)
                .padding(.bottom, 24)
            }
        }
        .background(
            RoundedCorner(radius: 8)
                .fill(Color.evBgColor4)
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 2
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
    
    @ViewBuilder private func infoItemView(
        imageName: String,
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .center, spacing: 8) {
            Image(imageName)
                .resizable()
                .frame(width: 24, height: 24)
            
            Text(title.capitalized)
                .font(.robotoRegular16)
                .foregroundColor(Color.evGray8)
            
            Spacer()
            
            Text(value)
                .font(.robotoMedium16)
                .foregroundColor(Color.evGray8)
        }
    }
    
    var rateTitleView: some View {
        Text("Rate Mimo Charging")
            .font(.robotoMedium18)
            .foregroundColor(Color.evGray8)
            .padding(.horizontal, 20)
    }
    
    var rateView: some View {
        EVRateView(maxRating: 5, rating: $viewModel.rating)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(
                RoundedCorner(radius: 8)
                    .fill(Color.evBgColor4)
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 8,
                x: 0,
                y: 2
            )
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
    }
    
    var bottomActionView: some View {
        Button {
            
        } label: {
            Text("Thank you!")
                .font(.robotoBold15)
                .foregroundColor(Color.evGray8)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(LinearGradient.evBrandGradientHorizontal)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}
