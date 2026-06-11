//
//  BookedScooterResult.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/26/22.
//

import Foundation

public struct BookedScooterResult: Codable {
    public let id: String?
    public let scooter: String?
    public let user: String?
    public let start: Int?
    public let end: Int?
    public let bikeCoordinates: Coordinates?
    public let userCoordinates: Coordinates?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case scooter = "scooter"
        case user = "user"
        case start = "start"
        case end = "end"
        case bikeCoordinates = "bikeCoordinates"
        case userCoordinates = "userCoordinates"
    }

    public init(id: String?, scooter: String?, user: String?, start: Int?, end: Int?, bikeCoordinates: Coordinates?, userCoordinates: Coordinates?) {
        self.id = id
        self.scooter = scooter
        self.user = user
        self.start = start
        self.end = end
        self.bikeCoordinates = bikeCoordinates
        self.userCoordinates = userCoordinates
    }
}

// MARK: - Coordinates
public struct Coordinates: Codable {
    public let longitude: Double?
    public let latitude: Double?
    public let timestamp: Int?

    enum CodingKeys: String, CodingKey {
        case longitude = "longitude"
        case latitude = "latitude"
        case timestamp = "timestamp"
    }

    public init(longitude: Double?, latitude: Double?, timestamp: Int?) {
        self.longitude = longitude
        self.latitude = latitude
        self.timestamp = timestamp
    }
}
