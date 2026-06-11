//
//  BikeWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 19.07.23.
//

import Foundation
import Combine
import CoreLocation

class BikeWorker: BikeWorkerProtocol {
    
    private let useCase: BikeUseCaseProtocol
    private let bikeSocketService: MimoBikeSocketServiceProtocol
    private let homeRepasitory: HomeRepository = HomeRepository()
    private let walletRepository: WalletRepository = WalletRepository()
    private let authRepository: AuthRepository = AuthRepository()
    private let accountRepository = AccountRepository()
    
    var bikesPublisher: AnyPublisher<Result<[BikeResult], Error>, Never> {
        bikeSubject.eraseToAnyPublisher()
    }
    
    var bikeTripDataPublisher: AnyPublisher<Result<TripActionModel, MimoError>, Never> {
        bikeTripDataSubject.eraseToAnyPublisher()
    }
    
    var socketDataLoggingPublisher: AnyPublisher<Void, Never> {
        socketDataLoggingSubject.eraseToAnyPublisher()
    }
    
    private let bikeSubject = PassthroughSubject<Result<[BikeResult], Error>, Never>()
    private let bikeTripDataSubject = PassthroughSubject<Result<TripActionModel, MimoError>, Never>()
    private let socketDataLoggingSubject = PassthroughSubject<Void, Never>()
    
    init(useCase: BikeUseCaseProtocol, bikeSocketService: MimoBikeSocketServiceProtocol) {
        self.useCase = useCase
        self.bikeSocketService = bikeSocketService
        self.bikeSocketService.delegate = self
    }
    
    func loadBalance() -> AnyPublisher<WalletModel, MimoError> {
        Deferred {
            Future<WalletModel, MimoError> { promise in
                self.walletRepository.getWallet { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: NetworkError.responseError(error.localizedDescription))))
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
    
    func loadBikes(currentLocation: CLLocationCoordinate2D) -> AnyPublisher<[BikeResult], MimoError> {
        Deferred {
            Future<[BikeResult], MimoError> { promise in
                self.homeRepasitory.getBikes { result in
                    switch result {
                    case .success(let data):
                        let bikeResult = HomeMapper.toBikeResults(from: data)
                        promise(.success(bikeResult))
                    case .failure(let error):
                        promise(.failure(.init(error: .responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func scanBike(code: String, location: CLLocationCoordinate2D) -> AnyPublisher<TripActionModel, MimoError> {
        Deferred {
            Future<TripActionModel, MimoError> { promise in
                self.homeRepasitory.scan(bikeID: code, location: location) { result in
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
    
    func getBikeState() -> AnyPublisher<TripActionModel, MimoError> {
        Deferred {
            Future<TripActionModel, MimoError> { promise in
                self.authRepository.getState { result in
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
    
    func bookBike(id: String, location: CLLocationCoordinate2D) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.homeRepasitory.bookNowRequest(bookId: id, location: location) { result in
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
    
    func cancelBikeBooking(id: String) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.homeRepasitory.cancelBikeBooking(id: id) { result in
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
    
    func getMapZones() -> AnyPublisher<[Zone], MimoError> {
        Deferred {
            Future<[Zone], MimoError> { promise in
                self.homeRepasitory.getBikeMapZone { result in
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
    
    func isMimoUser(phoneNumber: String, completion: @escaping (MimoUserCheckModel?) -> Void) async {
        let result = await useCase.isMimoUser(phoneNumber: phoneNumber)
        DispatchQueue.main.async {
            switch result {
            case .success(let data):
                completion(data)
            case .failure:
                completion(nil)
            }
        }
    }
    
    func inviteUser(phoneNumber: String) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.authRepository.inviteUser(phoneNumber: phoneNumber) { result in
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
    
    func socketConnect() {
        bikeSocketService.connect()
    }
    
    func subscribeToBikeStateChange() {
        bikeSocketService.subscribeToBikeStateUpdate()
    }
}

extension BikeWorker: MimoBikeSocketServiceDelegate {
    
    func onConnect() {
        
    }
    
    func onDisconnect() {
        
    }
    
    func bikesDataReceived(_ data: [BikeResult]) {
        bikeSubject.send(.success(data))
    }
    
    func bikeStateDataReceived(_ data: TripActionModel) {
        bikeTripDataSubject.send(.success(data))
    }
    
    func socketDataLagging() {
        socketDataLoggingSubject.send(())
    }
}
