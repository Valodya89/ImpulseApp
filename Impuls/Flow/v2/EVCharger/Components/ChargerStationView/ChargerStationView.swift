//
//  ChargerStationView.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 05.02.25.
//

import SwiftUI
import Kingfisher

struct ChargerStationView: View {
    let station: EVChargingStation
    let distance: String
    
    var chooseButtonTitle: String = "CHARGER_choose".localized()
    var chooseAction: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 7) {
                KFImage(station.logo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 12) {
                    Text(station.destinationName)
                        .font(.robotoBold16)
                        .foregroundColor(Color.evGray8)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 3) {
                            
                            Image("ic_qr")
                                .font(.system(size: 13, weight: .medium))
                            
                            Text(String(station.id))
                                .font(.system(size: 14, weight: .semibold))
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
                        HStack(spacing: 6) {
                            Image("ev_location_marker")
                                .foregroundColor(Color.evGray8)
                            
                            Text(station.destinationAddress)
                                .font(.robotoBold14)
                                .foregroundColor(Color.evGray8)
                        }
                        
                        HStack(spacing: 3) {
                            Image("ev_distance")
                                .foregroundColor(Color.evGray8)

                            Text("\("MOBILE_global_distance".localized()): \(distance)")
                                .font(.robotoBold14)
                                .foregroundColor(Color.evGray8)
                        }
                    }
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(uniqueConnectorTypes, id: \.self) { type in
                        Text(type.title)
                            .font(.robotoBold14)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(isAvailable(type: type) ? Color.addresTypeGreen.clipShape(Capsule()) : Color.evGray4.clipShape(Capsule()))
                    }
                    Spacer(minLength: 0)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
//            .frame(maxWidth: .infinity)
//            .padding(.trailing, 10)
            
            HStack(spacing: 12) {
                Button {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    chooseAction?()
                } label: {
                    Text(chooseButtonTitle)
                        .font(.robotoBold15)
                        .foregroundColor(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(10)
                        .background(Color.evbrandCyan80)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(16)
        .background(Color.evBgColor4.cornerRadius(12))
    }

    private var uniqueConnectorTypes: [EVConnectorType] {
        var seen = Set<EVConnectorType>()
        var result: [EVConnectorType] = []
        for connector in station.connectors {
            if seen.insert(connector.type).inserted {
                result.append(connector.type)
            }
            for adapter in connector.adapters where seen.insert(adapter).inserted {
                result.append(adapter)
            }
        }
        return result
    }

    private func isAvailable(type: EVConnectorType) -> Bool {
        station.connectors.contains { connector in
            connector.state == .available && (connector.type == type || connector.adapters.contains(type))
        }
    }
}
