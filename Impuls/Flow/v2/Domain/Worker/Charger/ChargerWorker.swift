//
//  ChargerWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 20.11.23.
//

import Combine
import CoreLocation
import UIKit

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
    private var cancellables = Set<AnyCancellable>()

    init(chargerSocketService: MimoChargerSocketServiceProtocol) {
        self.chargerSocketService = chargerSocketService

        // Publisher, not `delegate`: the socket is shared with the home screen and
        // a single delegate slot would hand every event to whichever worker was
        // created last.
        chargerSocketService.dataPublisher
            .sink { [weak self] data in
                self?.rentedChargerDataSubject.send(data)
            }
            .store(in: &cancellables)

        chargerSocketService.laggingPublisher
            .sink { [weak self] in
                self?.socketDataLaggingSubject.send(())
            }
            .store(in: &cancellables)
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

// MARK: - Stations cache

/// The last successful `GET api/station` answer, kept for the life of the app
/// process so a second visit to the power-bank map opens with its pins and
/// station cards already on screen. The map still reloads the list on every
/// open, exactly as before; this only decides what the rider looks at while
/// that reload is in flight.
///
/// Stations are kept `maxAge` (slot counts change; past that a blank map is
/// more honest than a list that is mostly wrong). Nothing here depends on
/// where the rider is: `api/station` takes no location, and the distance
/// order is computed on the device from the live fix every time.
///
/// What the answer DOES depend on is the request context every call sends:
/// the `country` and `locale` headers, and whose account the token belongs
/// to. The entry is stamped with that context; reading or writing under a
/// different one empties the cache first - so signing out, a 401 or a push
/// forced logout (every path ends in `KeychainManager.removeData()`) and a
/// language switch all start the next map the way the first one did. A
/// memory warning empties it as well. Never persisted to disk.
///
/// Thread-safe: every access takes the lock. The map reads and writes on the
/// main thread; the memory warning arrives there too, but nothing relies on it.
final class ChargerStationsCache {

    static let shared = ChargerStationsCache()

    /// Power-bank stations - the same age the Mimo map uses for its vehicles.
    static let maxAge: TimeInterval = 30 * 60

    private struct Entry {
        let stations: [ChargingStation]
        let fetchedAt: Date
    }

    private let lock = NSLock()
    private var entry: Entry?
    private var context: String?

    /// Overridable for a test harness; production reads the app settings.
    var contextProvider: () -> String = ChargerStationsCache.currentRequestContext
    var now: () -> Date = Date.init

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    /// The last successful answer, in the order it was fetched, or `nil` when
    /// there is none, it is older than `maxAge`, or it was fetched under a
    /// different request context. Setting `nil` removes the entry.
    var stations: [ChargingStation]? {
        get {
            let current = contextProvider()

            lock.lock()
            defer { lock.unlock() }

            guard context == current else {
                entry = nil
                context = current
                return nil
            }

            guard let entry, now().timeIntervalSince(entry.fetchedAt) <= ChargerStationsCache.maxAge else {
                return nil
            }

            return entry.stations
        }
        set {
            let current = contextProvider()

            lock.lock()
            defer { lock.unlock() }

            if context != current {
                entry = nil
                context = current
            }

            entry = newValue.map { Entry(stations: $0, fetchedAt: now()) }
        }
    }

    /// Forget everything. The next map open loads the way the first one did.
    func clear() {
        lock.lock()
        defer { lock.unlock() }
        entry = nil
        context = nil
    }

    @objc private func didReceiveMemoryWarning() {
        clear()
    }

    /// What the station request sends that changes its answer: the `country`
    /// header (`URLBuilder`), the `locale` header (`HomeAPI.getChargingStations`)
    /// and the account the access token belongs to. Only the token's hash is
    /// kept, never the token.
    private static func currentRequestContext() -> String {
        let country = Constant.requestCountryCode ?? "-"
        let language = StorageManager().fetch(key: .language, type: String.self)
            ?? String(Locale.preferredLanguages[0].prefix(2))
        let account = KeychainManager().getAccessToken().map { String($0.hashValue) } ?? "-"

        return "\(country)|\(language)|\(account)"
    }
}
