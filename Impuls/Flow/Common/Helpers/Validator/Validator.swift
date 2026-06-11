//
//  Validator.swift
//  MimoBike
//
//  Created by ITHD LLC on 26.04.21.
//

import Foundation


class Validator<T> {
    
    var data: T?
    
    private var isValid = true
    private var isGroup = false
    private var successCases = 0
    private var message = ""
    
    init(data: T?) {
        self.data = data
    }
    
    func validationFail(_ message: String) {
        isValid = false
        self.message = message
    }

    func validationSuccess() {
        successCases += 1
    }

    private func setGroup() {
        isGroup = true
    }

    func notNull(errorMessage: String? = nil) -> Validator<T> {
        if needBreak() { return self }
        if data == nil {
            validationFail(errorMessage ?? "Data can not be null")
        }
        return self
    }
    
    func validate() -> ValidationResultModel {
        return ValidationResultModel(isValid: isValid, message: message)
    }

    func needBreak() -> Bool {
        return !isValid && !isGroup
    }
}
