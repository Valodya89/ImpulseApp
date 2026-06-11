//
//  Validator+Int.swift
//  MimoBike
//
//  Created by ITHD LLC on 26.04.21.
//

import Foundation


extension Validator where T == Int {
    
    func notEmpty(errorMessage: String? = nil) -> Validator<Int> {
        if needBreak() { return self }

        if data.isNullOrEmpty {
            validationFail(errorMessage ?? "Data can not be empty")
        } else {
            validationSuccess()
        }
        return self
    }
    
    func lessThen(maxValue: Int, errorMessage: String? = nil) -> Validator<Int> {
        if needBreak() { return self }

        if (data! > maxValue) {
            validationFail(errorMessage?.replacingOccurrences(of: "<maxValue>", with: "\(maxValue)") ?? "Data must small then \(maxValue)")
        } else {
            validationSuccess()
        }
        return self
    }
    
    func moreThen(minValue: Int, errorMessage: String? = nil) -> Validator<Int> {
        if needBreak() { return self }

        if data! < minValue {
            validationFail(errorMessage?.replacingOccurrences(of: "<minValue>", with: "\(minValue)") ?? "Data must great then \(minValue)")
        } else {
            validationSuccess()
        }
        return self
    }

    func minLength(length: Int, errorMessage: String? = nil) -> Validator<Int> {
        if needBreak() { return self }

        if String(data!).count < length {
            validationFail(errorMessage?.replacingOccurrences(of: "<length>", with: "\(length)") ?? "Data must contains min \(length) digit")
        } else {
            validationSuccess()
        }
        return self
    }

    func maxLength(length: Int, errorMessage: String? = nil) -> Validator<Int> {
        if needBreak() { return self }

        if  String(data!).count > length {
            validationFail(errorMessage?.replacingOccurrences(of: "<length>", with: "\(length)") ?? "Data must contains max \(length) digit")
        } else {
            validationSuccess()
        }
        return self
    }
}

extension Swift.Optional where Wrapped == Int {
    
    var isNullOrEmpty: Bool {
        switch self {
        case .none:
            return false
        case .some(let value):
            return value == 0
        }
    }
}
