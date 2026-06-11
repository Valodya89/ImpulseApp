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
        
        worker.chargerDataPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] rentedCharger in
                self?.rentedCharger = rentedCharger
            })
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
        worker.getActiveScooters().zip(worker.getActiveBikes(), worker.getActiveChargers(), worker.getActiveEvChargers())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] failure in
                switch failure {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] scooters, bikes, chargers, evChargers in
                var _activeTrips: [AnyObject] = scooters.compactMap({ $0 as AnyObject })
                if let bikeTrips = bikes {
                    _activeTrips.append(bikeTrips as AnyObject)
                }
                _activeTrips.append(contentsOf: chargers.compactMap({ $0 as AnyObject }))
                _activeTrips.append(contentsOf: evChargers.compactMap({ $0 as AnyObject }))
                if simulate {
                    self?.activeTrips = [ScooterStateModel(state: .TripStarted, scooter: nil, data: nil) as AnyObject]
                } else {
                    self?.activeTrips = _activeTrips
                }
            }
            .store(in: &cancellables)
    }
    
    func checkForceUpdate() {
        worker.checkAppVersion()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isForceUpdateNeeded in
                self?.isForceUpdatedNeeded = isForceUpdateNeeded
            }
            .store(in: &cancellables)
    }
    
    func updateDeviceInfo(fcmToken: String) {
        worker.updateDeviceInfo(token: fcmToken)
            .receive(on: DispatchQueue.main)
            .sink { _ in
                print("Device info successfully updated")
            }
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
