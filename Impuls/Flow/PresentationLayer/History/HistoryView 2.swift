//
//  HistoryView.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/20/25.
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            SegmentedCapsulePicker(selected: $viewModel.selectedItem, options: viewModel.selectionItems)
                .padding([.top, .horizontal], 16)
            
            switch viewModel.selectedItem {
            case .scooter:
                scooterTripsListView()
            case .bike:
                bikeTripsListView()
            case .charger:
                chargerRentsListView()
            case .evup:
                evChargerRentsListView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.evBgColor.ignoresSafeArea())
        .safeAreaInset(edge: .top) { navigationView() }
    }
    
    private func headerView(_ title: String) -> some View {
        Text(title)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(Color.evText9)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.evBgColor)
    }
    
    func scooterTripsListView() -> some View {
        Group {
            if viewModel.scooterTrips.isEmpty {
                emptyDataView
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8, pinnedViews: .sectionHeaders) {
                        
                        ForEach(viewModel.scooterTrips, id: \.title) { section in
                            Section {
                                ForEach(section.items, id: \.id) { item in
                                    scooterView(item)
                                }
                                .padding(.horizontal, 16)
                            } header: {
                                headerView(section.title)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func scooterView(_ item: TripScooterDataModel) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                if let scooterQr = item.scooterQr {
                    HStack {
                        Image(.qrIcon)
                        
                        Text(scooterQr)
                            .lineLimit(1)
                            .frame(alignment: .leading)
                            .font(.robotoMedium15)
                            .foregroundColor(.gray5)
                        
                    }
                    .padding(5)
                    .roundedBorderMedium(color: .evbrandCyan80, lineWidth: 1)
                }

                HStack {
                    VStack {
                        if let start = item.start {
                            Text("Start: \(Date(timeIntervalSince1970: TimeInterval(start / 1000)).toString())")
                                .font(.robotoMedium14)
                                .foregroundColor(.gray5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if let end = item.end {
                            Text("End: \(Date(timeIntervalSince1970: TimeInterval(end / 1000)).toString())")
                                .font(.robotoMedium14)
                                .foregroundColor(.gray5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Spacer()
                    
                    if let amount = item.payment?.amount {
                        Text(amount.description + " " + "MOBILE_global_total_currency".localized())
                            .font(.robotoBold14)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(uiColor: item.payment?.status?.backgroundColor ?? .mimoRed500))
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        }
    }
    
    func bikeTripsListView() -> some View {
        Group {
            if viewModel.bikeTrips.isEmpty {
                emptyDataView
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8, pinnedViews: .sectionHeaders) {
                        
                        ForEach(viewModel.bikeTrips, id: \.title) { section in
                            Section {
                                ForEach(section.items, id: \.id) { item in
                                    bikeView(item)
                                }
                                .padding(.horizontal, 16)
                            } header: {
                                headerView(section.title)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func bikeView(_ item: TripBikeDataModel) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(.qrIcon)
                    
                    Text(item.id)
                        .lineLimit(1)
                        .frame(alignment: .leading)
                        .font(.robotoMedium15)
                        .foregroundColor(.gray5)
                    
                }
                .padding(5)
                .roundedBorderMedium(color: .evbrandCyan80, lineWidth: 1)

                HStack {
                    VStack {
                        if let start = item.start {
                            Text("Start: \(Date(timeIntervalSince1970: TimeInterval(start / 1000)).toString())")
                                .font(.robotoMedium14)
                                .foregroundColor(.gray5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        if let end = item.end {
                            Text("End: \(Date(timeIntervalSince1970: TimeInterval(end / 1000)).toString())")
                                .font(.robotoMedium14)
                                .foregroundColor(.gray5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Spacer()
                    
                    if let amount = item.payment?.amount {
                        Text(amount.description + " " + "MOBILE_global_total_currency".localized())
                            .font(.robotoBold14)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(Color(uiColor: item.payment?.status?.backgroundColor ?? .mimoRed500))
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        }
    }
    
    func chargerRentsListView() -> some View {
        Group {
            if viewModel.chargerRents.isEmpty {
                emptyDataView
            } else {
//                emptyDataView
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8, pinnedViews: .sectionHeaders) {
                        
                        ForEach(viewModel.chargerRents, id: \.title) { section in
                            Section {
                                ForEach(section.items, id: \.id) { item in
                                    chargerView(item)
                                }
                                .padding(.horizontal, 16)
                            } header: {
                                headerView(section.title)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func chargerView(_ item: ChargerRentModel) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(item.powerBank)
                    .font(.robotoMedium15)
                    .foregroundColor(.evText9)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .roundedBorderMedium(color: .evbrandCyan80, lineWidth: 1)
                
                Text("MOBILE_global_start_date".localized() + " - \(Date(timeIntervalSince1970: TimeInterval(item.start)).toString(dateStyle: .none, timeStyle: .short))")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.evText6)
                    .font(.robotoRegular12)
                Text("MOBILE_global_end_date".localized() + " - \(Date(timeIntervalSince1970: TimeInterval(item.end)).toString(dateStyle: .none, timeStyle: .short))")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.evText6)
                    .font(.robotoRegular12)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                Text("EV_CHARGER_amount".localized())
                    .font(.robotoMedium15)
                    .foregroundColor(.evText9)
                    .padding(.horizontal, 8)
                
                Text("\(item.payment.amount ?? 0)" + " " + "MOBILE_global_total_currency".localized())
                    .font(.robotoBold14)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(uiColor: item.payment.status?.backgroundColor ?? .mimoRed500))
                    )

            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        }
    }
    
    func evChargerRentsListView() -> some View {
        Group {
            if viewModel.evChargerRents.isEmpty {
                emptyDataView
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8, pinnedViews: .sectionHeaders) {
                        
                        ForEach(viewModel.evChargerRents, id: \.title) { section in
                            Section {
                                ForEach(section.items, id: \.id) { item in
                                    evChargerView(item)
//                                        .onTapGesture {
//                                            withAnimation(.easeInOut(duration: 0.4)) {
//                                                if viewModel.selectedCellItem == item.id {
//                                                    viewModel.selectedCellItem = ""
//                                                } else {
//                                                    viewModel.selectedCellItem = item.id
//                                                }
//                                            }
//                                        }
                                }
                                .padding(.horizontal, 16)
                            } header: {
                                headerView(section.title)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func evChargerView(_ item: EVChargerRentViewModel) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                
                HStack {
                    Image(.evLocationMarker)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20, alignment: .center)
                    Text("\(item.destinationName ?? "")  \(item.destinationAddress ?? "")")
                        .font(.robotoRegular14)
                        .foregroundColor(.gray5)
                }
                    
                HStack {
                    HStack {
                        Image(.qrIcon)
                            
                        Text(item.stationId)
                            .lineLimit(1)
                            .frame(alignment: .leading)
                            .font(.robotoMedium15)
                            .foregroundColor(.gray5)

                    }
                    .padding(5)
                    .roundedBorderMedium(color: .evbrandCyan80, lineWidth: 1)
                    
                    Text(item.connectorType?.title ?? "")
                        .frame(alignment: .leading)
                        .font(.robotoMedium14)
                        .foregroundColor(.evText9)
                    
                    Spacer()
                    
                    Text("\(item.formatedStartDate) • \(item.minutesBetweenDates)")
                        .font(.robotoMedium12)
                        .foregroundColor(.gray6)
                }
                
                HStack {
                    Text("\("EV_CHARGER_charged".localized()) :")
                        .font(.robotoMedium14)
                        .foregroundColor(.gray5)
                    
                    Text("\(item.kwtsCharged.stringValueRoundedUp2) \("EV_CHARGER_kw".localized())")
                        .font(.robotoMedium14)
                        .foregroundColor(.evText9)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("\(String(item.amount)) \(item.currency)")
                        .font(.robotoMedium14)
                        .foregroundColor(.evText9)
                }
                
//                if item.id == viewModel.selectedCellItem {
//                    receiptView(receipt: item)
//                        .transition(.opacity)
//                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        }
    }
    
    func navigationView() -> some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                Text("MOBILE_profile_history".localized())
                    .font(.robotoBold15)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding()
            
            Image(.icCloseBig)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .padding(.leading, 18.5)
                .onTapGesture { viewModel.back() }
        }
        .background(Color.white)
    }
    
    func receiptView(receipt: EVChargerRentModel) -> some View {
        
        let isPaymentSuccessful: Bool = true // you can write your logic hear, why it succses or fail,  MARK: i dont have data about it
        
        return VStack(alignment: .center, spacing: 14) {
            Divider()
            
            Text(isPaymentSuccessful ? "Payment Succsess" : "Payment Failed")
                .font(.robotoMedium15)
                .foregroundColor(.evText9)
            
            Line()
              .stroke(Color.evStroke, style: StrokeStyle(lineWidth: 1, dash: [5]))
              .frame(height: 1)
            
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    Text("chargerID")
                        .font(.robotoRegular14)
                        .foregroundColor(.evText6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("4567890")
                        .font(.robotoMedium14)
                        .foregroundColor(.evText9)
                }
                
                // need to add Hstacks with his propertys   , but i dont know whate propertys are available hear and we should show 
            }
        }
    }
    
    var emptyDataView: some View {
        VStack(spacing: 8) {
            Image("ic_empty_data")
            
            Text("EV_CHARGER_history_empty_title".localized())
                .font(.robotoSemibold16)
                .foregroundColor(Color.black08)
            
            Text("EV_CHARGER_history_empty_description".localized())
                .font(.robotoRegular15)
                .foregroundColor(Color.gray8)
       
        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 16)
    }
}
