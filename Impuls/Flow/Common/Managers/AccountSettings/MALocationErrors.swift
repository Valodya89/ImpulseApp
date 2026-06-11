//
//  MALocationErrors.swift
//  Management App
//
//  Created by Dose on 9/24/20.
//  Copyright © 2020 Doseh. All rights reserved.
//

import Foundation

enum MALocationErrors: Error {
    case locationError(description: String)
    case failureRequest(description: String)
    case errorDecoding(description: String)

    var localizedDescription: String {
        switch self {
        case .failureRequest(let description): return description
        case .locationError(let description): return description
        case .errorDecoding(description: let description): return description
        }
    }
}
