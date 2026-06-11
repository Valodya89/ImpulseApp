//
//  AppVersion.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 02.04.23.
//

import Foundation

struct AppVersion: Codable {

    let id: String?
    let version: String?
    let updatedDate: String?
    let osType: String?
    
    // MARK: CodingKeys
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case version = "version"
        case updatedDate = "updatedDate"
        case osType = "osType"
    }
}
