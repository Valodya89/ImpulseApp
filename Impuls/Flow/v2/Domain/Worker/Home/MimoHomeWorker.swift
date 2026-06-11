//
//  MimoHomeWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.06.23.
//

import Foundation
import Combine
import CoreLocation

class MimoHomeWorker: MimoHomeWorkerProtocol {
    
    private let homeRepasitory: HomeRepository = HomeRepository()
    private let walletRepository: WalletRepository = WalletRepository()
    private let authRepository: AuthRepository = AuthRepository()
    private let storyRepository: StoryRepository = StoryRepository()
    private let accountRepository: AccountRepository = AccountRepository()
    
    private let chargerSocket = MimoChargerSocketService()
    
    var chargerDataPublisher: AnyPublisher<RentedCharger?, Never> {
        chargerDataSubject.eraseToAnyPublisher()
    }
    
    private let chargerDataSubject = PassthroughSubject<RentedCharger?, Never>()
    
    init() {
        chargerSocket.delegate = self
        chargerSocket.connect()
    }
    
    func loadScooters() -> AnyPublisher<[ScooterResult], MimoError> {
        Deferred {
            Future<[ScooterResult], MimoError> { promise in
                self.homeRepasitory.getScooters { result in
                    switch result {
                    case .success(let data):
                        let scooterResult = HomeMapper.toScooterResults(from: data)
                        promise(.success(scooterResult))
                    case .failure(let error):
                        promise(.failure(MimoError.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func loadBikes() -> AnyPublisher<[BikeResult], MimoError> {
        Deferred {
            Future<[BikeResult], MimoError> { promise in
                self.homeRepasitory.getBikes { result in
                    switch result {
                    case .success(let data):
                        let bikeResult = HomeMapper.toBikeResults(from: data)
                        promise(.success(bikeResult))
                    case .failure(let error):
                        promise(.failure(MimoError.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func loadChargers() -> AnyPublisher<[ChargingStation], MimoError> {
        Deferred {
            Future<[ChargingStation], MimoError> { promise in
                self.homeRepasitory.getChargingStations { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data.content ?? []))
                    case .failure(let error):
                        promise(.failure(MimoError.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func loadEvChargers() -> AnyPublisher<[EVChargingStation], MimoError> {
        Deferred {
            Future<[EVChargingStation], MimoError> { promise in
                self.homeRepasitory.getChargingStations { result in
                    switch result {
                    case .success(let data):
                        let stations = data.content?.compactMap { EVChargingStation(station: $0) } ?? []
                        promise(.success(stations))
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
                self.homeRepasitory.getChargingState { result in
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
    
    func loadBalance() -> AnyPublisher<WalletModel, MimoError> {
        Deferred {
            Future<WalletModel, MimoError> { promise in
                self.walletRepository.getWallet { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(MimoError.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }.eraseToAnyPublisher()
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
        }.eraseToAnyPublisher()
    }
    
    func checkAppVersion() -> AnyPublisher<Bool, Never> {
        Deferred {
            Future<Bool, Never> { promise in
                self.homeRepasitory.getAppVersion { result in
                    switch result {
                    case .success(let data):
                        if let info = Bundle.main.infoDictionary,
                           let storeVersion = data.version,
                           let currentVersion = info["CFBundleShortVersionString"] as? String {
                            
                            if storeVersion > currentVersion {
                                promise(.success(true))
                            } else {
                                promise(.success(false))
                            }
                        } else {
                            promise(.success(false))
                        }
                    case .failure:
                        promise(.success(false))
                    }
                }
            }
        }.eraseToAnyPublisher()
    }
    
    func updateDeviceInfo(token: String) -> AnyPublisher<Void, Never> {
        Deferred {
            Future<Void, Never> { promise in
                self.accountRepository.updateDeviceInfo(token: token) { _ in
                    promise(.success(()))
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
    
    func getAvailableServices(countryCode: String) -> AnyPublisher<[MimoProductType], MimoError> {
        Deferred {
            Future<[MimoProductType], MimoError> { promise in
                self.accountRepository.getAvailableServices(countryCode: countryCode) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data.compactMap({ service in
                            return MimoProductType.allCases.first(where: { $0.service == service })
                        })))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func updateAllowedServices(_ services: [String]) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.accountRepository.updateAllowedServices(services: services) { result in
                    switch result {
                    case .success(let success):
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getLeasedScooters() -> AnyPublisher<[String], MimoError> {
        Deferred {
            Future<[String], MimoError> { promise in
                self.homeRepasitory.getLeasedScooters { result in
                    switch result {
                    case .success(let data):
                        let leasedScooters = data?.leasedScooters ?? []
                        if let activeInsurance = data?.insurance {
                            StorageManager().store(activeInsurance.activatedAt, key: .activeInsuranceStart)
                            StorageManager().store(activeInsurance.activeUntil, key: .activeInsuranceEnd)
                        } else {
                            StorageManager().remove(key: .activeInsuranceStart)
                            StorageManager().remove(key: .activeInsuranceEnd)
                        }
                        promise(.success(leasedScooters))
                    case .failure(let error):
                        StorageManager().remove(key: .activeInsuranceStart)
                        StorageManager().remove(key: .activeInsuranceEnd)
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}

extension MimoHomeWorker: MimoChargerSocketServiceDelegate {
    
    func onConnect() {
        
    }
    
    func onDisconnect() {
        
    }
    
    func onDataReceived(_ data: RentedCharger) {
        chargerDataSubject.send(data)
    }
    
    func socketDataLagging() {
        
    }
}
