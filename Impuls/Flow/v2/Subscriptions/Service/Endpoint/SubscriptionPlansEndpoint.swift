//
//  SubscriptionPlansEndpoint.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.06.24.
//

import Foundation

struct SubscriptionPlansEndpoint: Endpointable {
    
    var baseURL: String { MimoBaseURLs.accounts.rawValue }
    var path: String { "api/subscription-plan/list" }
    
    var method: HTTPMethod { .get }
}
