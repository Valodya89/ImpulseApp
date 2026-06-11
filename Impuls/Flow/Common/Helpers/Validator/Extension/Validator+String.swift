//
//  Validator+String.swift
//  MimoBike
//
//  Created by ITHD LLC on 26.04.21.
//

import Foundation


extension Validator where T == String {
    
    func notEmpty(errorMessage: String? = nil) -> Validator<String> {
        if needBreak() { return self }

        if (data.isNullOrEmpty || data.isBlank) {
            validationFail(errorMessage ?? "Data can not be empty")
        } else {
            validationSuccess()
        }
        return self
    }
    
    func hasSpace(errorMessage: String? = nil) -> Validator<String> {
        if needBreak() { return self }

        let result = data!.contains(" ")

        if result {
            validationFail(errorMessage ?? "Can not contain space")
        } else {
            validationSuccess()
        }
        return self
    }
    
    func contains(subString: String, errorMessage: String? = nil) -> Validator<String> {
        if needBreak() { return self }

        let result = data!.contains(subString)

        if !result {
            validationFail(errorMessage ?? "Data must contains \(subString)")
        } else {
            validationSuccess()
        }
        return self
    }
    
    func length(length: Int, errorMessage: String? = nil) -> Validator<String> {
        if needBreak() { return self }

        if data!.count != length {
            validationFail(errorMessage?.replacingOccurrences(of: "<length>", with: "\(length)") ?? "Data must contains \(length) character")
        } else {
            validationSuccess()
        }
        return self
    }
    
    func minLength(length: Int, errorMessage: String? = nil) -> Validator<String> {
        if needBreak() { return self }

        if data!.count < length {
            validationFail(errorMessage?.replacingOccurrences(of: "<length>", with: "\(length)") ?? "Data must contains min \(length) character")
        } else {
            validationSuccess()
        }
        return self
    }
    
    func maxLength(length: Int, errorMessage: String? = nil) -> Validator<String> {
        if needBreak() { return self }

        if data!.count > length {
            validationFail(errorMessage?.replacingOccurrences(of: "<length>", with: "\(length)") ?? "Data must contains max \(length) character")
        } else {
            validationSuccess()
        }
        return self
    }
    
    func isValidEmail(errorMessage: String? = nil) -> Validator<String> {
        if needBreak() { return self }
        
        let match = data!.matches(RegexConstants.EMAIL_REGEX)
        
        if !match {
            validationFail(errorMessage ?? "Invalid email address")
        } else {
            validationSuccess()
        }
        return self
    }
    
    func isValidPhone(countryCode: String, errorMessage: String? = nil) -> Validator<String> {
        if needBreak() { return self }

        let match = data!.matches(RegexConstants.PHONE_REGEX)

        if !match {
            validationFail(errorMessage ?? "Invalid phone number")
        } else {
            validationSuccess()
        }
        return self
    }
    
    func isEquals(string: String, errorMessage: String? = nil) -> Validator<String> {
        if needBreak() { return self }

        if data != string {
            validationFail(errorMessage ?? "Data not equals")
        } else {
            validationSuccess()
        }
        return self
    }
    
    func lettersOnly(errorMessage: String? = nil) -> Validator<String> {
        if needBreak() { return self }

        let result = data!.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil

        if !result {
            validationFail(errorMessage ?? "Can contain only letters")
        } else {
            validationSuccess()
        }
        return self
    }
    
    func lettersOnlyWithSpace(errorMessage: String? = nil) -> Validator<String> {
        if needBreak() { return self }

        let result = data!.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil

        if !result {
            validationFail(errorMessage ?? "Can contain only letters")
        } else {
            validationSuccess()
        }
        return self
    }
    
    func digitsOnly(errorMessage: String? = nil) -> Validator<String> {
        if needBreak() { return self }

        let result = data!.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil

        if !result {
            validationFail(errorMessage ?? "Can contain only digits")
        } else {
            validationSuccess()
        }
        return self
    }
    
    func isValidScooterCode(errorMessage: String? = nil) -> Validator<String> {
        if needBreak() { return self }
        guard let data else { return self }
        
        if data.hasPrefix("1001") && data.count == 8 {
            validationSuccess()
        } else {
            validationFail(errorMessage ?? "Incorrect QR code")
        }
        
        return self
    }
    
    func isValidBikeCode() -> Validator<String> {
        if needBreak() { return self }
        guard let data else { return self }
        
        let bikeURL = URL(string: data)?.query ?? ""
        if bikeURL.count == 10 {
            validationSuccess()
        } else {
            validationFail("Incorrect QR code")
        }
        
        return self
    }
    
    func isValidChargerCode() -> Validator<String> {
        if needBreak() { return self }
        guard let data else { return self }
        guard let query = URL(string: data)?.lastPathComponent else { return self }
        
        if query.starts(with: "200") {
            validationSuccess()
        } else {
            validationFail("Incorrect QR code")
        }
        
        return self
    }
    
    func isValidEVChargerCode() -> Validator<String> {
        if needBreak() { return self }
        guard let data else { return self }
        guard let query = URL(string: data)?.lastPathComponent else { return self }
        
        if query.starts(with: "300") {
            validationSuccess()
        } else {
            validationFail("Incorrect QR code")
        }
        
        return self
    }
}


extension String {
    var isBlank: Bool {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func matches(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
    var isEmail: Bool {
        do {
            let regex = try NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", options: .caseInsensitive)
            return regex.firstMatch(in: self, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.count)) != nil
        } catch {
            return false
        }
    }

}

extension Swift.Optional where Wrapped == String {
    
    var isNullOrEmpty: Bool {
        switch self {
        case .none:
            return false
        case .some(let value):
            return value == ""
        }
    }
    
    var isBlank: Bool {
        switch self {
        case .none:
            return false
        case .some(let value):
            return  value.isBlank
        }
    }
}
