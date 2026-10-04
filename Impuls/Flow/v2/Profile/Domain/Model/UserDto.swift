//
//  UserDto.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.06.24.
//

import Foundation

/// The accounts `UserDto` as the v2 profile reads it (accounts
/// docs/mobile-api.md "GET /api/user", "PUT /api/user", commit
/// eb41a3e925cf7da27bc5c6e59b4cf47a9eb6e2f4). Every field is optional and
/// decoded leniently: an omitted or `null` field is nil, a nested document in a
/// shape this build does not know is nil and reported once, never a failed
/// profile.
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
    /// Opted-in `SourceSystem` services (docs/overview.md "Main domain objects").
    var services: [String]?
    /// ISO alpha-3, stored at sign-up.
    let country: String?
    let address: AddressResponse?
}

extension UserDto {

    private enum CodingKeys: String, CodingKey {
        case name, surname, gender, email, birthday, status, distance, minutes, bio, avatar
        case emailVerified, package, tariff, lastActionDate, settings, activePlan, services
        case country, address
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let document = "UserDto"

        name = container.decodeLenient(String.self, forKey: .name, in: document)
        surname = container.decodeLenient(String.self, forKey: .surname, in: document)
        gender = container.decodeLenient(String.self, forKey: .gender, in: document)
        email = container.decodeLenient(String.self, forKey: .email, in: document)
        birthday = container.decodeLenient(String.self, forKey: .birthday, in: document)
        status = container.decodeLenient(String.self, forKey: .status, in: document)
        distance = container.decodeLenientDouble(forKey: .distance, in: document)
        minutes = container.decodeLenientDouble(forKey: .minutes, in: document)
        bio = container.decodeLenient(String.self, forKey: .bio, in: document)
        avatar = container.decodeLenient(ImageDto.self, forKey: .avatar, in: document)
        emailVerified = container.decodeLenient(Bool.self, forKey: .emailVerified, in: document)
        package = container.decodeLenient(ActivePackage.self, forKey: .package, in: document)
        tariff = container.decodeLenient(ActiveTarrif.self, forKey: .tariff, in: document)
        lastActionDate = container.decodeLenientDouble(forKey: .lastActionDate, in: document)
        settings = container.decodeLenient(SettingsDto.self, forKey: .settings, in: document)
        activePlan = container.decodeLenient(ActiveSubscriptionPlan.self, forKey: .activePlan, in: document)
        services = container.decodeLenient([String].self, forKey: .services, in: document)
        country = container.decodeLenient(String.self, forKey: .country, in: document)
        address = container.decodeLenient(AddressResponse.self, forKey: .address, in: document)
    }
}
