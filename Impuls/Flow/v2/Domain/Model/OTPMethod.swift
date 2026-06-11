//
//  OTPMethod.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.03.24.
//

import Foundation

enum OTPMethod: String, Decodable {
    case CALL
    case SMS
}

struct OTPContent: Decodable {
    let method: OTPMethod?
}
