//
//  PartnershipWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.10.23.
//

import Foundation
import Combine

protocol PartnershipWorkerProtocol {
    func submitApplication(fullName: String, email: String, phoneNumber: String?, location: String) -> AnyPublisher<Void, MimoError>
}

class PartnershipWorker: PartnershipWorkerProtocol {
    
    private var accountRepository = AccountRepository()
    
    func submitApplication(fullName: String, email: String, phoneNumber: String?, location: String) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.accountRepository.submitPartnershipApplication(fullName: fullName, email: email, phoneNumber: phoneNumber, location: location) { result in
                    switch result {
                    case .success:
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
