//
//  UIColorExtension.swift
//  FittedSheetsPod
//
//  Created by Gordon Tucker on 7/29/20.
//  Copyright © 2020 Gordon Tucker. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

extension UIColor {
    convenience init(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat,
        alpha: CGFloat = 1,
        darkRed: CGFloat,
        darkGreen: CGFloat,
        darkBlue: CGFloat,
        darkAlpha: CGFloat = 1
    ) {
        self.init { (traits) -> UIColor in
            switch traits.userInterfaceStyle {
            case .dark:
                return UIColor(red: darkRed, green: darkGreen, blue: darkBlue, alpha: darkAlpha)
            default:
                return UIColor(red: red, green: green, blue: blue, alpha: alpha)
            }
        }
    }
    
    convenience init(
        white: CGFloat,
        alpha: CGFloat = 1,
        black: CGFloat,
        darkAlpha: CGFloat = 1
    ) {
        self.init { (traits) -> UIColor in
            switch traits.userInterfaceStyle {
            case .dark:
                return UIColor(white: black, alpha: darkAlpha)
            default:
                return UIColor(white: white, alpha: alpha)
            }
        }
    }
    
    convenience init(
        light: UIColor,
        dark: UIColor
    ) {
        self.init { (traits) -> UIColor in
            switch traits.userInterfaceStyle {
            case .dark:
                return light
            default:
                return dark
            }
        }
    }
}

#endif // os(iOS) || os(tvOS) || os(watchOS)
