//
//  UserEndpoint.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.06.24.
//

import Foundation

struct UserEndpoint: Endpointable {
    var baseURL: String { MimoBaseURLs.accounts.rawValue }
    var path: String { "api/user" }
    var method: HTTPMethod { .get }
}
