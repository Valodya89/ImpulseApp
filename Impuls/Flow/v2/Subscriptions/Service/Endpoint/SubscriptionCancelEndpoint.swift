//
//  SubscriptionCancelEndpoint.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 29.06.24.
//

import Foundation

struct SubscriptionCancelEndpoint: Endpointable {
    var baseURL: String { MimoBaseURLs.accounts.rawValue }
    var path: String { "api/subscription-plan/cancel" }
    var method: HTTPMethod { .patch }
    
    let id: String
}
