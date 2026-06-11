//
//  EVChargerSuccessView.swift
//  MimoBike
//
//  Created by Yurka Babayan on 02.08.25.
//

import SwiftUI

struct EVChargerSuccessView: View {
    
    @ObservedObject var viewModel: EVSuccessViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            navigationView()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 0) {
                        Image(.evMediumLogo)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 75, height: 25)
                        
                        VStack(spacing: 16) {
                            Text("EV_CHARGER_session_total".localized())
                                .font(.robotoBold17)
                                .foregroundColor(Color(hex: "#666666"))
                            
                            Text(viewModel.totalPrice)
                                .font(.robotoBold24)
                                .foregroundColor(Color.evbrandCyan80)
                        }
                        .padding(.vertical, 58)
                        
                        VStack(spacing: 8) {
                            infoCharacterView(title: "EV_CHARGER_connector".localized(), value: viewModel.conectorNumber)
                            infoCharacterView(title: "EV_CHARGER_charger_type".localized(), value: viewModel.chargerType)
                            infoCharacterView(title: "EV_CHARGER_charged".localized(), value: viewModel.charged)
//                            infoCharacterView(title: "EV_CHARGER_charge_duration".localized(), value: viewModel.chargeDuration)
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 63)
                        
                        VStack(spacing: 8) {
                            Text("EV_CHARGER_rate_your_experience".localized())
                                .font(.robotoRegular15)
                                .foregroundColor(Color(hex: "#666666"))
                            
                            HStack(spacing: 16) {
                                ForEach(0..<5, id: \.self) { index in
                                    Image(index <= viewModel.selectedIndex ? .evFlashFill : .evFlashInactive)
                                        .onTapGesture {
                                            viewModel.selectedIndex = index
                                        }
                                }
                            }
                            Spacer()
//                            Text("Amazing!")
//                                .foregroundColor(Color.evbrandCyan80)
//                                .font(.robotoBold15)
//                                .padding(.top, 24)
//                                .padding(.bottom, 16)
                            
                            TextField(
                                "",
                                text: $viewModel.comment,
                                prompt: Text("EV_CHARGER_rate_field_playcholder".localized())
                                    .foregroundColor(Color.evbrandCyan80)
                            )
                            .padding(.all, 16)
                            .background(Color.evbrandCyan80.opacity(0.3))
                            .cornerRadius(16, corners: .allCorners)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.evbrandCyan80, lineWidth: 1)
                            )
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .padding(.horizontal, 32)
                                .padding(.vertical, 16)
                            
//                            Text(viewModel.attributedText)
                        }
                    }
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    Spacer()
                }
            }
            .background(Color.evBgColor.ignoresSafeArea())
            
            Button {
                viewModel.routeToMap()
            } label: {
                Text("EV_CHARGER_ok".localized())
                    .font(.robotoBold15)
                    .foregroundColor(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Capsule().fill(Color.evbrandCyan80))
            }
            .padding(.horizontal, 16)
        }
    }
}

extension EVChargerSuccessView {
    func navigationView() -> some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                Text("EV_CHARGER_charging_summary".localized())
                    .font(.robotoBold15)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding()
        }
        .background(Color.white)
    }
    
    func infoCharacterView(title: String, value: String) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.robotoRegular15)
                .foregroundColor(Color(hex: "#666666"))
            
            Spacer()
            
            Text(value)
                .font(.robotoRegular15)
                .foregroundColor(Color.evbrandCyan80)
        }
    }
}
