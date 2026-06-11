//
//  ProfileSettingsRows.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 15.04.24.
//

import Foundation

enum ProfileSettingsRows: CaseIterable, Identifiable {
    
    var id: Self { self }
    
    case history
//    case rate
    case howToUse
    case settings
    case partnership
    case privacy
    case terms
    case support
    case logOut
    case deleteAccount
    
    var name: String {
        switch self {
        case .history:
            return "MOBILE_profile_history".localized()
//        case .rate:
//            return "MOBILE_profile_rate".localized()
//            return "Rate"
        case .support:
            return "MOBILE_profile_support".localized()
        case .howToUse:
            return "MOBILE_profile_how_to_use".localized()
        case .settings:
            return "MOBILE_profile_settings".localized()
        case .partnership:
            return "MOBILE_profile_partnership".localized()
        case .privacy:
            return "MOBILE_profile_privacy_and_policy".localized()
        case .terms:
            return "MOBILE_profile_agreement".localized()
        case .logOut:
            return "MOBILE_profile_log_out".localized()
        case .deleteAccount:
            return "MOBILE_profile_delete".localized()
        }
    }
    
    var icon: String {
        switch self {
        case .history:
            return "profile_history"
//        case .rate:
//            return "profile_history"
        case .support:
            return "profile_support"
        case .howToUse:
            return "profile_info"
        case .settings:
            return "profile_settings"
        case .partnership:
            return "profile_partnership"
        case .privacy:
            return "profile_privacy_policy"
        case .terms:
            return "profile_mimo_agreement"
        case .logOut:
            return "profile_logout"
        case .deleteAccount:
            return "profile_delete"
        }
    }
    
    var isDestuctive: Bool {
        return self == .logOut || self == .deleteAccount
    }
}
