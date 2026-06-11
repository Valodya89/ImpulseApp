//
//  Font.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.09.23.
//

import Foundation
import SwiftUI

fileprivate enum FontType: String {
    case robotoLight = "Roboto-Light"
    case robotoRegular = "Roboto-Regular"
    case robotoBold = "Roboto-Bold"
    case robotoMedium = "Roboto-Medium"
    case robotoSemibold = "Roboto-Semibold"
}

extension Font {
    static var robotoLight12: Font = Font.custom(FontType.robotoLight.rawValue, size: 12)
    static var robotoLight13: Font = Font.custom(FontType.robotoLight.rawValue, size: 13)
    static var robotoLight14: Font = Font.custom(FontType.robotoLight.rawValue, size: 14)
    static var robotoLight36: Font = Font.custom(FontType.robotoLight.rawValue, size: 36)
    
    static var robotoRegular12: Font = Font.custom(FontType.robotoRegular.rawValue, size: 12)
    static var robotoRegular14: Font = Font.custom(FontType.robotoRegular.rawValue, size: 14)
    static var robotoRegular15: Font = Font.custom(FontType.robotoRegular.rawValue, size: 15)
    static var robotoRegular16: Font = Font.custom(FontType.robotoRegular.rawValue, size: 16)
    static var robotoRegular17: Font = Font.custom(FontType.robotoRegular.rawValue, size: 17)
    static var robotoRegular20: Font = Font.custom(FontType.robotoRegular.rawValue, size: 20)
    static var robotoRegular24: Font = Font.custom(FontType.robotoRegular.rawValue, size: 24)
    
    static var robotoSemibold14: Font = Font.custom(FontType.robotoSemibold.rawValue, size: 14)
    static var robotoSemibold16: Font = Font.custom(FontType.robotoSemibold.rawValue, size: 16)
    static var robotoSemibold20: Font = Font.custom(FontType.robotoSemibold.rawValue, size: 20)
    static var robotoSemibold40: Font = Font.custom(FontType.robotoSemibold.rawValue, size: 40)
    
    static var robotoBold12: Font = Font.custom(FontType.robotoBold.rawValue, size: 12)
    static var robotoBold14: Font = Font.custom(FontType.robotoBold.rawValue, size: 14)
    static var robotoBold15: Font = Font.custom(FontType.robotoBold.rawValue, size: 15)
    static var robotoBold16: Font = Font.custom(FontType.robotoBold.rawValue, size: 16)
    static var robotoBold17: Font = Font.custom(FontType.robotoBold.rawValue, size: 17)
    static var robotoBold20: Font = Font.custom(FontType.robotoBold.rawValue, size: 20)
    static var robotoBold24: Font = Font.custom(FontType.robotoBold.rawValue, size: 24)
    static var robotoBold32: Font = Font.custom(FontType.robotoBold.rawValue, size: 32)
    static var robotoBold36: Font = Font.custom(FontType.robotoBold.rawValue, size: 36)
    
    static var robotoMedium8: Font = Font.custom(FontType.robotoMedium.rawValue, size: 8)
    static var robotoMedium10: Font = Font.custom(FontType.robotoMedium.rawValue, size: 10)
    static var robotoMedium12: Font = Font.custom(FontType.robotoMedium.rawValue, size: 12)
    static var robotoMedium13: Font = Font.custom(FontType.robotoMedium.rawValue, size: 13)
    static var robotoMedium14: Font = Font.custom(FontType.robotoMedium.rawValue, size: 14)
    static var robotoMedium15: Font = Font.custom(FontType.robotoMedium.rawValue, size: 15)
    static var robotoMedium16: Font = Font.custom(FontType.robotoMedium.rawValue, size: 16)
    static var robotoMedium17: Font = Font.custom(FontType.robotoMedium.rawValue, size: 17)
    static var robotoMedium18: Font = Font.custom(FontType.robotoMedium.rawValue, size: 18)
    static var robotoMedium20: Font = Font.custom(FontType.robotoMedium.rawValue, size: 20)
    static var robotoMedium24: Font = Font.custom(FontType.robotoMedium.rawValue, size: 24)
}
