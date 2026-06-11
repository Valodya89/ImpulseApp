//
//  ProfileWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 15.04.24.
//

import Foundation
import Combine

protocol ProfileWorkerProtocol {
    func loadBalance() -> AnyPublisher<WalletModel, MimoError>
    func loadFinancialState() -> AnyPublisher<FinancialStateModel, MimoError>
    func getUser() -> AnyPublisher<UserResponse, MimoError>
    func getActivePackage() -> AnyPublisher<UserResponse?, MimoError>
    func logout() -> AnyPublisher<Bool, MimoError>
    func deleteAccount() -> AnyPublisher<Bool, MimoError>
}

final class ProfileWorker: ProfileWorkerProtocol {
    
    private let accountRepository = AccountRepository()
    private let walletRepository: WalletRepository = WalletRepository()
    private let authRepository: AuthRepository = AuthRepository()
    
    func loadBalance() -> AnyPublisher<WalletModel, MimoError> {
        Deferred {
            Future<WalletModel, MimoError> { promise in
                self.walletRepository.getWallet { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(MimoError.init(error: NetworkError.responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func loadFinancialState() -> AnyPublisher<FinancialStateModel, MimoError> {
        Deferred {
            Future<FinancialStateModel, MimoError> { promise in
                self.authRepository.getFinancialState { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getUser() -> AnyPublisher<UserResponse, MimoError> {
        Deferred {
            Future<UserResponse, MimoError> { promise in
                self.accountRepository.getUser { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(MimoError(error: NetworkError.responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getActivePackage() -> AnyPublisher<UserResponse?, MimoError> {
        Deferred {
            Future<UserResponse?, MimoError> { promise in
                self.accountRepository.getUserAccount { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func logout() -> AnyPublisher<Bool, MimoError> {
        Deferred {
            Future<Bool, MimoError> { promise in
                self.authRepository.logout { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(MimoError(error: NetworkError.responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteAccount() -> AnyPublisher<Bool, MimoError> {
        Deferred {
            Future<Bool, MimoError> { promise in
                self.authRepository.deleteAccount { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(MimoError(error: NetworkError.responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
