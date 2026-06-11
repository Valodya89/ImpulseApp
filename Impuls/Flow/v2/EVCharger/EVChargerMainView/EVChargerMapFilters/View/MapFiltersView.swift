//
//  MapFiltersView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 26.02.25.
//

import SwiftUI

struct MapFiltersView: View {
    @ObservedObject var viewModel: MapFiltersViewModel
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(spacing: 28) {
                    chargerTypeSection()
                    chargingPowerSection()
                    connectorsSection()
                    amenitiesSection()
                }
                .padding(.top, 28)
                .padding(.horizontal, 20)
            }
            Spacer()
            bottomActionView
        }
        .background(Color.evMainBgBlue.ignoresSafeArea())
        .compactNavigationView(title: "EV_CHARGER_filter".localized(), backAction: {
            viewModel.closeFiltersView()
        }, rightAction: {
            viewModel.resetFilters()
        })
        
    }
    
    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: 10, alignment: .center),
        count: 3
    )
    
    @ViewBuilder private func chargerTypeSection() -> some View {
        VStack(spacing: 16) {
            ListSectionHeaderView(title: "EV_CHARGER_charger_type".localized())
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.chargerTypes) { item in
                    FilterChargeOptionView(item: item)
                        .onTapGesture {
                            viewModel.toggleSelection(for: item)
                        }
                }
            }
        }
    }
    
    @ViewBuilder private func chargingPowerSection() -> some View {
        VStack(spacing: 0) {
            ListSectionHeaderView(title: "EV_CHARGER_charging_power".localized())
            
            EVRangedSliderView(
                lowerValue: $viewModel.lowerValue,
                upperValue: $viewModel.upperValue,
                minValue: viewModel.minValue,
                maxValue: viewModel.maxValue
            )
            .padding(.top, 16)
            
            HStack {
                Text("\(Int(viewModel.minValue))kW")
                    .font(.robotoRegular12)
                    .foregroundColor(Color.evText8)
                
                Spacer()
                
                Text("\(Int(viewModel.maxValue))kW")
                    .font(.robotoRegular12)
                    .foregroundColor(Color.evText8)
            }
            
            HStack {
                Image("ev_flash_bordered")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .foregroundColor(Color.evText6)
                
                Text("EV_CHARGER_selected_range".localized())
                    .font(.robotoMedium14)
                    .foregroundColor(Color.evText6)
                
                Spacer()
                    
                Text("\(Int(viewModel.lowerValue))" + "EV_CHARGER_kw".localized() + " - \(Int(viewModel.upperValue))" + "EV_CHARGER_kw".localized())
                    .font(.robotoMedium14)
                    .foregroundColor(Color.evText8)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.evMainBg2)
            .cornerRadius(8)
            .padding(.top, 20)
        }
    }
    
    @ViewBuilder private func connectorsSection() -> some View {
        VStack(spacing: 16) {
            ListSectionHeaderView(title: "EV_CHARGER_connectors".localized())
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.connectors) { item in
                    FilterChargeOptionView(item: item)
                        .onTapGesture {
                            viewModel.toggleSelection(for: item)
                        }
                }
            }
        }
    }
    
    @ViewBuilder private func amenitiesSection() -> some View {
        VStack(spacing: 16) {
            ListSectionHeaderView(title: "EV_CHARGER_ammenities".localized())
            
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(viewModel.amenities) { item in
                    FilterChargeOptionView(item: item)
                        .onTapGesture {
                            viewModel.toggleSelection(for: item)
                        }
                }
            }
        }
    }
    
    var bottomActionView: some View {
        Button {
            viewModel.showFilteredStations()
        } label: {
            Text("EV_CHARGER_show_locations".localized())
                .font(.robotoBold15)
                .foregroundColor(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.evbrandCyan80)
                .clipShape(Capsule())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}


struct ListSectionHeaderView: View {
    let title: String
    var body: some View {
        HStack {
            Text(title)
                .font(.robotoMedium17)
                .foregroundColor(.evText9)
            Spacer()
        }
    }
}
