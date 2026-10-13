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
    
    /// Use this method to localize string.
    ///
    /// The in-memory table of the current language first (the downloaded
    /// texts, restored from disk at launch); a key it does not have is looked
    /// up in the dictionaries saved on disk, the current language with any
    /// region and then English, so a text the locale service serves is shown
    /// even when this language has none. The key itself when nothing serves it.
    func localized() -> String {
//        return LocalizationModel.shared?.getText(for: self) ?? self
        if let value = Mimo.Localization.localizations[self] { return value }
        return LocalizationStore.shared.servedFallback(for: self) ?? self
    }
    
    /// The server-driven translation, or `fallback` when the key is not on the
    /// server yet (a bare key must never reach the screen).
    func localized(fallback: String) -> String {
        let value = localized()
        return value == self ? fallback : value
    }
    
    /// A backend `message` as screen text: `String.resolveMessage` fed with the
    /// live sources (the in-memory table, the dictionaries saved on disk for
    /// the current language and English, the generic error text).
    /// - Parameter fallback: the per-key English text compiled into the app,
    ///   used only when no served text exists.
    func localizedMessage(fallback: String? = nil) -> String {
        let language = LocalizationStore.shared.currentLanguageCode
        return String.resolveMessage(
            self,
            dictionary: Mimo.Localization.localizations,
            cached: LocalizationStore.shared.fallbackDictionaries(for: language),
            language: language,
            fallback: fallback,
            generic: String.genericErrorMessage
        )
    }
    
    /// "Something went wrong. Please try again." - what a backend code with no
    /// served text is shown as. Note: on the Impulse locale service
    /// `MOBILE_something_wrong_try_again` carries the verification-code text,
    /// so the generic key stays `MOBILE_something_wrong` here.
    static var genericErrorMessage: String {
        "MOBILE_something_wrong".localized(fallback: "Something went wrong. Please try again.")
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

// MARK: - Backend message resolver -

extension String {
    /// Whether `text` is a locale key rather than human text: an ALL-CAPS
    /// module prefix, an underscore, and no whitespace
    /// ("EV_CHARGER_station_offline", "ACCOUNTS_no_such_device", "CHARGER_x").
    /// "Something went wrong." or "The operation couldn't be completed." is not.
    static func isMessageCode(_ text: String) -> Bool {
        guard !text.isEmpty,
              text.rangeOfCharacter(from: .whitespacesAndNewlines) == nil,
              let underscore = text.firstIndex(of: "_"),
              underscore != text.startIndex
        else { return false }
        let prefix = text[..<underscore]
        let allowed = CharacterSet.uppercaseLetters.union(.decimalDigits)
        return prefix.unicodeScalars.allSatisfy { allowed.contains($0) }
            && prefix.unicodeScalars.contains { CharacterSet.uppercaseLetters.contains($0) }
    }
    
    /// The text some source serves for `key`, or nil. Pure: feed it the
    /// tables. Order:
    ///  (a) `dictionary`, the in-memory table of the current language;
    ///  (b) `cached`, the dictionaries saved on disk by language code: the
    ///      exact `language`, then the same language with any region, then
    ///      "en", then English with any region.
    /// A blank served value counts as missing.
    static func servedText(for key: String,
                           dictionary: [String: String],
                           cached: [String: [String: String]],
                           language: String) -> String? {
        if let value = nonBlank(dictionary[key]) { return value }
        for code in fallbackOrder(of: cached.keys, language: language) {
            if let value = nonBlank(cached[code]?[key]) { return value }
        }
        return nil
    }
    
    /// The ONE place a backend `message` code becomes screen text. Pure:
    /// feed it the tables and unit-test it with a fake map.
    ///  (a)+(b) `servedText`: the in-memory table, then the saved
    ///      dictionaries (same language any region, then English);
    ///  (c) otherwise the existing fallbacks: `fallback` (the per-key English
    ///      text compiled into the app), then `generic` ("Something went
    ///      wrong. Please try again.") for something that looks like a machine
    ///      code; a message that is already human text is shown unchanged.
    /// `code` is trimmed; a blank code gives `generic`.
    static func resolveMessage(_ code: String,
                               dictionary: [String: String],
                               cached: [String: [String: String]],
                               language: String,
                               fallback: String? = nil,
                               generic: String) -> String {
        guard let code = nonBlank(code) else { return generic }
        if let served = servedText(for: code, dictionary: dictionary, cached: cached, language: language) {
            return served
        }
        if let fallback = nonBlank(fallback) { return fallback }
        return isMessageCode(code) ? generic : code
    }
    
    /// The language codes to try, most specific first: the exact `language`,
    /// the same language with another region (sorted), "en", then English with
    /// a region (sorted). Codes of other languages are left out.
    static func fallbackOrder<C: Collection>(of codes: C, language: String) -> [String] where C.Element == String {
        let primary = LocalizationStore.primaryLanguage(of: language)
        let sameLanguage = codes
            .filter { $0 != language && LocalizationStore.primaryLanguage(of: $0) == primary }
            .sorted()
        let english = codes
            .filter { $0 != language && $0 != "en" && LocalizationStore.primaryLanguage(of: $0) == "en" }
            .sorted()
        var order: [String] = []
        if codes.contains(language) { order.append(language) }
        order.append(contentsOf: sameLanguage)
        if primary != "en", codes.contains("en") { order.append("en") }
        order.append(contentsOf: english.filter { !order.contains($0) })
        return order
    }
    
    /// `value` trimmed, or nil when it is nil or blank.
    private static func nonBlank(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
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
