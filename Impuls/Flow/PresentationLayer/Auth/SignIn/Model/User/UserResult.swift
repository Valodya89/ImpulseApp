//
//  UserResult.swift
//  MimoBike
//
//  Created by Albert on 21.05.21.
//

import Foundation

struct UserResult {
    var name = ""
    var surname = ""
    var gender = ""
    var email = ""
    var birthday = ""
    var status = ""
    var distance: Double = 0
    var minutes: Double = 0.0
    var bio = ""
    var avatar: AvatarResult?
    var emailVerified: Bool? = false
    
    init(userResponse: UserResponse?) {
        self.name = userResponse?.name ?? ""
        self.surname = userResponse?.surname ?? ""
        self.gender = userResponse?.gender ?? ""
        self.email = userResponse?.email ?? ""
        self.birthday = userResponse?.birthday ?? ""
        self.status = userResponse?.status ?? ""
        self.distance = userResponse?.distance ?? 0.0
        self.minutes = userResponse?.minutes ?? 0.0
        self.bio = userResponse?.bio ?? ""
        self.avatar = AvatarResult(id: userResponse?.avatar?.id ?? "", node: userResponse?.avatar?.node ?? "")
        self.emailVerified = userResponse?.emailVerified ?? false
    }
}

struct AvatarResult: Decodable {
    let id: String?
    let node: String?
    
    func getURL() -> URL? {
        guard let token = KeychainManager().getAccessToken(), let node = node, let id = id else { return nil }
        
        let avatar = "https://\(node).impulsepower.ru/files?id=\(id)&token=\(token)"

        return URL(string: avatar)
    }
}
