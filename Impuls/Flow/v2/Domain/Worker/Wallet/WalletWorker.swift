//
//  WalletWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.04.24.
//

import Combine

protocol WalletWorkerProtocol {
    func loadPaymentMethods() -> AnyPublisher<[PaymentMethodModel], MimoError>
    func loadBalance() -> AnyPublisher<WalletModel, MimoError>
    func loadFinancialState() -> AnyPublisher<FinancialStateModel, MimoError>
    func getUser() -> AnyPublisher<UserResponse, MimoError>
    func getAccount() -> AnyPublisher<UserResponse, MimoError>
    func submitPromo(code: String) -> AnyPublisher<EmptyModel, MimoError>
    func depositFromUnAttachedCard(amount: Double) -> AnyPublisher<AttachCardModel, MimoError>
    func deleteCard() -> AnyPublisher<EmptyModel, MimoError>
    func attachCard(provider: PaymentMethodProvider) -> AnyPublisher<AttachCardModel, MimoError>
    func depositFromAttachedCard(amount: Double) -> AnyPublisher<(WalletModel?, AttachCardModel?), MimoError>
    func depositFromTelCell(amount: Double, phoneNumber: String) -> AnyPublisher<Void, MimoError>
    func depositFromCrypto(amount: Double) -> AnyPublisher<AttachCardModel, MimoError>
    func depositFromFastshift(amount: Double, phoneNumber: String) -> AnyPublisher<FastshiftFormModel, MimoError>
    func depositFromMyAmeria(amount: Double) -> AnyPublisher<MyAmeriaFormModel, MimoError>
    func depositFromEasyPay(amount: Double, phoneNumber: String) -> AnyPublisher<FastshiftFormModel, MimoError>
}

final class WalletWorker: WalletWorkerProtocol {
    
    private let accountRepository = AccountRepository()
    private let walletRepository: WalletRepository = WalletRepository()
    private let authRepository: AuthRepository = AuthRepository()
    
    func loadPaymentMethods() -> AnyPublisher<[PaymentMethodModel], MimoError> {
        Deferred {
            Future<[PaymentMethodModel], MimoError> { promise in
                self.walletRepository.getPaymentMethods { result in
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
    
    func getAccount() -> AnyPublisher<UserResponse, MimoError> {
        Deferred {
            Future<UserResponse, MimoError> { promise in
                self.accountRepository.getUserAccount { result in
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
    
    func submitPromo(code: String) -> AnyPublisher<EmptyModel, MimoError> {
        Deferred {
            Future<EmptyModel, MimoError> { promise in
                self.walletRepository.sendPromoCode(code: code) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func depositFromUnAttachedCard(amount: Double) -> AnyPublisher<AttachCardModel, MimoError> {
        Deferred {
            Future<AttachCardModel, MimoError> { promise in
                self.walletRepository.depostFromUnattachedCard(amount) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func deleteCard() -> AnyPublisher<EmptyModel, MimoError> {
        Deferred {
            Future<EmptyModel, MimoError> { promise in
                self.walletRepository.deleteAttachedCard { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func attachCard(provider: PaymentMethodProvider) -> AnyPublisher<AttachCardModel, MimoError> {
        Deferred {
            Future<AttachCardModel, MimoError> { promise in
                self.walletRepository.attachCard(provider: provider.rawValue) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func depositFromAttachedCard(amount: Double) -> AnyPublisher<(WalletModel?, AttachCardModel?), MimoError> {
        Deferred {
            Future<(WalletModel?, AttachCardModel?), MimoError> { promise in
                self.walletRepository.depositFromAttachedCard2(amount) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func depositFromTelCell(amount: Double, phoneNumber: String) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.walletRepository.depositWithTelCell(amount: amount, phoneNumber: phoneNumber) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func depositFromFastshift(amount: Double, phoneNumber: String) -> AnyPublisher<FastshiftFormModel, MimoError> {
        Deferred {
            Future<FastshiftFormModel, MimoError> { promise in
                self.walletRepository.depositWithFastshift(amount: amount, phoneNumber: phoneNumber) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func depositFromMyAmeria(amount: Double) -> AnyPublisher<MyAmeriaFormModel, MimoError> {
        Deferred {
            Future<MyAmeriaFormModel, MimoError> { promise in
                self.walletRepository.depositWithMyAmeria(amount: amount) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func depositFromEasyPay(amount: Double, phoneNumber: String) -> AnyPublisher<FastshiftFormModel, MimoError> {
        Deferred {
            Future<FastshiftFormModel, MimoError> { promise in
                self.walletRepository.depositWithEasyPay(amount: amount, phoneNumber: phoneNumber) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func depositFromCrypto(amount: Double) -> AnyPublisher<AttachCardModel, MimoError> {
        Deferred {
            Future<AttachCardModel, MimoError> { promise in
                self.walletRepository.depositFromCrypto(amount) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
