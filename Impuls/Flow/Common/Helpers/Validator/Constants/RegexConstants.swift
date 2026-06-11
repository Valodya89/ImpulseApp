//
//  RegexConstants.swift
//  DGSCarrier
//
//  Created by ITHD LLC on 26.04.21.
//

import Foundation

struct RegexConstants {
    static let EMAIL_REGEX = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}"
    static let IPV4_REGEX = "((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\\.){3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])"
    static let URL_REGEX = "(:?(?:https?:\\/\\/)?(?:www\\.)?)?[-a-z0-9]+\\.(?:com|gov|org|net|edu|biz|info)"
    static let PHONE_REGEX = ""
//    static let LETTERS_ONLY_REGEX = "^[A-Za-z]+\$"
}
