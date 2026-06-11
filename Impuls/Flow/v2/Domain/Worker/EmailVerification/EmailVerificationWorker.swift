//
//  EmailVerificationWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 03.10.23.
//

import Combine

class EmailVerificationWorker: EmailVerificationWorkerProtocol {
    
    private let authRepository = AuthRepository()
    
    var verifyEmailPublisher: AnyPublisher<Result<Void, Error>, Never> { verifyEmailSubject.eraseToAnyPublisher() }
    var verifyEmailSubject = PassthroughSubject<Result<Void, Error>, Never>()
    
    func resendVerificationEmail() {
        authRepository.sendCodeToEmail(userId: "", deviceID: "") { result in
            switch result {
            case .success:
                break
            case .failure:
                break
            }
        }
    }
    
    func verifyEmail(code: String) {
        authRepository.verifyEmailCode(code: code) { result in
            switch result {
            case .success:
                self.verifyEmailSubject.send(.success(()))
            case .failure(let error):
                self.verifyEmailSubject.send(.failure(error))
            }
        }
    }
}
