//
//  ActiveSubscriptionPlan.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.06.24.
//

import Foundation

struct ActiveSubscriptionPlan: Decodable {
    let subscriptionPlanId: String
    let activeUntil: Int64
    let activatedAt: Int64
    let extendedAt: Int
    let cancelled: Bool
}
