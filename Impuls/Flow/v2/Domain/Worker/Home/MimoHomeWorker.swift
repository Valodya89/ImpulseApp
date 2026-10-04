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
    
    private let chargerSocket: MimoChargerSocketServiceProtocol
    private var socketCancellables = Set<AnyCancellable>()
    
    var chargerDataPublisher: AnyPublisher<RentedCharger?, Never> {
        chargerDataSubject.eraseToAnyPublisher()
    }

    var chargerLaggingPublisher: AnyPublisher<Void, Never> {
        chargerSocket.laggingPublisher
    }
    
    private let chargerDataSubject = PassthroughSubject<RentedCharger?, Never>()
    
    init(chargerSocketService: MimoChargerSocketServiceProtocol) {
        self.chargerSocket = chargerSocketService

        // Shared with the power bank map - see `MimoChargerSocketService` - so the
        // events arrive through the publisher rather than the single delegate.
        chargerSocket.dataPublisher
            .sink { [weak self] data in
                self?.chargerDataSubject.send(data)
            }
            .store(in: &socketCancellables)

        connectSockets()
    }

    /// The home screen is the first screen with a signed-in user, so it opens
    /// the rent socket: a bank put back while the rider is on home has to
    /// move the active-trips strip and show the summary, not wait for the map.
    func connectSockets() {
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
    
    // MARK: - Push token

    /// The FCM token the backend has acknowledged in this process. Home calls
    /// `updateDeviceInfo` on every appearance, so the same token is not sent
    /// again and again; a rotated token differs and goes through. Cleared on
    /// logout, so the next account registers afresh.
    private static var acknowledgedPushToken: String?

    /// Back-off between upload attempts; a cold start often races the network.
    private static let pushTokenRetryDelays: [TimeInterval] = [2, 5, 15, 45]

    /// Forgets the acknowledged token (logout / account deletion), so the next
    /// signed-in Home uploads whatever token Firebase mints next.
    static func forgetAcknowledgedPushToken() {
        acknowledgedPushToken = nil
    }

    /// `PUT /api/user/device` with the current FCM token (accounts
    /// docs/mobile-api.md). The backend removes a token FCM rejects as
    /// UNREGISTERED and never restores it, so the token is re-registered after
    /// login, on every cold start and on rotation (accounts
    /// docs/push-notifications.md, "Token lifecycle (mobile)"). The publisher
    /// completes when the token is acknowledged, was already acknowledged, or
    /// the retries are exhausted; it never fails, the strip must not care.
    func updateDeviceInfo(token: String) -> AnyPublisher<Void, Never> {
        Deferred {
            Future<Void, Never> { promise in
                guard Self.acknowledgedPushToken != token else {
                    return promise(.success(()))
                }

                self.sendDeviceInfo(token: token, attempt: 0, promise: promise)
            }
        }
        .eraseToAnyPublisher()
    }

    private func sendDeviceInfo(token: String, attempt: Int, promise: @escaping (Result<Void, Never>) -> Void) {
        accountRepository.updateDeviceInfo(token: token) { [weak self] result in
            switch result {
            case .success:
                Self.acknowledgedPushToken = token
                debugPrint("[push] token registered")
                promise(.success(()))
            case .failure(let error):
                debugPrint("[push] token registration failed, attempt \(attempt): \(error.localizedDescription)")

                // A signed-out user has no device to update; the next login's
                // Home starts over.
                guard let self, attempt < Self.pushTokenRetryDelays.count, KeychainManager().isUserLoggedIn() else {
                    return promise(.success(()))
                }

                DispatchQueue.global().asyncAfter(deadline: .now() + Self.pushTokenRetryDelays[attempt]) {
                    // The token may have rotated meanwhile; the newer upload wins.
                    guard Self.acknowledgedPushToken != token else { return promise(.success(())) }
                    self.sendDeviceInfo(token: token, attempt: attempt + 1, promise: promise)
                }
            }
        }
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
