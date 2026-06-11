//
//  UserResponse.swift
//  MimoBike
//
//  Created by Albert on 19.05.21.
//

import Foundation

enum AppThemeMode: String, Codable {
    case dark = "DARK"
    case light = "LIGHT"
}

struct UserResponse: Decodable {
    let name: String?
    let surname: String?
    let gender: String?
    let email: String?
    let birthday: String?
    let status: String?
    let distance: Double?
    let minutes: Double?
    let bio: String?
    let avatar: AvatarResponse?
    var emailVerified: Bool?
    let package: ActivePackage?
    let tariff: ActiveTarrif?
    let lastActionDate: Double?
    var settings: SettingsModel?
    let activePlan: ActiveSubscriptionPlan?
    var services: [String]?

    struct SettingsModel: Codable {
        var locale: String?
        var sendPush: Bool?
        var mode: AppThemeMode?
        
        func toDictionary() -> [String: Any] {
            return ["locale": locale ?? "en", "sendPush": sendPush ?? true, "mode": mode?.rawValue ?? AppThemeMode.light.rawValue]
        }
    }
    
    var isAccountComplated: Bool {
        return name != nil && surname != nil && gender != nil && birthday != nil
    }
}

struct AvatarResponse: Decodable {
    let id: String?
    let node: String?
    
    func getURL() -> URL? {
        guard let token = KeychainManager().getAccessToken(), let node = node, let id = id else { return nil }
        var avatar = "https://\(node).impulsepower.ru/files?id=\(id)&token=\(token)"
        print("avatar url = \(avatar)")
        return URL(string: avatar)
    }
}
