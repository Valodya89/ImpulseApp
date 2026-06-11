//
//  SettingsDto.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.06.24.
//

import Foundation

struct SettingsDto: Decodable {
    var locale: String?
    var sendPush: Bool?
    var mode: String?
}
