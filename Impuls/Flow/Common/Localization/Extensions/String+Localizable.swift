//
//  String+Localizable.swift
//  hay
//
//  Created by Vardan Gevorgyan on 2/10/20.
//  Copyright © 2020 Sedrak Igityan. All rights reserved.
//

import Foundation
import UIKit

// MARK: - Localized String -

/// String extension for localizable functionality
extension String {
    var storageManager: StorageManager {
        return .init()
    }
    
    /// Use this method to localize string
    func localized() -> String {
//        return LocalizationModel.shared?.getText(for: self) ?? self
        return Mimo.Localization.localizations[self] ?? self
    }
    
    /// Use this method to get key from value
    func getKey() -> String {
//        let keyString = LocalizationModel.shared?.getKey(from: self)
        
        /// Get key from value
//        return keyString ?? self
        
        return Mimo.Localization.localizations.first(where: { $0.value == self })?.key ?? self
    }
    
    func hexStringToUIColor () -> UIColor {
        var cString:String = self.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
}

extension Locale {
    var deviceLanguageCode: String {
        if #available(iOS 16, *) {
            return language.languageCode?.identifier ?? "am"
        } else {
            return languageCode ?? "am"
        }
    }
}
