//
//  EVChargerMapViewModel.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/4/25.
//

import Foundation
import Foundation
import CoreLocation
import Combine
import GoogleMaps

enum EvChargerViewState {
    case initial
    case scooterList(Int)
}

final class EVChargerMapViewModel: MimoBaseViewModel {
    private let locationManager: MimoLocationManagerProtocol
    private let worker: EVChargerWorkerProtocol
    private let messagingService: MessageServiceProtocol
    private let preSelectedStationID: String?
    private var cancellables = Set<AnyCancellable>()
    private let selectedFilters: SelectedFilters = SelectedFilters()
    
    @Published var viewState: EvChargerViewState = .initial
    
    @Published private(set) var startLocation: CLLocationCoordinate2D?
    @Published private(set) var currentLocation: CLLocationCoordinate2D?
    
    @Published private(set) var stations: [EVChargingStation]?
    
    @Published private(set) var walletInfo: WalletModel?
    @Published private(set) var financialState: FinancialStateModel?
    @Published private(set) var walletState: FinancialState?
    @Published private(set) var user: UserResponse?
    
    @Published private(set) var stationMarkers: [GMSMarker] = []
    @Published private(set) var selectedStationMarker: GMSMarker?
    
    @Published private(set) var scooterTripData: ScooterStateModel?
    @Published private(set) var scooterStateData: [ScooterStateModel]?
    
    @Published private(set) var selectedTrip: ScooterStateModel?
    @Published private(set) var isProfileCompleted: Bool = false
        
    @Published private(set) var isUserInvited: Bool?
    
    @Published private(set) var showInfoMessage: Bool = false
    
    @Published private(set) var aciveChargings: Bool = false
    var stationId: String = ""

    var mapRadius: Double = 5000
    private var lastMapCenter: CLLocationCoordinate2D?
        
    var selectedStation: EVChargingStation? {
        willSet {
            selectedStationMarker?.icon = selectedStation?.isFast == true ? #imageLiteral(resourceName: "evcharger_fast_marker") : #imageLiteral(resourceName: "evcharger_marker")
            
            if newValue == nil {
                selectedStationMarker = nil
            }
        }
        didSet {
            let selectedMarker = stationMarkers.first(where: { $0.position.latitude == selectedStation?.location?.latitude && $0.position.longitude == selectedStation?.location?.longitude })
            selectedMarker?.icon = selectedStation?.isFast == true ? #imageLiteral(resourceName: "evcharger_fast_selected_marker") : #imageLiteral(resourceName: "evcharger_selected_marker")
            self.selectedStationMarker = selectedMarker
        }
    }
        
    var coordinator: EVChargerCoordinator!
    
    init(
        preSelectedId: String?,
        worker: EVChargerWorkerProtocol,
        locationManager: MimoLocationManagerProtocol,
        messagingService: MessageServiceProtocol
    ) {
        self.preSelectedStationID = preSelectedId
        self.worker = worker
        self.locationManager = locationManager
        self.messagingService = messagingService
        super.init()
        
        setupPublishers()
        
        self.messagingService.subscribe(self, for: .scooterScanned, .scooterTripEnded, .balanceUpdated, .speedTariffChanged)
        
        fetchStates()
    }
    
    func viewDidLoaded() {
        if let preSelectedStationID {
            coordinator.routeEVChargerDetailView(id: preSelectedStationID, byStationId: true)
        }

        worker.socketConnect()
        locationManager.sendLastLocation()
    }
    
    func fetchStates() {
        worker.fetchStates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] chargings in
                self?.aciveChargings = !chargings.isEmpty
                self?.stationId = chargings.last?.station.id ?? ""
            }
            .store(in: &cancellables)
    }
    
    func activeChargingTapped() {
        coordinator.showChargingSessionView(id: stationId)
    }
    
    private func setupPublishers() {
        selectedFilters.objectWillChange
             .sink { [weak self] in
                 // react to filter changes here
                 print("Filters changed")

                 if let lastMapCenter = self?.lastMapCenter {
                     self?.loadScooters(mapCenter: lastMapCenter)
                 }
             }
             .store(in: &cancellables)
        
        locationManager.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self else { return }
                
                if self.startLocation == nil {
                    self.startLocation = location
                }
                
                self.currentLocation = location
            }
            .store(in: &cancellables)
        
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }

                if let lastMapCenter {
                    self.loadScooters(mapCenter: lastMapCenter)
                }
            }
            .store(in: &cancellables)
    }
    
    func filterTapped() {
        coordinator.routeEVChargerFilter(selectedFilters: selectedFilters)
     }
    
    func loadScooters(mapCenter: CLLocationCoordinate2D) {
        lastMapCenter = mapCenter

        let chargingTypes = selectedFilters.chargingTypes.isEmpty
            ? EVChargingType.allCases.map { $0.rawValue }
            : Array(selectedFilters.chargingTypes)
        let connectorTypes = selectedFilters.connectorTypes.isEmpty
            ? EVConnectorType.allCases.map { $0.rawValue }
            : Array(selectedFilters.connectorTypes)
        let facilities = selectedFilters.amenities.isEmpty
            ? EVFacility.allCases.map { $0.rawValue }
            : Array(selectedFilters.amenities)

        worker.getLocationList(
            location: mapCenter,
            radius: 300000,
            chargingTypes: chargingTypes,
            connectorTypes: connectorTypes,
            facilities: facilities,
            minPowerKwts: selectedFilters.minChargingPower,
            maxPowerKwts: selectedFilters.maxChargingPower,
            stations: []
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            switch completion {
            case .failure(let error):
                print(error)
            default: break
            }
        } receiveValue: { [weak self] stations in
            let sortAnchor = self?.currentLocation ?? mapCenter
            self?.stations = stations
                .sorted(by: { $0.coordinate.clLocation.distance(from: sortAnchor.clLocation) < $1.coordinate.clLocation.distance(from: sortAnchor.clLocation) })
            self?.updateSelectedTrip()
        }
        .store(in: &cancellables)
    }
    
    func loadBalance() {
        Publishers.Zip3(worker.loadFinancialState(), worker.loadBalance(), worker.getUser())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] financialState, wallet, user in
                self?.financialState = financialState
                self?.walletState = financialState.state
                self?.walletInfo = wallet
                self?.user = user
            }
            .store(in: &cancellables)
    }
    
    func updateSelectedTrip() {
//        self.selectedTripIndex = index
        
//        if !tripStartedList.isEmpty {
//            selectedTrip = index < tripStartedList.count ? tripStartedList[index] : tripStartedList.first
//        }
//        
//        if !bookingStartedList.isEmpty {
//            selectedTrip = self.bookingStartedList[index]
//        }
        
        guard let tripScooter = selectedTrip?.scooter else {
            self.stationMarkers = stations?.compactMap({ $0.toGMSMarker(animate: stationMarkers.isEmpty) }) ?? []
//            self.selectedStation = stations?.first(where: { $0.qr == selectedStation?.qr })
            return
        }
        
        var _scootersMarkers: [GMSMarker] = []
        stations?.forEach({ scooter in
            let marker = scooter.toGMSMarker(animate: stationMarkers.isEmpty)
            
            if scooter.id == tripScooter.id {
                marker.icon = tripScooter.batteryPercent?.scooterMarkerSelectedIcon
                self.selectedStation = scooter
            }
            
            _scootersMarkers.append(marker)
        })
        
//        scooterStateData?.compactMap({ $0.scooter }).forEach({ scooter in
//            if !(stations?.contains(where: { $0.id == tripScooter.id }) ?? true) {
//                let tripScooterResult = ScooterResult(
//                    id: scooter.id ?? "",
//                    qr: scooter.qr ?? "",
//                    type: scooter.type ?? "",
//                    batteryPercent: scooter.batteryPercent ?? 0,
//                    remainingMileage: scooter.remainingMileage ?? 0,
//                    longitude: scooter.located?.longitude ?? 0,
//                    latitude: scooter.located?.latitude ?? 0)
//                
//                let marker = tripScooterResult.toGMSMarker(animate: stationMarkers.isEmpty)
//                marker.icon = scooter.id == tripScooter.id ? tripScooterResult.batteryPercent.scooterMarkerSelectedIcon : tripScooterResult.batteryPercent.scooterMarkerIcon
//                self.selectedStation = tripScooterResult
//                
//                _scootersMarkers.append(marker)
//            }
//        })
        
        self.stationMarkers = _scootersMarkers
    }
    
    func updateMyLocation() {
        startLocation = nil
        locationManager.sendLastLocation()
    }
    
    func isMimoUser(phoneNumber: String, completion: @escaping (MimoUserCheckModel?) -> Void) {
        Task {
            await worker.isMimoUser(phoneNumber: phoneNumber, completion: completion)
        }
    }
    
    func inviteUser(phoneNumber: String) {
        worker.inviteUser(phoneNumber: phoneNumber)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] _ in
                self?.isUserInvited = true
            }
            .store(in: &cancellables)
    }
    
    override func receive(message: MessageKey) {
        switch message {
        case .scooterTripEnded:
//            fetchScooterTrips()
            loadBalance()
            if let lastMapCenter {
                loadScooters(mapCenter: lastMapCenter)
            }
        case .balanceUpdated:
            loadBalance()
        default:
            break
        }
    }
    
    override func unsubscribe() {
        messagingService.unsubscribe(self, from: .scooterScanned, .scooterTripEnded, .balanceUpdated)
    }
}
