//
//  EVChargerDetailsView.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/25/25.
//

import SwiftUI
import Kingfisher
import CoreLocation
import MapKit

struct EVChargerDetailsView: View {
    @ObservedObject private var viewModel: EVChargerDetailsViewModel
    @Environment(\.openURL) var openURL
    @State private var showWalletScreen = false
    @State private var showDialog = false
    @State private var errorMessage: ErrorMessage?
    
    init(viewModel: EVChargerDetailsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                if let station = viewModel.station {
                    balanceView
                    
                    EVContactSupportButton()
                        .padding(.horizontal, 16)
                    
                    ScrollView(.vertical) {
                        LazyVStack(spacing: 16) {
                            detailsView(station)
                            
                            if let medias = station.images, !medias.isEmpty {
                                mediaView(medias)
                            }
                            
                            tabsView()
                                .padding(.bottom, 20)
                        }
                    }
                } else {
                    ProgressView("Loading...")
                        .padding()
                }
            }
            
            selectedMediaOverlay
        }
        .background(Color.evBgColor.ignoresSafeArea())
        .sheet(isPresented: $showWalletScreen) {
            WalletView(viewModel: MimoWalletViewModel(worker: Resolver.resolve(), productType: .evCharger))
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
        .confirmationDialog("Choose Map", isPresented: $showDialog, titleVisibility: .visible) {
            
            if let latitude = viewModel.station?.location?.latitude, let longitude = viewModel.station?.location?.longitude {
                Button("Yandex Maps") {
                    openYandexMaps(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                }
                
                Button("Google Maps") {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    openGoogleMaps(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                }
                
                Button("Apple Maps") {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    openAppleMaps(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                }
                Button("Cancel", role: .cancel) {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                }
            }
        }
    }
    
    private func openYandexMaps(coordinate: CLLocationCoordinate2D) {
           let url = URL(string: "yandexmaps://build_route_on_map/?lat_to=\(coordinate.latitude)&lon_to=\(coordinate.longitude)")!
           if UIApplication.shared.canOpenURL(url) {
               UIApplication.shared.open(url)
           } else if let url = URL(string: "https://yandex.ru/maps/?ll=\(coordinate.latitude),\(coordinate.longitude)&z=12&l=map") {
               UIApplication.shared.open(url)
           }
       }
       
       private func openGoogleMaps(coordinate: CLLocationCoordinate2D) {
           let url = URL(string: "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving&zoom=14&views=traffic")!
           if UIApplication.shared.canOpenURL(url) {
               UIApplication.shared.open(url)
           } else if let url = URL(string: "https://www.google.com/maps/dir/?daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving") {
               UIApplication.shared.open(url)
           }
       }
       
       private func openAppleMaps(coordinate: CLLocationCoordinate2D) {
           let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
           mapItem.name = "Mimo"
           mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
       }
    
    @ViewBuilder
    var selectedMediaOverlay: some View {
        if let selectedLogoIcon = viewModel.selectedLogoIconURL {
            overlayBackground {
                ZoomableImageView(url: selectedLogoIcon, width: viewModel.cardWidth, height: 300)
            }
        } else if let medias = viewModel.station?.images,
                  let selectedMediaIcon = viewModel.selectedMediaIcon,
                  !medias.isEmpty {
            overlayBackground {
                PagingView(
                    config: .init(
                        direction: .horizontal,
                        margin: (UIScreen.screenWidth - viewModel.cardWidth) / 2,
                        spacing: 16
                    ),
                    page: Binding(
                        get: { selectedMediaIcon },
                        set: { index in viewModel.selectedMediaIcon = index }
                    )
                ) {
                    ForEach(medias, id: \.self) { mediaIcon in
                        ZoomableImageView(url: mediaIcon, width: viewModel.cardWidth, height: 300)
                    }
                }
                .frame(height: 300)
            }
        }
    }

    @ViewBuilder
    private func overlayBackground<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Group {
            Color.black
                .opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    viewModel.selectedMediaIcon = nil
                    viewModel.selectedLogoIconURL = nil
                }
                .overlay(alignment: .topLeading) {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.white)
                        .padding()
                        .onTapGesture {
                            viewModel.selectedMediaIcon = nil
                            viewModel.selectedLogoIconURL = nil
                        }
                }
            content()
        }
    }
    
    var balanceView: some View {
        HStack(spacing: 16) {
//            Group {
//                HStack(alignment: .center) {
//                    Spacer()
//                    
//                    VStack(alignment: .leading, spacing: 2) {
//                        Text("Free minutes")
//                            .font(.robotoLight12)
//                            .foregroundColor(Color.evText6)
//                        
//                        HStack(spacing: 6) {
//                            Text(viewModel.freeMinutes)
//                                .font(.robotoBold20)
//                                .foregroundColor(Color.evText9)
//                            
//                            Text("Min")
//                                .font(.robotoLight13)
//                                .foregroundColor(Color.evText9)
//                        }
//                    }
//                    Spacer()
//                }
//            }
//            
//            Divider()
//                .frame(width: 1, height: 40)
            
            Group {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("MOBILE_mimo_balance".localized())
                            .font(.robotoLight12)
                            .foregroundColor(Color.evText6)
                        
                        HStack(spacing: 6) {
                            Text(viewModel.balance)
                                .font(.robotoBold20)
                                .foregroundColor(Color.evText9)
                            
                            Text(viewModel.currency)
                                .font(.robotoLight13)
                                .foregroundColor(Color.evText9)
                        }
                    }
//                    Spacer()
                    
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        showWalletScreen = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(Color.white)
                            .frame(width: 40, height: 40)
                    }
                    .background(Color.evbrandCyan80)
                    .clipShape(Circle())
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func detailsView(_ station: EVChargingStation) -> some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(spacing: 16) {
                
                KFImage(station.logo)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: 120, height: 120)
                    .padding(.leading, 8)
                    .onTapGesture {
                        viewModel.selectedLogoIconURL = station.logo
                    }
                
//                HStack(spacing: 3) {
//                    Image("ic_qr")
//                        .font(.system(size: 16, weight: .medium))
//                    
//                    Text(String(station.id.suffix(4)))
//                        .font(.system(size: 18, weight: .semibold))
//                }
//                .padding(.horizontal, 6)
//                .padding(.vertical, 2)
//                .background(
//                    Capsule()
//                        .fill(Color.white)
//                )
//                .overlay(
//                    Capsule()
//                        .stroke(Color.evGray8, lineWidth: 2)
//                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(station.destinationName)
                    .font(.robotoSemibold20)
                    .foregroundColor(Color.evText9)

                HStack(spacing: 2) {
                    Image("review_flash")
                    Text(String(format: "%.1f", station.rating ?? 0))
                        .font(.robotoMedium14)
                        .foregroundColor(Color.evText8)
                    Text("(\(viewModel.feedbacks.count) " + "EV_CHARGER_reviews".localized() + ")")
                        .font(.robotoRegular14)
                        .foregroundColor(Color.evText6)
                }

                HStack(spacing: 6) {
                    Image("ev_location_marker")
                        .foregroundColor(Color.evText8)
                    Text(station.destinationAddress)
                        .font(.robotoRegular14)
                        .foregroundColor(Color.evText8)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)

                    Image("ev_map_navigator")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
                .onTapGesture {
                    showDialog = true
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                }

                HStack(spacing: 6) {
                    Image("ev_distance")
                        .foregroundColor(Color.evText8)
                    Text(viewModel.distance)
                        .font(.robotoRegular14)
                        .foregroundColor(Color.evText8)
                }

                HStack(spacing: 6) {
                    Image("ev_clock")
                        .foregroundColor(Color.evSuccess)
                    Text(station.workingHours)
                        .font(.robotoRegular14)
                        .foregroundColor(Color.evSuccess)
                }
                
                HStack(spacing: 12) {
                    if let instagram = station.instagramUrl,
                       let instagramURL = URL(string: instagram) {
                        Button {
                            openURL(instagramURL)
                        } label: {
                            Image("instagram_logo")
                        }
                        .frame(width: 24, height: 24)
                    }
                    
                    if let facebook = station.facebookUrl,
                       let facebookURL = URL(string: facebook)  {
                        Button {
                            openURL(facebookURL)
                        } label: {
                            Image("facebook_logo")
                        }
                        .frame(width: 24, height: 24)
                    }
                }
            }
        }
        .padding(.horizontal, 16)

    }
    
    @ViewBuilder
    private func mediaView(_ mediasURL: [URL]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHGrid(rows: [GridItem(.fixed(100), spacing: 6)]) {
                ForEach(Array(mediasURL.enumerated()), id: \.element) { index, mediaURL in
                    KFImage(mediaURL)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .onTapGesture {
                            viewModel.selectedMediaIcon = index
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                        }
                }
            }
            .padding(.horizontal, 16)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    @State private var selectedPage: Int = 0
    
    @ViewBuilder
    private func tabsView() -> some View {
        TabSegmentedControl(selected: $selectedPage, pages: [
            ("EV_CHARGER_connectors".localized(), AnyView(connectorList(groups: viewModel.station?.stationGroups ?? []))),
            ("EV_CHARGER_info".localized(), AnyView(infoView(amenities: viewModel.station?.amenities ?? []))),
            ("EV_CHARGER_reviews".localized(), AnyView(reviewsList(reviews: viewModel.feedbacks)))
        ])
    }
    
    @ViewBuilder
    private func infoView(amenities: [String]) -> some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            Text("EV_CHARGER_ammenities".localized())
                .font(.robotoMedium12)
                .foregroundColor(Color.evText8)
            
            Text("EV_CHARGER_ammenities_description".localized())
                .font(.robotoLight14)
                .foregroundColor(Color.evText8)
            
            ForEach(amenities, id: \.self) { amenity in
                HStack(alignment: .center, spacing: 0) {
                    Circle()
                        .fill(Color.evText8)
                        .frame(width: 2, height: 2)
                        .padding(.horizontal, 10)
                    Text(amenity)
                        .font(.robotoRegular14)
                        .foregroundColor(Color.evText8)
                }
            }
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func connectorList(groups: [EVStationGroup]) -> some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            ForEach(groups) { group in
                VStack(alignment: .leading, spacing: 8) {
                    
                    HStack {
                        Text("EV_CHARGER_station".localized())
                            .font(.robotoMedium14)
                            .font(.system(size: 18, weight: .semibold))
                        
                        HStack(spacing: 3) {
                            Image("ic_qr")
                                .font(.system(size: 16, weight: .medium))
                            
                            Text(group.id.dropFirst(4))
                                .font(.robotoMedium14)
                                .font(.system(size: 18, weight: .semibold))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.white)
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.evGray8, lineWidth: 2)
                        )
                    }

                    ForEach(Array(group.connectors.enumerated()), id: \.offset) { _, connector in
                        EVConnectorCardView(connector: connector)
                            .onTapGesture {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                    generator.impactOccurred()
                                viewModel.connectorTapped(connector: connector)
                            }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    @ViewBuilder
    private func reviewsList(reviews: [EVStationFeedback]) -> some View {
        if reviews.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("EV_CHARGER_no_reviews".localized())
                    .font(.robotoMedium12)
                    .foregroundColor(Color.evText8)
                
                Text("EV_CHARGER_no_reviews_description".localized())
                    .font(.robotoLight14)
                    .foregroundColor(Color.evText8)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
        } else {
            LazyVStack(alignment: .leading, spacing: 8) {
                Text("\(reviews.count) " + "EV_CHARGER_reviews".localized())
                    .font(.robotoMedium12)
                    .foregroundColor(Color.evText8)
                
                ForEach(reviews) { review in
                    reviewCard(review: review)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private func reviewCard(review: EVStationFeedback) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                EVRatingView(maxRating: 5, rating: review.rating)
                
                Spacer()
                
                Text("2 days ago")
                    .font(.robotoRegular12)
                    .foregroundColor(Color.evText6)
            }
            
            if let comment = review.comment {
                Text(comment)
                    .font(.robotoMedium14)
                    .foregroundColor(Color.evText9)
            }
            
            HStack(spacing: 8) {
                Text(review.author)
                    .font(.robotoRegular12)
                    .foregroundColor(Color.evText6)
                
                Circle()
                    .frame(width: 2, height: 2)
                    .foregroundColor(Color.evStroke)
                
                Text("Type 2")
                    .font(.robotoRegular12)
                    .foregroundColor(Color.evText6)
                
                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.evStroke, lineWidth: 1)
        )
    }
}

struct EVConnectorCardView: View {
    let connector: EVChargingConnector
    
    var body: some View {
        HStack(spacing: 12) {
            leftView
            centerView
            rightView
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background {
            RoundedRectangle(cornerRadius: 16)
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
                .frame(width: 26, height: 26)
        }
    }
    
    private var centerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("EV_CHARGER_connector".localized() + " N\(connector.id)")
                    .font(.robotoMedium13)
            }
            HStack {
                Text(connector.power.stringValue + " " + "EV_CHARGER_kw".localized())
                    .font(.robotoMedium13)
                    .foregroundColor(.evGray12)
                
                Text("|")
                    .font(.robotoRegular12)
                    .foregroundColor(.evGray12)
                
                Text("\(connector.pricePerKW.description) AMD/KW")
                    .font(.robotoRegular12)
                    .foregroundColor(.evGray8)
            }
            HStack {
                ForEach(connector.adapters, id: \.self) { adapter in
                    HStack(spacing: 4) {
                        Image(adapter.iconName)
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 16, height: 16)
                        
                        Text(adapter.title)
                            .font(.robotoBold12)
                    }
                }
                
                if !connector.adapters.contains(where: { $0 == connector.type }) {
                    HStack(spacing: 4) {
                        Image(connector.type.iconName)
                            .resizable()
                            .foregroundColor(.gray)
                            .frame(width: 16, height: 16)
                        
                        Text(connector.type.title)
                            .font(.robotoBold12)
                    }
                }
                
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
        
    private var rightView: some View {
        VStack(alignment: .trailing, spacing: 8) {
            stateView
            
            if let percent = connector.percent {
                Text(String(percent) + " %")
                    .font(.robotoRegular15)
                    .foregroundColor(.evGray12)
            }
        }
    }
    
    private var stateView: some View {
        var state: String
        var bgColor: Color
        var textColor: Color
        
        switch connector.state {
        case .available:
            state = "EV_CHARGER_connector_state_available".localized()
            bgColor = Color(hex: "AFF4C6")
            textColor = Color(hex: "02542D")
        case .preparing:
            state = "EV_CHARGER_connector_state_preparing".localized()
            bgColor = Color(hex: "FFE8A3")
            textColor = Color(hex: "682D03")
        case .charging:
            state = "EV_CHARGER_connector_state_charging".localized()
            bgColor = Color(hex: "FFE8A3")
            textColor = Color(hex: "682D03")
        case .finishing:
            state = "EV_CHARGER_connector_state_finishing".localized()
            bgColor = Color(hex: "FFE8A3")
            textColor = Color(hex: "682D03")
        case .suspendedEvse, .suspendedEv:
            state = "EV_CHARGER_connector_state_suspended".localized()
            bgColor = Color(hex: "FFE8A3")
            textColor = Color(hex: "682D03")
        case .reserved, .unavailable, .faulted:
            state = "EV_CHARGER_connector_state_unavailable".localized()
            bgColor = Color(hex: "E0E0E0")
            textColor = Color(hex: "404040")
        }
        
        return Text(state)
            .font(.robotoMedium12)
            .foregroundColor(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(bgColor)
            )
    }
}

struct ZoomableImageView: View {
    let url: URL?
    let width: CGFloat
    let height: CGFloat

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        let isZoomed = scale > 1.0

        return KFImage(url)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .frame(width: width, height: height)
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = max(1.0, min(lastScale * value, 5.0))
                    }
                    .onEnded { _ in
                        lastScale = scale
                        if scale <= 1.0 {
                            withAnimation { offset = .zero }
                            lastOffset = .zero
                        }
                    }
            )
            .gesture(
                isZoomed
                    ? DragGesture()
                        .onChanged { value in
                            offset = CGSize(
                                width: lastOffset.width + value.translation.width,
                                height: lastOffset.height + value.translation.height
                            )
                        }
                        .onEnded { _ in
                            lastOffset = offset
                        }
                    : nil
            )
            .onTapGesture(count: 2) {
                withAnimation {
                    if scale > 1.0 {
                        scale = 1.0
                        lastScale = 1.0
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        scale = 2.0
                        lastScale = 2.0
                    }
                }
            }
    }
}
