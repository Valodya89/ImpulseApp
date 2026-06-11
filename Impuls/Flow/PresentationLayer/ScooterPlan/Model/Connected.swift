//
//  Connected.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/18/22.
//

import Foundation

public struct Connected: Codable {
    
    // MARK: Properties
    public let online: Bool?
    public let date: Int?

    // MARK: CodingKeys
    enum CodingKeys: String, CodingKey {
        case online = "online"
        case date = "date"
    }

    // MARK: Initialization
    public init(online: Bool?, date: Int?) {
        self.online = online
        self.date = date
    }
}
