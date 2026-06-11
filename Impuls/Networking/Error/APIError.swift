//
//  APIError.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.06.24.
//

import Foundation

enum APIError: Error {
    case invalidURL
    case missingData(UInt)
    case requestFailed(String)
    case responseError(String)
    case decodingFailed(String)
    case authorizationError
    
    var message: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .missingData:
            return "Missing data"
        case .requestFailed(let string):
            return string
        case .responseError(let string):
            return string
        case .decodingFailed:
            return "Decode Error"
        case .authorizationError:
            return "Authorization Error"
        }
    }
}
