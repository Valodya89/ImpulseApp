//
//  ProductItemViewModel.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 04.07.25.
//

import SwiftUI

class ProductItemViewModel: ObservableObject {
    
    private let productType: MimoProductType
    let value: String
    let valueLabel: String
    
    var image: String {
        "productItem.\(productType.service)"
    }
    
    var text: String {
        "productItem.\(productType.service)".localized()
    }
    
    init(productType: MimoProductType,
         value: String,
         valueLabel: String
     ) {
         self.productType = productType
         self.value = value
         self.valueLabel = valueLabel
     }
}
