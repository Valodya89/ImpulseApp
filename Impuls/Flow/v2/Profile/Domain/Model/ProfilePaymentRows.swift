//
//  ProfilePaymentRows.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 14.04.24.
//

import Foundation

enum ProfilePaymentRows: CaseIterable, Identifiable {
    
    var id: Self {
        return self
    }
    
    case promoCode
    case subscriptions
    
    var name: String {
        switch self {
        case .promoCode:
            return "Activate Promo Code"
        case .subscriptions:
            return "MOBILE_subscriptions_row_title".localized()
        }
    }
    
    var icon: String {
        switch self {
        case .promoCode:
            return "profile_promoCode"
        case .subscriptions:
            return "profile_subscriptions"
        }
    }
}
