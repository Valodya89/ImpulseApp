//
//  MimoHomeViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.06.23.
//

import Foundation
import Combine
import CoreLocation

class MimoHomeViewModel: MimoBaseViewModel {
    
    private var cancellables = Set<AnyCancellable>()
    
    private let worker: MimoHomeWorkerProtocol
    private let locationManager: MimoLocationManagerProtocol
    private let messageServicce: MessageServiceProtocol
    
    @Published private(set) var currentLocation: CLLocationCoordinate2D?
    @Published private(set) var walletInfo: WalletModel?
    @Published private(set) var financialState: FinancialStateModel?
    @Published private(set) var isForceUpdatedNeeded: Bool?
    @Published private(set) var isLocationAuthorized: Bool = false
    
    @Published private(set) var activeTrips: [AnyObject]
    @Published private(set) var availableServices: [MimoProductType]?
    @Published private(set) var countryCode: String?
    
    private(set) var fastDecisions: CurrentValueSubject<[MimoResult], Never> = .init([])
    
    @Published private(set) var rentedCharger: RentedCharger?
    
    /// Rents the socket has already reported as finished. `GET /api/state` can
    /// keep returning them for a moment: in a `RENT_ENDED` push the embedded
    /// `data.state` is still `RENT_STARTED`, i.e. the server-side document has not
    /// caught up yet, so the refresh that follows would put the row straight back.
    private var endedRentIds: Set<String> = []

    /// Coalesces the socket-driven re-reads: a rent start arrives as several
    /// messages in a row, and each one must not be its own HTTP round trip.
    private let activeTripsRefresh = PassthroughSubject<Void, Never>()

    private var bikes: [BikeResult] = []
    private var scooters: [ScooterResult] = []
    private var chargers: [ChargingStation] = []
    private var evChargers: [EVChargingStation] = []
    var leasedScooters: [String] = []
    
    init(worker: MimoHomeWorkerProtocol, locationManager: MimoLocationManagerProtocol, messageServicce: MessageServiceProtocol, activeTrips: [AnyObject]) {
        self.worker = worker
        self.locationManager = locationManager
        self.messageServicce = messageServicce
        self.activeTrips = activeTrips
        
        super.init()
        
        messageServicce.subscribe(self, for: .balanceUpdated)
        messageServicce.subscribe(self, for: .allowedServicesUpdated)
        Task {
            try? await loadRemoteConfigs()
        }
        locationManager.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                if self?.currentLocation == nil {
                    self?.currentLocation = location
                    
                    CLGeocoder().reverseGeocodeLocation(
                        CLLocation(
                            latitude: location.latitude,
                            longitude: location.longitude
                        )) { [weak self] placemarks, error in
                            guard error == nil else { return }
                            
                            guard let isoCountryCode = placemarks?.first?.isoCountryCode else { return }
                            ApplicationSettings.shared.isoCountryCode = CountryUtilities.getAlphaThreeCode(byAlpha2Code: isoCountryCode)
                            self?.countryCode = isoCountryCode
                            self?.getAvailableServices()
                        }
                }
            }
            .store(in: &cancellables)
        
        locationManager.authorizationStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isAuthorized in
                self?.isLocationAuthorized = isAuthorized
            }
            .store(in: &cancellables)
        
        // Live rent state from the power bank socket (`/ws`, STOMP, one destination
        // per user). The states are RENT_SCANNED / RENT_STARTED / RENT_ENDED, and
        // the home screen's active-trips row has to follow all of them - putting a
        // bank back into a cabinet is a hardware event, so nothing else tells the
        // app the rent is over until the next manual refresh.
        worker.chargerDataPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] rentedCharger in
                guard let self else { return }

                self.rentedCharger = rentedCharger

                guard let rentedCharger else { return }

                self.handleRentedChargerStateChange(rentedCharger)
            })
            .store(in: &cancellables)

        // A quiet rent socket is re-read over HTTP, the way the power-bank map
        // does, so a RENT_ENDED lost to a dropped socket still reaches the strip.
        // Only while a rent is on the strip: with nothing rented there is
        // nothing to lose, and the watchdog ticks every 15 seconds for the
        // whole session.
        worker.chargerLaggingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                guard let self, self.activeTrips.contains(where: { $0 is RentedCharger }) else { return }
                self.scheduleActiveTripsRefresh()
            }
            .store(in: &cancellables)

        activeTripsRefresh
            .debounce(for: .milliseconds(600), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.getActiveTrips() }
            .store(in: &cancellables)
        
        worker.getLeasedScooters()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                case .finished: break
                }
            } receiveValue: { [weak self] leasedScooters in
                self?.leasedScooters = leasedScooters
                print("leasedScooters: \(leasedScooters)")
            }
            .store(in: &cancellables)
        
    }
    
    func loadRemoteConfigs() async throws {
        do {
            let appConfig = try await RemoteConfigManager.configure()
            print("RemoteConfig = ", appConfig)
            MimoMeta.appConfig = appConfig
        } catch (let error) {
            print(error)
        }
    }
    func getAvailableServices() {
        guard let isoCountryCode = ApplicationSettings.shared.isoCountryCode else { return }
        
        worker.getAvailableServices(countryCode: isoCountryCode)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] availableServices in
                let allowedServices = UserManager.share.userResponse?.services ?? []
                
                self?.availableServices = availableServices.filter { allowedServices.contains($0.service) }
                ApplicationSettings.shared.availableServices = availableServices.compactMap { $0.mimoType }
            }
            .store(in: &cancellables)
    }
    
    func removeProduct(at index: Int) {
        guard let product = MimoProductType(rawValue: index) else { return }
        
        availableServices?.removeAll(where: { $0 == product })
        
        guard let allowedServices = availableServices?.compactMap({ $0.service }),
              !allowedServices.isEmpty else { return }
        
        worker.updateAllowedServices(allowedServices)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                case .finished: break
                }
            } receiveValue: {
                UserManager.share.userResponse?.services = allowedServices
            }
            .store(in: &cancellables)
    }
    
    func loadData(for services: [MimoProductType]) {
        let scooterPublisher = services.contains(.scooter) ? worker.loadScooters() : Just([]).setFailureType(to: MimoError.self).eraseToAnyPublisher()
        let bikePublisher = services.contains(.bike) ? worker.loadBikes() : Just([]).setFailureType(to: MimoError.self).eraseToAnyPublisher()
        let chargerPublisher = services.contains(.charger) ? worker.loadChargers() : Just([]).setFailureType(to: MimoError.self).eraseToAnyPublisher()
        let evChargerPublisher = services.contains(.evCharger) ? worker.loadEvChargers() : Just([]).setFailureType(to: MimoError.self).eraseToAnyPublisher()
        
        scooterPublisher.replaceError(with: [])
            .combineLatest(
                bikePublisher.replaceError(with: []),
                chargerPublisher.replaceError(with: []),
                evChargerPublisher.replaceError(with: [])
            )
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] scooters, bikes, chargers, evChargers in
                self?.scooters = scooters
                self?.bikes = bikes
                self?.chargers = chargers
                
                self?.evChargers = evChargers.flatMap { station in
                    station.connectors.map { connector in
                        var newStation = station
                        newStation.connectors = [connector]
                        newStation.uniqueConnectors = [connector]
                        return newStation
                    }
                }
                
                self?.sortData()
            })
            .store(in: &cancellables)
    }
    
    func loadBalance() {
        worker.loadBalance().zip(worker.loadFinancialState())
            .receive(on: DispatchQueue.main)
            .sink { error in
                switch error {
                case .failure(let error):
                    self.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] data in
                self?.walletInfo = data.0
                self?.financialState = data.1
                UserManager.share.debtState = data.1
                UserManager.share.debtAmount = (data.0.balance - (data.1.additional ?? 0))
            }
            .store(in: &cancellables)
    }
    
    func getActiveTrips(simulate: Bool = false) {
        // One product's state call failing must not blank the whole strip: a
        // market without that product, or one server being down, used to fail
        // the whole zip and the power-bank rent never appeared on home. Each
        // product falls back to the rows it already shows.
        let current = activeTripsSnapshot()
        let scooters = worker.getActiveScooters()
            .catch { error -> Just<[ScooterStateModel]> in
                MimoSocketLog.error(.scooter, "active state failed", error.message)
                return Just(current.scooters)
            }
        let bikes = worker.getActiveBikes()
            .catch { error -> Just<TripActionModel?> in
                MimoSocketLog.error(.bike, "active state failed", error.message)
                return Just(current.bike)
            }
        let chargers = worker.getActiveChargers()
            .catch { error -> Just<[RentedCharger]> in
                MimoSocketLog.error(.charger, "active state failed", error.message)
                return Just(current.chargers)
            }
        let evChargers = worker.getActiveEvChargers()
            .catch { error -> Just<[EVStateMessagedDTO]> in
                MimoSocketLog.error(.evCharger, "active state failed", error.message)
                return Just(current.evChargers)
            }

        scooters.zip(bikes, chargers, evChargers)
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] scooters, bikes, chargers, evChargers in
                guard let self else { return }

                // The summary is not this screen's job any more: the presenter
                // remembers which rents this read shows as running and, when a
                // later read reports one of them as ended (the socket frame was
                // lost), shows the summary over whatever screen is up.
                EndedRentPresenter.shared.stateRead(chargers)

                // Only rents that are really still running belong on the strip: the
                // socket may already have ended one the server still lists, and the
                // list itself can carry an entry whose own state is RENT_ENDED.
                let liveChargers = chargers.filter { charger in
                    guard charger.state != .rentEnded else { return false }
                    guard let id = charger.data?.id else { return true }

                    return !self.endedRentIds.contains(id)
                }

                // Once the server stops reporting a finished rent there is nothing
                // left to guard against, so the id is forgotten.
                self.endedRentIds = self.endedRentIds.filter { id in
                    chargers.contains(where: { $0.data?.id == id })
                }

                var _activeTrips: [AnyObject] = scooters.compactMap({ $0 as AnyObject })
                if let bikeTrips = bikes {
                    _activeTrips.append(bikeTrips as AnyObject)
                }
                _activeTrips.append(contentsOf: liveChargers.compactMap({ $0 as AnyObject }))
                _activeTrips.append(contentsOf: evChargers.compactMap({ $0 as AnyObject }))
                if simulate {
                    self.activeTrips = [ScooterStateModel(state: .TripStarted, scooter: nil, data: nil) as AnyObject]
                } else {
                    self.activeTrips = _activeTrips
                }
            }
            .store(in: &cancellables)
    }
    
    private func activeTripsSnapshot() -> (scooters: [ScooterStateModel], bike: TripActionModel?, chargers: [RentedCharger], evChargers: [EVStateMessagedDTO]) {
        (
            scooters: activeTrips.compactMap { $0 as? ScooterStateModel },
            bike: activeTrips.compactMap { $0 as? TripActionModel }.first,
            chargers: activeTrips.compactMap { $0 as? RentedCharger },
            evChargers: activeTrips.compactMap { $0 as? EVStateMessagedDTO }
        )
    }

    func scheduleActiveTripsRefresh() {
        activeTripsRefresh.send(())
    }

    /// Reconnects the sockets and re-reads the strip: called when the app
    /// returns to the foreground on home, where no appearance callback fires.
    func resumeFromBackground() {
        MimoSocketLog.info(.charger, "home resume from background")
        worker.connectSockets()
        getActiveTrips()
        loadBalance()
    }

    /// Keeps the home active-trips strip in step with the rent socket.
    private func handleRentedChargerStateChange(_ charger: RentedCharger) {
        MimoSocketLog.info(.charger, "home rent state", "state=\(charger.state?.rawValue ?? "-") rent=\(charger.data?.id ?? "-") bank=\(charger.data?.powerBank ?? "-")")
        switch charger.state {
        case .rentEnded:
            // Drop the finished rent right away: waiting for the round trip leaves
            // a power bank on screen that is already back in the cabinet. The id is
            // remembered so the refetch below - which reconciles the other products
            // - cannot resurrect it from a server document that is still catching up.
            if let id = charger.data?.id {
                endedRentIds.insert(id)
            }

            removeActiveCharger(id: charger.data?.id)
            getActiveTrips()

        case .rentScanned, .rentStarted:
            // A rent that started on this device or another one - pull the strip in.
            scheduleActiveTripsRefresh()

        case .none:
            break
        }
    }

    private func removeActiveCharger(id: String?) {
        guard let id else { return }

        activeTrips = activeTrips.filter { trip in
            guard let rent = trip as? RentedCharger else { return true }

            return rent.data?.id != id
        }
    }

    func checkForceUpdate() {
        worker.checkAppVersion()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isForceUpdateNeeded in
                self?.isForceUpdatedNeeded = isForceUpdateNeeded
            }
            .store(in: &cancellables)
    }
    
    /// Registers the FCM token with `PUT /api/user/device`. Called on every
    /// Home appearance (cold start, after login) and on every token rotation;
    /// the worker skips a token the backend already acknowledged and retries
    /// a failed upload on its own.
    func updateDeviceInfo(fcmToken: String) {
        worker.updateDeviceInfo(token: fcmToken)
            .receive(on: DispatchQueue.main)
            .sink { _ in }
            .store(in: &cancellables)
    }
    
    func sortData() {
        var data: [MimoResult] = scooters + bikes + chargers + evChargers
        data = data.sorted(by: { (currentLocation?.distance(to: $0.coordinate) ?? 0) < (currentLocation?.distance(to: $1.coordinate) ?? 0) })
        DispatchQueue.main.async {
            self.fastDecisions.send(data)
        }
    }
    
    func getScanedStationData(code: String) -> (EVChargingStation?, EVChargingConnector?) {
        let splitData = code.components(separatedBy: ":")
        var selectedEvChargers: [EVChargingStation] = []
        var selectedConnector: EVChargingConnector?
        
        evChargers.forEach { charger in
            if charger.id == splitData[0] {
                selectedEvChargers.append(charger)
            }
        }
        guard selectedEvChargers.count > 0 else { return (nil,nil)}
        if splitData.count == 2 {
            selectedEvChargers.forEach { charger in
                selectedConnector = charger.connectors.first(where: { $0.id == Int(splitData[1])})
            }
            guard let selectedConnector else { return (selectedEvChargers.first, nil)}
            return (selectedEvChargers.first, selectedConnector)
        }
        
        return (selectedEvChargers.first, nil)
    }
    
    //MARK: MessageService
    override func receive(message: MessageKey) {
        if message == .balanceUpdated {
            loadBalance()
        }
        
        if message == .allowedServicesUpdated {
            getAvailableServices()
        }
    }
    
    override func unsubscribe() {
        messageServicce.unsubscribe(self, from: .allowedServicesUpdated)
    }
}
