//
//  ScooterScanResponse.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 29.07.22.
//

import Foundation

struct ScooterScanResponse: Codable {
    let state:  String?
    let scooter: ScanedScooter?
    let data: ScanData?
}


struct ScanedScooter: Codable {
    let id: String?
    let qr: String?
    let type:  String?
    let located: LocatedData?
    let batteryPercent: Int?
    let remainingMileage:  Int?
    let speed: Int?
}

struct ScanData: Codable {
    let id: String?
    let state: String?
    let scan: Double?
    let start: Double?
    let end: Double?
    let speedModeTariff: SpeedModeTariff?
    let billingModeTariff: BillingModeTariff?
    let user: String?
    let scooter: String?
    let startPosition: LocatedData?
    let endPosition: Int?
    let startMileage: Int?
    let endMileage: Int?
    let distance: Int?
    let amount: Double?
    let pauses: [[Double]]?
    let path: [[Double]]?
}

