//
//  ScooterWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 12.05.23.
//

import Foundation
import Combine
import CoreLocation

class ScooterWorker: ScooterWorkerProtocol {
    
    private let useCase: ScooterUseCaseProtocol
    private let homeRepasitory: HomeRepository = HomeRepository()
    private let walletRepository: WalletRepository = WalletRepository()
    private let authRepository: AuthRepository = AuthRepository()
    private let accountRepository = AccountRepository()
    
    private let scooterSocketService: MimoScooterSocketServiceProtocol
    
    var scooterTripDataPublisher: AnyPublisher<ScooterStateModel?, Never> {
        scooterTripDataSubject.eraseToAnyPublisher()
    }
    
    var scootersDataPublisher: AnyPublisher<[ScooterResult], Never> {
        scootersDataSubject.eraseToAnyPublisher()
    }
    
    var socketDataLoggingPublisher: AnyPublisher<Void, Never> {
        socketDataLoggingSubject.eraseToAnyPublisher()
    }
    
    private let scooterTripDataSubject = PassthroughSubject<ScooterStateModel?, Never>()
    private let scootersDataSubject = PassthroughSubject<[ScooterResult], Never>()
    private let socketDataLoggingSubject = PassthroughSubject<Void, Never>()
    
    init(useCase: ScooterUseCaseProtocol, scooterSocketService: MimoScooterSocketServiceProtocol) {
        self.useCase = useCase
        self.scooterSocketService = scooterSocketService
        self.scooterSocketService.delegate = self
    }
    
    func loadScooters(currentLocation: CLLocationCoordinate2D) -> AnyPublisher<[ScooterResult], MimoError> {
        Deferred {
            Future<[ScooterResult], MimoError> { promise in
                self.homeRepasitory.getScooters { result in
                    switch result {
                    case .success(let data):
                        let scooterResult = HomeMapper.toScooterResults(from: data)
                            .sorted(by: { $0.coordinate.clLocation.distance(from: currentLocation.clLocation) < $1.coordinate.clLocation.distance(from: currentLocation.clLocation) })
                        promise(.success(scooterResult))
                    case .failure(let error):
                        promise(.failure(MimoError(error: NetworkError.responseError(error.localizedDescription))))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
 
    func loadParkings() -> AnyPublisher<[ParkingResponse], MimoError> {
        Deferred {
            Future<[ParkingResponse], MimoError> { promise in
                self.homeRepasitory.getParkings { result in
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
    
    func loadZones() -> AnyPublisher<[Zone], MimoError> {
        Deferred {
            Future<[Zone], MimoError> { promise in
                self.homeRepasitory.getMapZone { result in
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
   
    func fetchScooterState() -> AnyPublisher<[ScooterStateModel], MimoError> {
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
    
    func bookScooter(id: String, location: CLLocationCoordinate2D) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.homeRepasitory.bookNowScooterRequest(bookId: id, location: location) { result in
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
    
    func cancelBooking(id: String) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.homeRepasitory.cancelScooterBooking(id: id) { result in
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
    
    func lockLeasedScooter(id: String) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.homeRepasitory.lockLeasedScooter(id: id) { result in
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
    
    func unlockLeasedScooter(id: String) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.homeRepasitory.unlockLeasedScooter(id: id) { result in
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
    
    func openBatteryCover(id: String) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.homeRepasitory.openBatteryCover(id: id) { result in
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
    
    func socketConnect() {
        scooterSocketService.connect()
    }
}

extension ScooterWorker: MimoScooterSocketServiceDelegate {
    
    func scootersDataReceived(_ data: [ScooterResult]) {
        scootersDataSubject.send(data)
    }
    
    func onConnect() {
        
    }
    
    func onDisconnect() {
        
    }
    
    func onDataReceived(_ data: ScooterStateModel) {
        scooterTripDataSubject.send(data)
    }
    
    func socketDataLagging() {
        socketDataLoggingSubject.send(())
    }
}
