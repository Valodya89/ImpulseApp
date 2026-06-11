//
//  MimoBaseViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.05.23.
//

import Foundation

class MimoBaseViewModel: SubscriberProtocol {
    
    var id: String = UUID().uuidString
    
    var networkError: NetworkError? {
        didSet {
            switch networkError {
            case .serverError:
                errorMessage = "Server Error"
            case .invalidParse(let errorMessage):
                self.errorMessage = errorMessage
            case .responseError(let errorMessage):
                self.errorMessage = errorMessage
            case .validatorError(let errorMessage):
                self.errorMessage = errorMessage
            case .tooFar(let errorMessage):
                self.errorMessage = errorMessage
            case .none:
                break
            }
        }
    }
    
    var mimoError: MimoError? {
        didSet {
            errorMessage = mimoError?.message
        }
    }
    
    var apiError: APIError? {
        didSet {
            if case .authorizationError = apiError {
                BaseRouter.shared.showLoginView()
                return
            }
            
            self.errorMessage = apiError?.message
        }
    }
    
    @Published var errorMessage: String?
    
    deinit {
        print("deinit - \(String(describing: self))")
        unsubscribe()
    }
    
    open func receive(message: MessageKey) { }
    open func unsubscribe() { }
}
