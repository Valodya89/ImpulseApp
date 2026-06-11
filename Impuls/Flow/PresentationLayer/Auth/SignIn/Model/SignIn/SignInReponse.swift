//
//  SignInReponse.swift
//  MimoBike
//
//  Created by Albert on 14.05.21.
//

import Foundation

struct SignInReponse: Decodable, UserToken {
    let user: UserResponse?
    let token: TokenResponse?
}
