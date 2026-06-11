//
//  Located.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/18/22.
//

import Foundation

public struct Located: Codable {
    
    // MARK: Properties
    public let longitude: Double?
    public let latitude: Double?
    public let timestamp: Int?

    // MARK: CodingKeys
    enum CodingKeys: String, CodingKey {
        case longitude = "longitude"
        case latitude = "latitude"
        case timestamp = "timestamp"
    }

    // MARK: Initialization
    public init(longitude: Double?, latitude: Double?, timestamp: Int?) {
        self.longitude = longitude
        self.latitude = latitude
        self.timestamp = timestamp
    }
}
