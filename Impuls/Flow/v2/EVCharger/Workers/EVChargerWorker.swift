//
//  EVChargerWorker.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/26/25.
//

import Combine
import CoreLocation

protocol EVChargerWorkerProtocol {    
    func inviteUser(phoneNumber: String) -> AnyPublisher<Void, MimoError>
    func isMimoUser(phoneNumber: String, completion: @escaping (MimoUserCheckModel?) -> Void) async
    
    func getChargingStations() -> AnyPublisher<[EVChargingStation], MimoError>
    func filterChargingStations(selectedFilters: SelectedFilters) -> AnyPublisher<[EVChargingStation], MimoError>
    func getLocationList(location: CLLocationCoordinate2D, radius: Double, chargingTypes: [String], connectorTypes: [String], facilities: [String], minPowerKwts: Double, maxPowerKwts: Double, stations: [String]) -> AnyPublisher<[EVChargingStation], MimoError>
    func getChargingStation(id: String) -> AnyPublisher<EVChargingStation, MimoError>
    func getChargingStationDetailed(id: String) -> AnyPublisher<EVChargingStation, MimoError>
    func getChargingStationDetailedByStationId(stationId: String) -> AnyPublisher<EVChargingStation, MimoError>
    func startCharging(id: String, connectorId: Int, kwts: Double) -> AnyPublisher<(EVChargingStation, EVChargingModel), MimoError>
    func finishCharger(id: String) -> AnyPublisher<Void, MimoError>
    func getCharging(id: String) -> AnyPublisher<ChargingListDto, MimoError>
    func getGuide() -> AnyPublisher<GuideDTO, MimoError>
    
    var chargerState: AnyPublisher<EVStateMessagedDTO?, Never> { get }
    var socketDataLaggingPublisher: AnyPublisher<Void, Never> { get }
    var chargingFinished: PassthroughSubject<Void, Never> { get }
    
    func loadBalance() -> AnyPublisher<WalletModel, MimoError>
    func loadFinancialState() -> AnyPublisher<FinancialStateModel, MimoError>
    func getUser() -> AnyPublisher<UserResponse, MimoError>
    
    func fetchState(id: String)
    func fetchStates() -> AnyPublisher<[EVStateMessagedDTO], MimoError>
    
    func startPolling(for id: String, timeinterval: TimeInterval)
    func stopPolling()
    
    func socketConnect()
    func socketDisconnect()
}

class EVChargerWorker: EVChargerWorkerProtocol {
    private let useCase: EVChargerUseCaseProtocol
    private let evChargerRepository: EVChargerRepository = EVChargerRepository()
    private let walletRepository: WalletRepository = WalletRepository()
    private let authRepository: AuthRepository = AuthRepository()
    private let accountRepository = AccountRepository()
    private let evChargerSocketService: EVChargerSocketServiceProtocol
    
    private var timer: Timer?
    
    var chargingFinished = PassthroughSubject<Void, Never>()
    
    private var chargerStateSubject = CurrentValueSubject<EVStateMessagedDTO?, Never>(nil)
    private let socketDataLaggingSubject = PassthroughSubject<Void, Never>()
    
    var chargerState: AnyPublisher<EVStateMessagedDTO?, Never> {
        chargerStateSubject.eraseToAnyPublisher()
    }
    
    var socketDataLaggingPublisher: AnyPublisher<Void, Never> {
        socketDataLaggingSubject.eraseToAnyPublisher()
    }
    
    init(
        useCase: EVChargerUseCaseProtocol,
        evChargerSocketService: EVChargerSocketServiceProtocol
    ) {
        self.useCase = useCase
        self.evChargerSocketService = evChargerSocketService
        self.evChargerSocketService.delegate = self
        self.chargerStateSubject = CurrentValueSubject<EVStateMessagedDTO?, Never>(nil)
    }

    func startPolling(for id: String, timeinterval: TimeInterval = 10) {
        stopPolling() // prevent multiple timers
        
        // Immediately fetch once
        fetchState(id: id)
        
        // Start 30s repeating timer
        timer = Timer.scheduledTimer(withTimeInterval: timeinterval, repeats: true) { [weak self] _ in
            self?.fetchState(id: id)
        }
    }
    
    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
    
    func fetchState(id: String) {
        evChargerRepository.getChargingState() { [weak self] result in
            switch result {
            case .success(let dto):
                print("AAAAA fetched charger state")
                if let charger = dto.first(where: { $0.station.id == id }) {
                    self?.chargerStateSubject.send(charger)
                } else {
                    self?.chargingFinished.send()
//                    self?.chargerStateSubject.send(nil) // FInished state
                }
            case .failure(let error):
                print("Failed to fetch charger state:", error)
            }
        }
    }
    
    func fetchStates() -> AnyPublisher<[EVStateMessagedDTO], MimoError> {
//        evChargerRepository.getChargingState() { [weak self] result in
//            switch result {
//            case .success(let dto):
//                print("AAAAA fetched charger state")
//                
//            case .failure(let error):
//                print("Failed to fetch charger state:", error)
//            }
//        }
        
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
    
    func getChargingStations() -> AnyPublisher<[EVChargingStation], MimoError> {
        Deferred {
            Future<[EVChargingStation], MimoError> { promise in
                self.evChargerRepository.getChargingStations { result in
                    switch result {
                    case .success(let data):
                        let stations = data.content?.compactMap { EVChargingStation(station: $0) } ?? []
                        
                        promise(.success(stations))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getLocationList(location: CLLocationCoordinate2D, radius: Double, chargingTypes: [String], connectorTypes: [String], facilities: [String], minPowerKwts: Double, maxPowerKwts: Double, stations: [String]) -> AnyPublisher<[EVChargingStation], MimoError> {
        Deferred {
            Future<[EVChargingStation], MimoError> { promise in
                self.evChargerRepository.getLocationList(
                    latitude: location.latitude,
                    longitude: location.longitude,
                    radius: radius,
                    chargingTypes: chargingTypes,
                    connectorTypes: connectorTypes,
                    facilities: facilities,
                    minPowerKwts: minPowerKwts,
                    maxPowerKwts: maxPowerKwts,
                    stations: stations
                ) { result in
                    switch result {
                    case .success(let data):
                        let locations = data.content?.compactMap { EVChargingStation(location: $0) } ?? []

                        promise(.success(locations))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func filterChargingStations(selectedFilters: SelectedFilters) -> AnyPublisher<[EVChargingStation], MimoError> {
        var criterias: [[String: Any]] = [
            [
                "fieldName": "connectors.power",
                "fieldValue": [selectedFilters.minChargingPower, selectedFilters.maxChargingPower],
                "searchOperation": "INTERVAL"
            ]
        ]
        
        if !selectedFilters.chargingTypes.isEmpty {
            criterias.append([
                "fieldName": "chargingType",
                "fieldValue": Array(selectedFilters.chargingTypes),
                "searchOperation": "IN"
            ])
        }
        
        if !selectedFilters.connectorTypes.isEmpty {
            criterias.append([
                "fieldName": "connectors.type",
                "fieldValue": Array(selectedFilters.connectorTypes),
                "searchOperation": "IN"
            ])
        }
        
        selectedFilters.amenities.forEach { amenity in
            criterias.append([
                "fieldName": "amenities",
                "fieldValue": amenity,
                "searchOperation": "EQUALS"
            ])
        }
        
        return Deferred {
            Future<[EVChargingStation], MimoError> { promise in
                self.evChargerRepository.filterChargingStations(criterias: criterias) { result in
                    switch result {
                    case .success(let data):
                        let stations = data.content?.compactMap { EVChargingStation(station: $0) } ?? []
                        
                        promise(.success(stations))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getChargingStation(id: String) -> AnyPublisher<EVChargingStation, MimoError> {
        Deferred {
            Future<EVChargingStation, MimoError> { promise in
                self.evChargerRepository.getChargingStation(id: id) { result in
                    switch result {
                    case .success(let data):
                        let station = EVChargingStation(station: data)
                        promise(.success(station))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getChargingStationDetailed(id: String) -> AnyPublisher<EVChargingStation, MimoError> {
        Deferred {
            Future<EVChargingStation, MimoError> { promise in
                self.evChargerRepository.getChargingStationDetailed(id: id) { result in
                    switch result {
                    case .success(let data):
                        let station = EVChargingStation(location: data)
                        promise(.success(station))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func getChargingStationDetailedByStationId(stationId: String) -> AnyPublisher<EVChargingStation, MimoError> {
        Deferred {
            Future<EVChargingStation, MimoError> { promise in
                self.evChargerRepository.getChargingStationDetailedByStationId(stationId: stationId) { result in
                    switch result {
                    case .success(let data):
                        let station = EVChargingStation(location: data)
                        promise(.success(station))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func startCharging(id: String, connectorId: Int, kwts: Double) -> AnyPublisher<(EVChargingStation, EVChargingModel), MimoError> {
        Deferred {
            Future<(EVChargingStation, EVChargingModel), MimoError> { promise in
                self.evChargerRepository.startCharging(id: id, connectorId: connectorId, kwts: kwts) { result in
                    switch result {
                    case .success(let data):
//                        if data.state == "INITIATED" {
//                            promise(.failure(MimoError(error: .responseError("Invalid state"))))
//                        } else {
                            
                            let station = EVChargingStation(station: data.station)
                            let chargingModel = EVChargingModel(chargingModel: data.data)
                            promise(.success((station, chargingModel)))
//                        }
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func finishCharger(id: String) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.evChargerRepository.finishCharging(id: id) { result in
                    switch result {
                    case .success:
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    func getCharging(id: String) -> AnyPublisher<ChargingListDto, MimoError> {
        Deferred {
            Future<ChargingListDto, MimoError> { promise in
                self.evChargerRepository.getCharging(id: id) { result in
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
    
    func getGuide() -> AnyPublisher<GuideDTO, MimoError> {
        Deferred {
            Future<GuideDTO, MimoError> { promise in
                self.evChargerRepository.getGuide { result in
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
    
    func socketConnect() {
        evChargerSocketService.connect()
    }
    
    func socketDisconnect() {
        evChargerSocketService.disconnect()
    }
}

extension EVChargerWorker: EVChargerSocketServiceDelegate {
    
    func onConnect() {
        
    }
    
    func onDisconnect() {
        
    }
    
    func evChargerStateDataReceived(_ data: EVSocketResponse) {
        self.chargerStateSubject.send(data.payload)
    }
    
    func socketDataLagging() {
        socketDataLaggingSubject.send(())
    }
}
