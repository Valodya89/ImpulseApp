//
//  EVChargerRentModel.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 8/3/25.
//

import Foundation

struct EVChargerRentModel: Decodable {
    let stationId: String
    let connectorType: EVConnectorType?
    let destinationName: String?
    let start: Int
    let end: Int
    let price: Price?
    let destinationAddress: String?
    let kwtsCharged: Double
    
    struct Price: Decodable {
        let currency: String
        let amount: Double
    }
}

extension EVChargerRentModel {
    
    func toViewMOdel() -> EVChargerRentViewModel {
        return EVChargerRentViewModel(
            id: UUID(),
            stationId: self.stationId,
            start: self.start,
            end: self.end,
            currency: self.price?.currency ?? "",
            amount: self.price?.amount ?? 0,
            destinationName: self.destinationName,
            destinationAddress: self.destinationAddress,
            connectorType: self.connectorType,
            kwtsCharged: self.kwtsCharged
        )
    }
}

struct EVChargerRentViewModel {
    let id: UUID
    let stationId: String
    let start: Int
    let end: Int
    let currency: String
    let amount: Double
    let destinationName: String?
    let destinationAddress: String?
    let connectorType: EVConnectorType?
    let kwtsCharged: Double
    
    var formatedStartDate: String {
        DateFormatter.hoursMinutesFormatter.string(from: Date(timeIntervalSince1970: TimeInterval(start)))
    }
    
    var minutesBetweenDates: String {
        let startDate = Date(timeIntervalSince1970: TimeInterval(start) / 1000.0)
        let endDate = Date(timeIntervalSince1970: TimeInterval(end) / 1000.0)

        // Calculate total minutes
        let totalMinutes = Int(endDate.timeIntervalSince(startDate) / 60)

        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        let formattedDuration: String
        if hours > 0 && minutes > 0 {
            formattedDuration = "\(hours)h \(minutes)m"
        } else if hours > 0 {
            formattedDuration = "\(hours)h"
        } else {
            formattedDuration = "\(minutes)m"
        }

        return formattedDuration
    }
}
