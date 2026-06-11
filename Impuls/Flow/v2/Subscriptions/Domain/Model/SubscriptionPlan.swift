//
//  SubscriptionPlan.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.06.24.
//

import Foundation

struct SubscriptionPlan: Decodable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let duration: String
}
