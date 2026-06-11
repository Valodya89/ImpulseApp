//
//  RatesWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.11.23.
//

import Combine

class RatesWorker: RatesWorkerProtocol {
    
    private let homeRepasitory = HomeRepository()
    
    func getBikeTariffs() -> AnyPublisher<[TariffModel], MimoError> {
        Deferred {
            Future<[TariffModel], MimoError> { promise in
                self.homeRepasitory.getBikeTariffs { result in
                    switch result {
                    case .success(let data):
                        let _data = data.sorted(by: { $0.order < $1.order })
                        promise(.success(_data))
                    case .failure(let error):
                        promise(.failure(MimoError(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getBikePackages() -> AnyPublisher<[PackageModel], MimoError> {
        Deferred {
            Future<[PackageModel], MimoError> { promise in
                self.homeRepasitory.getBikePackages { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(MimoError(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getChargerTariffs() -> AnyPublisher<[ChargerTariff], MimoError> {
        Deferred {
            Future<[ChargerTariff], MimoError> { promise in
                self.homeRepasitory.getChargerTariffs { result in
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
    
    func getChargerPackages() -> AnyPublisher<[ChargerPackage], MimoError> {
        Deferred {
            Future<[ChargerPackage], MimoError> { promise in
                self.homeRepasitory.getChargerPackages { result in
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
    
    func activateChargerPackage(id: String) -> AnyPublisher<ActivatedPackage, MimoError> {
        Deferred {
            Future<ActivatedPackage, MimoError> { promise in
                self.homeRepasitory.activateChargerPackage(id: id) { result in
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
    
    func activateBikePackage(id: String) -> AnyPublisher<ActivatedPackage, MimoError> {
        Deferred {
            Future<ActivatedPackage, MimoError> { promise in
                self.homeRepasitory.bikePackageActivate(id: id) { result in
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
    
    func getChargerAccount() -> AnyPublisher<ActivatedPackage?, MimoError> {
        Deferred {
            Future<ActivatedPackage?, MimoError> { promise in
                self.homeRepasitory.getChargerAccount { result in
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
