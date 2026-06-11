//
//  TransactionWorker.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/29/25.
//

import Combine

protocol TransactionWorkerProtocol {
    func getTransactionList() -> AnyPublisher<[TransactionDTO], MimoError>
}

final class TransactionWorker: TransactionWorkerProtocol {
    private let transactionRepository: TransactionRepository
    
    init(transactionRepository: TransactionRepository = TransactionRepository()) {
        self.transactionRepository = transactionRepository
    }
    
    func getTransactionList() -> AnyPublisher<[TransactionDTO], MimoError> {
        Deferred {
            Future<[TransactionDTO], MimoError> { promise in
                self.transactionRepository.getTransactionList { result in
                    switch result {
                    case .success(let data):
                        let scooterTrips = data.content ?? []
                        promise(.success(scooterTrips))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
