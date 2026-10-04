//
//  UserGender.swift
//  MimoBike
//
//  Created by Albert on 22.05.21.
//

import Foundation

/// Impulse offers only male and female when a gender is picked (product
/// decision 2026-10-04). The accounts service still knows OTHER, so a profile
/// that already has it keeps showing and saving it unchanged; the value is
/// just never offered to a rider who picks anew.
enum UserGender: String {
    case male = "MOBILE_registartion_sex_bottom_sheet_male"
    case female = "MOBILE_registartion_sex_bottom_sheet_female"
    case other = "MOBILE_registartion_sex_bottom_sheet_other"

    /// Value of the accounts `Gender` enum (`PUT /api/user`).
    var key: String {
        switch self {
        case .male:
            return "MALE"
        case .female:
            return "FEMALE"
        case .other:
            return "OTHER"
        }
    }

    var title: String {
        switch self {
        case .male, .female:
            return rawValue.localized()
        case .other:
            return rawValue.localized(fallback: "Other")
        }
    }

    init?(backendValue: String?) {
        switch backendValue?.uppercased() {
        case "MALE": self = .male
        case "FEMALE": self = .female
        case "OTHER": self = .other
        default: return nil
        }
    }

    /// What the gender picker offers: male and female, plus OTHER only when
    /// the profile already carries it, so that profile still renders and saves.
    static func options(keeping current: UserGender? = nil) -> [UserGender] {
        var options: [UserGender] = [.male, .female]
        if current == .other {
            options.append(.other)
        }
        return options
    }
}
