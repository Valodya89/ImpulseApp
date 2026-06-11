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
    
    var key: String {
        switch self {
        case .male:
            return "MALE"
        case .female:
            return "FEMALE"
        }
    }
}
