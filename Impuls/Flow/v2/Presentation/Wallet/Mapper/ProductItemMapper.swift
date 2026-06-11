//
//  ProductItemMapper.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 05.07.25.
//

import Foundation

enum ProductItemMapper {
    static func mapProductItems(productType: MimoProductType?) -> [ProductItemViewModel] {
        var productItemViewModels: [ProductItemViewModel]  = []
        if let item = productType {
            productItemViewModels.append(ProductItemViewModel(productType: item, value: "10", valueLabel: "Minutes"))
        } else {
            for index in 0..<MimoProductType.allCases.count {
                let item = MimoProductType.allCases[index]
                productItemViewModels.append(ProductItemViewModel(productType: item, value: "10", valueLabel: "Minutes"))
            }
        }
        return productItemViewModels
    }
}
