//
//  UserGender.swift
//  MimoBike
//
//  Created by Albert on 22.05.21.
//

import Foundation

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

    /// What the gender picker offers. The accounts service accepts OTHER
    /// everywhere, so it is always on the list; a rider who already has it
    /// stored keeps seeing it.
    static func options(keeping current: UserGender? = nil) -> [UserGender] {
        [.male, .female, .other]
    }
}
