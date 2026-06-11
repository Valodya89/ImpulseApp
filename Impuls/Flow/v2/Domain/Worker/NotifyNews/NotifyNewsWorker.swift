//
//  NotifyNewsWorker.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/23/25.
//

import Foundation
import Combine

final class NotifyNewsWorker: NotifyNewsWorkerProtocol {
    
    private var accountRepository = AccountRepository()
    
    func subscribeEVChargerNews(email: String) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.accountRepository.subscribeEVChargerNews(email: email) { result in
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
