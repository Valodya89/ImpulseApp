//
//  MimoSplashWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 03.09.23.
//

import Combine

class MimoSplashWorker: MimoSplashWorkerProtocol {
    
    private let keychain = KeychainManager()
    private let storageManager = StorageManager()
    private let authRepository = AuthRepository()
    private let homeRepasitory = HomeRepository()
    private let evChargerRepository = EVChargerRepository()
    
    var isUserLoggedIn: Bool {
        keychain.isUserLoggedIn()
    }
    
    var isAccountComplated: Bool {
        storageManager.fetch(key: .isAccountCompleted, type: Bool.self) ?? false
    }
    
    func getLanguages() -> AnyPublisher<[LanguageResult], Error> {
        Deferred {
            Future<[LanguageResult], Error> { promise in
                self.authRepository.getLanguages { result in
                    switch result {
                    case .success(let data):
                        AuthMapper.toLanguageResults(from: data) { result in
                            switch result {
                            case .success(let data):
                                promise(.success(data))
                            case .failure(let error):
                                promise(.failure(error))
                            }
                        }
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getTranslations(languageCode: String) -> AnyPublisher<[String: String], Never> {
        let first = Publishers.Zip4(
            getScooterTranslations(languageCode: languageCode),
            getBikeTranslations(languageCode: languageCode),
            getChargerTranslations(languageCode: languageCode),
            getEVChargerTranslations(languageCode: languageCode))
        let second = Publishers.Zip3(getAccountTranslations(languageCode: languageCode), getMobileTranslations(languageCode: languageCode), getiPayTranslations(languageCode: languageCode))
        return Publishers.Zip(first, second)
        .map({ response1, response2 in
            let first = response1.0
            let second = response1.1
            let third = response1.2
            let fourth = response2.0
            let fifth = response2.1
            let sixth = response2.2
            let seventh = response1.3
            
            var dict: [String: String] = first
            second.forEach { dict[$0] = $1 }
            third.forEach { dict[$0] = $1 }
            fourth.forEach { dict[$0] = $1 }
            fifth.forEach { dict[$0] = $1 }
            sixth.forEach { dict[$0] = $1 }
            seventh.forEach { dict[$0] = $1 }
            
            return dict
        })
        .eraseToAnyPublisher()
    }
    
    private func getScooterTranslations(languageCode: String) -> AnyPublisher<[String: String], Never> {
        Deferred {
            Future<[String: String], Never> { promise in
                self.authRepository.getScooterTranslations(language: languageCode) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure:
                        promise(.success([:]))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func getBikeTranslations(languageCode: String) -> AnyPublisher<[String: String], Never> {
        Deferred {
            Future<[String: String], Never> { promise in
                self.authRepository.getSharingTranslations(language: languageCode) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure:
                        promise(.success([:]))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func getChargerTranslations(languageCode: String) -> AnyPublisher<[String: String], Never> {
        Deferred {
            Future<[String: String], Never> { promise in
                self.authRepository.getChargerTranslations(language: languageCode) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure:
                        promise(.success([:]))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func getEVChargerTranslations(languageCode: String) -> AnyPublisher<[String: String], Never> {
        Deferred {
            Future<[String: String], Never> { promise in
                self.authRepository.getEVChargerTranslations(language: languageCode) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure:
                        promise(.success([:]))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func getAccountTranslations(languageCode: String) -> AnyPublisher<[String: String], Never> {
        Deferred {
            Future<[String: String], Never> { promise in
                self.authRepository.getAccountTranslations(language: languageCode) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure:
                        promise(.success([:]))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func getMobileTranslations(languageCode: String) -> AnyPublisher<[String: String], Never> {
        Deferred {
            Future<[String: String], Never> { promise in
                self.authRepository.getMobileTranslations(language: languageCode) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure:
                        promise(.success([:]))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    private func getiPayTranslations(languageCode: String) -> AnyPublisher<[String: String], Never> {
        Deferred {
            Future<[String: String], Never> { promise in
                self.authRepository.getiPayTranslations(language: languageCode) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure:
                        promise(.success([:]))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getActiveScooters() -> AnyPublisher<[ScooterStateModel], MimoError> {
        Deferred {
            Future<[ScooterStateModel], MimoError> { promise in
                self.authRepository.getScooterState { result in
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
    
    func getActiveBikes() -> AnyPublisher<TripActionModel?, MimoError> {
        Deferred {
            Future<TripActionModel?, MimoError> { promise in
                self.authRepository.getState { result in
                    switch result {
                    case .success(let data):
                        if data.data != nil {
                            promise(.success(data))
                        } else {
                            promise(.success(nil))
                        }
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getActiveChargers() -> AnyPublisher<[RentedCharger], MimoError> {
        Deferred {
            Future<[RentedCharger], MimoError> { promise in
                self.homeRepasitory.getChargerState { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data.sorted(by: { ($0.data?.start ?? 0) < ($1.data?.start ?? 0) })))
                    case .failure(let error):
                        promise(.failure(MimoError.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getActiveEvChargers() -> AnyPublisher<[EVStateMessagedDTO], MimoError> {
        Deferred {
            Future<[EVStateMessagedDTO], MimoError> { promise in
                self.evChargerRepository.getChargingState { result in
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
}

extension Publishers {
    struct Zip5<A: Publisher, B: Publisher, C: Publisher, D: Publisher, E: Publisher>: Publisher
    where A.Failure == B.Failure, A.Failure == C.Failure, A.Failure == D.Failure, A.Failure == E.Failure {
        typealias Output = (A.Output, B.Output, C.Output, D.Output, E.Output)
        typealias Failure = A.Failure
        
        private let a: A
        private let b: B
        private let c: C
        private let d: D
        private let e: E
        
        init(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.e = e
        }
        
        func receive<S>(subscriber: S) where S : Subscriber, Output == S.Input, Failure == S.Failure {
            Zip(Zip4(a, b, c, d), e)
                .map { ($0.0, $0.1, $0.2, $0.3, $1) }
                .receive(subscriber: subscriber)
        }
    }
}

extension Publishers {
    struct Zip6<
        A: Publisher,
        B: Publisher,
        C: Publisher,
        D: Publisher,
        E: Publisher,
        F: Publisher
    >: Publisher
    where A.Failure == B.Failure,
          A.Failure == C.Failure,
          A.Failure == D.Failure,
          A.Failure == E.Failure,
          A.Failure == F.Failure{
        typealias Output = (A.Output, B.Output, C.Output, D.Output, E.Output, F.Output)
        typealias Failure = A.Failure
        
        private let a: A
        private let b: B
        private let c: C
        private let d: D
        private let e: E
        private let f: F
        
        init(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) {
            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.e = e
            self.f = f
        }
        
        func receive<S>(subscriber: S) where S : Subscriber, Output == S.Input, Failure == S.Failure {
            Zip(Zip5(a, b, c, d, e), f)
                .map { ($0.0, $0.1, $0.2, $0.3, $0.4, $1) }
                .receive(subscriber: subscriber)
        }
    }
}
