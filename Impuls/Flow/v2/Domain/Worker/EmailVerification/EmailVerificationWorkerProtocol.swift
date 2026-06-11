//
//  EmailVerificationWorkerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 03.10.23.
//

import Combine

protocol EmailVerificationWorkerProtocol {
    
    var verifyEmailPublisher: AnyPublisher<Result<Void, Error>, Never> { get }
    
    func resendVerificationEmail()
    func verifyEmail(code: String)
}
