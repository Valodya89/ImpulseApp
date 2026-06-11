//
//  ChargerDiscount.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 12.03.24.
//

import Foundation

struct ChargerDiscount {
    var title: String
    var description: String
    var icon: UIImage?
}

extension ChargerDiscount {
    
    static var staticData: [ChargerDiscount] {
        var data: [ChargerDiscount] = []
        
        data.append(ChargerDiscount(
            title: "MOBILE_charger_discount_free_title".localized(),
            description: "MOBILE_charger_discount_free_description".localized(),
            icon: "charger_discount_free".image)
        )
        
        data.append(ChargerDiscount(
            title: "MOBILE_charger_discount_50_title".localized(),
            description: "MOBILE_charger_discount_50_description".localized(),
            icon: "charger_discount_50".image)
        )
        
        data.append(ChargerDiscount(
            title: "MOBILE_charger_discount_20_title".localized(),
            description: "MOBILE_charger_discount_20_description".localized(),
            icon: "charger_discount_20".image)
        )
        
        return data
    }
}
