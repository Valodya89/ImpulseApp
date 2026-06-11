//
//  BatteryLvl.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/18/22.
//

import Foundation

public struct BatteryLvl: Codable {
    
    // MARK: Properties
    public let voltage: Double?
    public let percent: Int?
    public let date: Int?

    // MARK: CodingKeys
    enum CodingKeys: String, CodingKey {
        case voltage = "voltage"
        case percent = "percent"
        case date = "date"
    }

    // MARK: Initialization
    public init(voltage: Double?, percent: Int?, date: Int?) {
        self.voltage = voltage
        self.percent = percent
        self.date = date
    }
}
