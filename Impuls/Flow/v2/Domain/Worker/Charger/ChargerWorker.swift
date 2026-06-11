//
//  ChargerWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 20.11.23.
//

import Combine
import CoreLocation

class ChargerWorker: ChargerWorkerProtocol {
    
    private let homeRepasitory: HomeRepository = HomeRepository()
    private let walletRepository: WalletRepository = WalletRepository()
    private let authRepository: AuthRepository = AuthRepository()
    private let accountRepository = AccountRepository()
    
    private let chargerSocketService: MimoChargerSocketServiceProtocol
    
    var rentedChargerDataPublisher: AnyPublisher<RentedCharger?, Never> { rentedChargerDataSubject.eraseToAnyPublisher() }
    var socketDataLaggingPublisher: AnyPublisher<Void, Never> { socketDataLaggingSubject.eraseToAnyPublisher() }
    
    private let rentedChargerDataSubject = PassthroughSubject<RentedCharger?, Never>()
    private let socketDataLaggingSubject = PassthroughSubject<Void, Never>()
    
    init(chargerSocketService: MimoChargerSocketServiceProtocol) {
        self.chargerSocketService = chargerSocketService
        self.chargerSocketService.delegate = self
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
    
    func getNews() -> AnyPublisher<[NewsObject], MimoError> {
        Deferred {
            Future<[NewsObject], MimoError> { promise in
                self.homeRepasitory.getNews(token: KeychainManager().getAccessToken() ?? "") { result in
                    switch result {
                    case .success(let data):
                        guard !data.isEmpty else { promise(.success([])); return }
                        if let lastShownDate = UserDefaults.standard.value(forKey: "lastShowDateForNews") as? Date {
                            if Date().since(lastShownDate, in: .hour) >= 24 {
                                UserDefaults.standard.setValue(Date(), forKey: "lastShowDateForNews")
                                
                                promise(.success(data))
                            } else {
                                promise(.success([]))
                            }
                        } else {
                            UserDefaults.standard.setValue(Date(), forKey: "lastShowDateForNews")
                            promise(.success(data))
                        }
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getChargingStations(currentLocation: CLLocationCoordinate2D) -> AnyPublisher<[ChargingStation], MimoError> {
        Deferred {
            Future<[ChargingStation], MimoError> { promise in
                self.homeRepasitory.getChargingStations { result in
                    switch result {
                    case .success(let data):
                        let stations = (data.content ?? []).sorted { station1, station2 in
                            let location1 = CLLocation(latitude: station1.location?.latitude ?? 0, longitude: station1.location?.longitude ?? 0)
                            let location2 = CLLocation(latitude: station2.location?.latitude ?? 0, longitude: station2.location?.longitude ?? 0)
                            
                            return location1.distance(from: currentLocation.clLocation) < location2.distance(from: currentLocation.clLocation)
                        }
                        
                        promise(.success(stations))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func scan(stationId: String, currentLocation: CLLocationCoordinate2D) -> AnyPublisher<RentedCharger, MimoError> {
        Deferred {
            Future<RentedCharger, MimoError> { promise in
                self.homeRepasitory.scanCharger(stationId: stationId, location: currentLocation) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(MimoError.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getChargerState() -> AnyPublisher<[RentedCharger], MimoError> {
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
    
    func socketConnect() {
        chargerSocketService.connect()
    }
}

extension ChargerWorker: MimoChargerSocketServiceDelegate {
    
    func onConnect() {
        
    }
    
    func onDisconnect() {
        
    }
    
    func onDataReceived(_ data: RentedCharger) {
        rentedChargerDataSubject.send(data)
    }
    
    func socketDataLagging() {
        socketDataLaggingSubject.send(())
    }
}
