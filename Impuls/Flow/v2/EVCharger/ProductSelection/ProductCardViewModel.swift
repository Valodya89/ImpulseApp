//
//  ProductCardViewModel.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/26/25.
//

import Foundation

struct ProductCardViewModel {
    var service: String
    var isSelected: Bool
    var imageName: String
    
    init(type: MimoProductType, isSelected: Bool = false) {
        var imageName: String
        
        switch type {
        case .scooter:
            imageName = "mimo_product_scooter"
        case .bike:
            imageName = "mimo_product_bike"
        case .charger:
            imageName = "mimo_product_charger"
        case .evCharger:
            imageName = "mimo_product_ev_charger"
        }
        
        self.init(service: type.service, imageName: imageName, isSelected: isSelected)
    }
    
    init(service: String, imageName: String, isSelected: Bool = false) {
        self.service = service
        self.imageName = imageName
        self.isSelected = isSelected
    }
}
