//
//  AccountMapper.swift
//  MimoBike
//
//  Created by Albert on 21.05.21.
//

import Foundation

final class AccountMapper {
    
    static func toUserResult(from response: UserResponse) -> UserResult {
        
        var userResult = UserResult(userResponse: response)
        userResult.name = response.name ?? ""
        userResult.surname = response.surname ?? ""
        userResult.gender = response.gender ?? ""
        userResult.email = response.email ?? ""
        userResult.emailVerified = response.emailVerified ?? false
        userResult.bio = response.bio ?? ""
        userResult.birthday = response.birthday ?? ""
        userResult.status = response.status ?? ""
        userResult.avatar = AvatarResult(id: response.avatar?.id ?? "", node: response.avatar?.node ?? "")
        userResult.distance = response.distance ?? 0
        userResult.minutes = response.minutes ?? 0
        return userResult
    }
}
