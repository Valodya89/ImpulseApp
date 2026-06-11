//
//  CompleteAccountValidator.swift
//  MimoBike
//
//  Created by Vardan on 12.05.21.
//

import Foundation

final class CompleteAccountValidator {
    
    
    func validateCompleteAccount(firstName: String?, lastName: String?, email: String?, dateOfBirth: String?, sex: String?, bio: String?) -> ValidationResultModel {
        
        let firstNameValidator = Validator(data: firstName)
            .notEmpty(errorMessage: "First name can not be empty")
            .hasSpace()
            .validate()
        
        if !firstNameValidator.isValid {
            return firstNameValidator
        }
        
        let lastNameValidator = Validator(data: lastName)
            .notEmpty(errorMessage: "Last name can not be empty")
            .hasSpace()
            .validate()
        
        if !lastNameValidator.isValid {
            return lastNameValidator
        }
        
        if let email, !email.isEmpty {
            let emailValidator = Validator(data: email)
                .isValidEmail()
                .validate()
            
            if !emailValidator.isValid {
                return emailValidator
            }
        }
        
        let dateOfBirthValidator = Validator(data: dateOfBirth)
            .notEmpty(errorMessage: "Please select date of birth")
            .validate()
        
        if !dateOfBirthValidator.isValid {
            return dateOfBirthValidator
        }
        
        let sexValidator = Validator(data: sex)
            .notEmpty(errorMessage: "Please select your sex")
            .validate()
        
        if !sexValidator.isValid {
            return sexValidator
        }
        
        return ValidationResultModel(isValid: true, message: "")
    }
}
