//
//  MimoError.swift
//  MimoBike
//
//  Created by Vardan on 12.05.21.
//

import Foundation

final class MimoError: Error {
    public var message: String
    
    init(error: NetworkError) {
        switch error {
        case .validatorError(let error):
            self.message = error
        case .responseError(let error):
            self.message = error
        case .serverError:
            self.message = "Something went wrong."
        case .invalidParse(let error):
            self.message = error
        case .tooFar(let error):
            self.message = error
        }
    }
}

public enum NetworkError: Error {
    case validatorError(_ errorMessage: String)
    case responseError(_ errorMessage: String)
    case serverError
    case invalidParse(_ errorMessage: String)
    case tooFar(_ errorMessage: String)
}
