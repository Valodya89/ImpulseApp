//
//  GlobalSettings.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/14/21.
//

import Foundation

struct GlobalSettings: Decodable {
    static var settings: GlobalSettings?
    
    let id: String?
    let kcal: Int?
    let tree: Int?
    let iosVersion: String?
    let androidVersion: String?
    let supportPhone: String?
    let howToUserUrl: String?
    let termsUrl: String?

    enum CodingKeys: String, CodingKey {
        case id
        case kcal
        case tree
        case iosVersion
        case androidVersion
        case supportPhone
        case howToUserUrl
        case termsUrl
    }
}
