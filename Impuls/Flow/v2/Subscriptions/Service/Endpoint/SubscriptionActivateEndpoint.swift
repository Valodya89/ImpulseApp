//
//  SubscriptionActivateEndpoint.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.06.24.
//

import Foundation

struct SubscriptionActivateEndpoint: Endpointable {
    
    var baseURL: String { MimoBaseURLs.accounts.rawValue }
    var path: String { "api/subscription-plan/\(id)/activate" }
    
    var method: HTTPMethod { .patch }
    
    let id: String
}
