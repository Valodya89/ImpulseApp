//
//  UserDto.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.06.24.
//

import Foundation

struct UserDto: Decodable {
    let name: String?
    let surname: String?
    let gender: String?
    let email: String?
    let birthday: String?
    let status: String?
    let distance: Double?
    let minutes: Double?
    let bio: String?
    let avatar: ImageDto?
    var emailVerified: Bool?
    let package: ActivePackage?
    let tariff: ActiveTarrif?
    let lastActionDate: Double?
    var settings: SettingsDto?
    let activePlan: ActiveSubscriptionPlan?
}

