//
//  RatesView.swift
//  MimoBike
//
//  Created by Yurka Babayan on 11.07.25.
//

import SwiftUI

struct RatesView: View {
    
    @ObservedObject var viewModel: RatesViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                SegmentedCapsulePicker(selected: $viewModel.selectedItem, options: viewModel.selectionItems)
                    .padding([.top, .horizontal], 16)
                pageDetailItemsView()
                switch viewModel.selectedItem {
                case .scooter:
                    scooterPage()
                case .bike:
                    bikePage()
                case .charger:
                    chargerPage()
                case .evup:
                    evUpPage()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.evBgColor.ignoresSafeArea())
        .safeAreaInset(edge: .top) { navigationView() }
    }
}

extension RatesView {    
    func pageDetailItemsView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 45) {
                ForEach(viewModel.pageSelectionItems, id: \.self) { item in
                    VStack(spacing: 0) {
                        Text(item.rawValue)
                            .font(.robotoBold12)
                            .foregroundColor(viewModel.pageSelectedItem == item ? .black : .black.opacity(0.5))
                            .padding(.all, 10)
                        
                        if viewModel.pageSelectedItem == item {
                            RoundedRectangle(cornerRadius: 16)
                                .frame(height: 2)
                                .foregroundColor(Color.black)
                        }
                    }
                    .onTapGesture { viewModel.pageItemTapAction(item: item) }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    func navigationView() -> some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                Text("Mimo Rates")
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
    
    func scooterPage() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            bookingTabView(
                image: "ic_bookmark_check",
                title: "BOOKING",
                subtitle: "FREE",
                description: "5 minute free after each minutes 2amd"
            )
            scootersListView()
            if let scooter = viewModel.selectedScooter { speedChargeInfoView(scooter: scooter) }
            Divider()
                .padding(.horizontal, 16)
                .padding(.vertical, 17)
            challangesTabView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    func bikePage() -> some View {
        VStack(spacing: 0) {
            bookingTabView(
                image: "ic_Cap",
                title: "Student",
                subtitle: "4.99 AMD/Minute",
                description: "Minimal fee is 99.9 amd"
            ) {
                viewModel.bikeStudentAction()
            }
            
            bookingTabView(
                image: "ic_cube_box",
                title: "Basic",
                subtitle: "9.99 AMD/Minute",
                description: "Minimal fee is 99.9 amd"
            )
            
            bookingTabView(
                image: "ic_bookmark_check",
                title: "Booking",
                subtitle: "Free",
                description: "Daily limit is 3 times"
            )
        }
    }
    
    func bookingTabView(
        image: String,
        title: String,
        subtitle: String,
        description: String,
        action: Action? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.robotoBold16)
                    .foregroundColor(.black)
                
                Spacer()
                
                Text(subtitle)
                    .font(.robotoBold16)
                    .foregroundColor(.black)
            }
            .padding(.top, 17)
            
            Divider()
            
            Text(description)
                .font(.robotoSemibold14)
                .foregroundColor(.black)
            
            if let action = action {
                Button {
                    action()
                } label: {
                    Text("Activate")
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)
                        .background(Color.brandYellow)
                        .clipShape(RoundedRectangle(cornerRadius: 50))
                        .padding(.horizontal, 70)
                }
                .padding(.top, 16)
            }
        }
        .padding(.bottom, action != nil ? 11 : 19)
        .padding(.horizontal, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 8)
        .padding(.top, 23)
        .padding(.horizontal)
    }
    
    func chargerPage() -> some View {
        VStack(spacing: 0) {
            Text("Once your tariff time is up, it switches to the next tariff.")
                .font(.robotoMedium13)
                .foregroundColor(Color(hex: "#404040"))
                .padding(.top, 24)
            
            bookingTabView(
                image: "ic_cube_box",
                title: "Start",
                subtitle: "0 AMD",
                description: "5 min = 0 amd"
            )
        }
    }
    
    func evUpPage() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                Image(.evChargingTypeSuperFastCyan)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 35, height: 35)
                
                Text("$10/kwh - $20/kwh")
                    .font(.robotoBold20)
                    .foregroundColor(.black)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                
                VStack(alignment: .center, spacing: 0) {
                    Text("This is an approximate pricing range.")
                    Text("Each station has unique pricing.")
                }
                .font(.robotoRegular12)
                .foregroundColor(Color(hex: "#808080"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 16)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.grayBackground, lineWidth: 2)
            )
            .shadow(color: Color.grayBackground, radius: 16)
            .padding(.horizontal, 16)
        }
    }
    
    func scootersListView() -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Scooters")
                .font(.robotoBold17)
                .padding(.leading, 25)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.rateScooters, id: \.id) { scooter in
                        scooterItemView(scooter: scooter)
                            .onTapGesture { viewModel.rateScooterItemTapction(scooter: scooter) }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 17)
            }
        }
        .padding(.top, 26)
    }
    
    func scooterItemView(scooter: RatesScooterModel) -> some View {
        HStack(spacing: 0) {
            Image(.icScooterList)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 24)
            
            Text(scooter.name)
                .foregroundColor(.black)
                .font(.robotoBold16)
        }
        .padding(.all, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(viewModel.selectedScooter == scooter ? Color.brandYellow : Color.clear, lineWidth: 2)
        )
        .shadow(color: Color.grayBackground, radius: 10)
    }
    
    func speedChargeInfoView(scooter: RatesScooterModel) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Speed charge")
                .font(.robotoBold17)
                .padding(.bottom, 17)
                .padding(.leading, 25)
            
            HStack(spacing: 36.5) {
                Spacer()
                ForEach(0..<scooter.speedChargeTarrif.count, id: \.self) { index in
                    speedChargeInfoItem(
                        title: String(viewModel.rateScootersSpeed[index]),
                        subTitle: String(scooter.speedChargeTarrif[index])
                    )
                    
                    if scooter.speedChargeTarrif[index] != scooter.speedChargeTarrif.last {
                        Divider()
                            .frame(height: 45)
                    }
                }
                Spacer()
            }
            
            Text("Tariffs")
                .font(.robotoBold17)
                .padding(.bottom, 17)
                .padding(.leading, 25)
                .padding(.top, 30)
            
            VStack(alignment: .leading, spacing: 20) {
                tariffsItemView(image: "ic_alarmClock", title: "For 1 hour", subTitle: "Pay by hourly 1375֏ and enjoy your trip")
                tariffsItemView(image: "ic_timer", title: "Minute by minute ", subTitle: "Pay by minute 75֏+ 35֏/min and you can stop youre ride when you want")
                tariffsItemView(image: "ic_batteryFullFill", title: "Do not sit", subTitle: "Pay 3375֏ and ride until your scooter energy over")
            }
            .padding(.horizontal, 25)
        }
        .padding(.top, 20)
        .padding(.bottom, 24)
        .background(Color.white)
    }
    
    func tariffsItemView(image: String, title: String, subTitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.robotoBold15)
                    .foregroundColor(.black)
            }
            
            Text(subTitle)
                .font(.robotoMedium13)
        }
    }
    
    func speedChargeInfoItem(title: String, subTitle: String) -> some View {
        VStack(spacing: 10) {
            Text("\(title) km/h")
                .foregroundColor(Color.gray)
                .font(.robotoMedium14)
            
            Text("\(subTitle) ֏")
                .foregroundColor(Color.black)
                .font(.robotoMedium15)
        }
    }
    
    func challangesTabView() -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Challenges 💪")
                    .font(.robotoLight14)
                    .foregroundColor(Color.black)
                
                Text("Endurance Challenge")
                    .font(.robotoLight14)
                    .foregroundColor(Color(hex: "#404040"))
            }
            
            Spacer()
            
            Image("ic_arrow_right_bold")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.black)
                .frame(width: 10, height: 10)
        }
        .padding([.horizontal, .top], 12)
        .padding(.bottom, 14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.grayBackground, lineWidth: 2)
        )
        .padding(.horizontal, 20)
        .onTapGesture { viewModel.chanlangeTapAction() }
    }
}
