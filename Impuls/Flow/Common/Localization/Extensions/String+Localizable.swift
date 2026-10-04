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
    
    /// The server-driven translation, or `fallback` when the key is not on the
    /// server yet (a bare key must never reach the screen).
    func localized(fallback: String) -> String {
        let value = localized()
        return value == self ? fallback : value
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

// MARK: - Plural forms -

/// The plural category a count falls into. The locale service serves flat
/// key/value strings with no plural rules and the bundle has no .stringsdict,
/// so counted labels ("1 слот / 2 слота / 5 слотов") are picked in code.
enum PluralForm {
    case one, few, many, other
}

extension String {
    /// The language the UI speaks: the one chosen in settings, else the
    /// device's. Two lowercase letters ("ru", "en", "hy").
    static var appLanguageCode: String {
        let stored = StorageManager().fetch(key: .language, type: String.self)
        let raw = (stored?.isEmpty == false ? stored : nil) ?? Locale.current.deviceLanguageCode
        return String(raw.prefix(2)).lowercased()
    }

    /// Russian one/few/many and English one/other category of `count`. Nil for
    /// a language the app has no rule for, so the caller keeps the server label.
    static func pluralForm(of count: Int, language: String = appLanguageCode) -> PluralForm? {
        let n = abs(count)
        switch language {
        case "ru":
            let mod10 = n % 10
            let mod100 = n % 100
            if mod10 == 1 && mod100 != 11 { return .one }
            if (2...4).contains(mod10) && !(12...14).contains(mod100) { return .few }
            return .many
        case "en":
            return n == 1 ? .one : .other
        default:
            return nil
        }
    }

    /// "4 слота" / "4 slots" / "4 <fallbackUnit>": the count followed by the
    /// unit in the plural form of the current app language. For a language
    /// without bundled forms the server label `fallbackUnit` follows unchanged.
    static func counted(
        _ count: Int,
        ru: (one: String, few: String, many: String),
        en: (one: String, other: String),
        fallbackUnit: String
    ) -> String {
        let unit: String
        switch (appLanguageCode, pluralForm(of: count)) {
        case ("ru", .one?): unit = ru.one
        case ("ru", .few?): unit = ru.few
        case ("ru", .many?), ("ru", .other?): unit = ru.many
        case ("en", .one?): unit = en.one
        case ("en", _?): unit = en.other
        default: unit = fallbackUnit
        }
        return "\(count) \(unit)"
    }

    /// "1 слот / 2 слота / 5 слотов", "1 slot / 2 slots"; other languages use
    /// the server label passed as `fallbackUnit`.
    static func slotsCount(_ count: Int, fallbackUnit: String) -> String {
        counted(
            count,
            ru: (one: "слот", few: "слота", many: "слотов"),
            en: (one: "slot", other: "slots"),
            fallbackUnit: fallbackUnit
        )
    }

    /// "1 пауэрбанк в наличии / 2 пауэрбанка в наличии / 5 пауэрбанков в наличии",
    /// "1 Power Bank Available / 2 Power Banks Available".
    static func powerBanksAvailable(_ count: Int, fallbackUnit: String) -> String {
        counted(
            count,
            ru: (one: "пауэрбанк в наличии", few: "пауэрбанка в наличии", many: "пауэрбанков в наличии"),
            en: (one: "Power Bank Available", other: "Power Banks Available"),
            fallbackUnit: fallbackUnit
        )
    }

    /// "1 слот для возврата / 2 слота для возврата / 5 слотов для возврата",
    /// "1 Slot to return / 2 Slots to return".
    static func slotsToReturn(_ count: Int, fallbackUnit: String) -> String {
        counted(
            count,
            ru: (one: "слот для возврата", few: "слота для возврата", many: "слотов для возврата"),
            en: (one: "Slot to return", other: "Slots to return"),
            fallbackUnit: fallbackUnit
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
