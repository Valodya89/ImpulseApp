//
//  ChargerViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 20.11.23.
//

import Foundation
import Combine
import CoreLocation
import GoogleMaps

enum MimoChargerViewState {
    case initial
    case chargerList(Int)
    case rent([RentedCharger])
}

class ChargerViewModel: MimoBaseViewModel {
    
    private let locationManager: MimoLocationManagerProtocol
    private let worker: ChargerWorkerProtocol
    private let messagingService: MessageServiceProtocol
    private let stationsCache: ChargerStationsCache
    
    private var cancellables = Set<AnyCancellable>()
    /// One network load per map open. The list is restored from the cache
    /// before the first render; this makes sure it is still refreshed once
    /// the first fix arrives, and only once.
    private var hasRefreshedStations = false
    private var isLoadingStations = false
    
    @Published var viewState: MimoChargerViewState = .initial
    
    @Published private(set) var startLocation: CLLocationCoordinate2D?
    @Published private(set) var currentLocation: CLLocationCoordinate2D?
    
    @Published private(set) var walletInfo: WalletModel?
    @Published private(set) var financialState: FinancialStateModel?
    @Published private(set) var walletState: FinancialState?
    @Published private(set) var user: UserResponse?
    
    private(set) var stations: CurrentValueSubject<[ChargingStation]?, Never> = .init(nil)
    @Published private(set) var stationsMarkers: [GMSMarker]?
    
    @Published private(set) var news: [NewsObject]?
    @Published private(set) var selectedStationMarker: GMSMarker?
    @Published private(set) var rentedChargers: [RentedCharger] = []
    @Published private(set) var preScannedQR: String?
    private var _scannedQR: String?
    @Published var preSelectedQR: String?
    
    var selectedPowerBank: String? = nil
    
    var selectedStation: ChargingStation? {
//        willSet {
////            selectedStationMarker?.icon = selectedStation?.toGMSMarker().icon
//            selectedStationMarker?.iconView = selectedStation?.toGMSMarker().iconView
//            if newValue == nil {
//                selectedStationMarker = nil
//            }
//        }
//        didSet {
//            let selectedMarker = stationsMarkers?.first(where: { ($0.position.latitude == selectedStation?.location?.latitude ?? 0) && $0.position.longitude == (selectedStation?.location?.longitude ?? 0) })
////            selectedMarker?.icon = selectedStation?.toSelectedGMSMarker().icon
//            selectedMarker?.iconView = selectedStation?.toSelectedGMSMarker().iconView
//            self.selectedStationMarker = selectedMarker
//        }
        didSet {
//            stationsMarkers?.forEach({
//                $0.iconView =
//                if ($0.position.latitude == (selectedStation?.location?.latitude ?? 0)) && ($0.position.longitude == (selectedStation?.location?.longitude ?? 0))  {
//                    $0.iconView = selectedStation?.toSelectedGMSMarker().iconView
//                }
//            })
            if selectedStation == nil {
                stationsMarkers = stations.value?.compactMap({ $0.toGMSMarker() })
                return
            }
            
            
            stationsMarkers = stations.value?.compactMap({
                if $0.id == selectedStation?.id {
                    let marker = $0.toSelectedGMSMarker()
                    self.selectedStationMarker = marker
                    return marker
                }
                
                return $0.toGMSMarker()
            })
        }
    }
    
    init(preScannedQR: String?, preSelectedQR: String?, worker: ChargerWorkerProtocol, locationManager: MimoLocationManagerProtocol, messagingService: MessageServiceProtocol, stationsCache: ChargerStationsCache = .shared) {
        self._scannedQR = preScannedQR
        self.preSelectedQR = preSelectedQR
        self.worker = worker
        self.locationManager = locationManager
        self.messagingService = messagingService
        self.stationsCache = stationsCache
        super.init()
        
        restoreCachedStations()
        setupPublishers()
        
        // `balanceUpdated` comes from the wallet, the debt screen and the
        // history: the header balance and the debt state follow it at once.
        self.messagingService.subscribe(self, for: .chargerRentEnded, .balanceUpdated)
    }
    
    private func setupPublishers() {
        locationManager.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self else { return }
                
                if self.startLocation == nil {
                    self.startLocation = location
                }
                
                self.currentLocation = location
                if self.preScannedQR == nil && self._scannedQR != nil {
                    self.preScannedQR = self._scannedQR
                }
            }
            .store(in: &cancellables)
        
        worker.rentedChargerDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rentedCharger in
                guard let rentedCharger = rentedCharger else { return }
                if let index = self?.rentedChargers.firstIndex(where: { $0.data?.powerBank == rentedCharger.data?.powerBank }) {
                    self?.rentedChargers[index] = rentedCharger
                } else {
                    self?.rentedChargers.append(rentedCharger)
                }
            }
            .store(in: &cancellables)
        
        worker.socketDataLaggingPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.getState()
            })
            .store(in: &cancellables)
    }
    
    func updateMyLocation() {
        startLocation = nil
        locationManager.sendLastLocation()
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
    
    /// Whatever an earlier visit to the map already loaded goes straight onto
    /// this one, before its first render: the pins are drawn as soon as the
    /// map view subscribes, and the station cards are there the moment a pin
    /// is tapped. The list is put in distance order from the fix the location
    /// manager already has (the fetch sorted it from the fix of that visit).
    /// `refreshStationsIfNeeded` still reloads it; the answer replaces this
    /// list in place.
    private func restoreCachedStations() {
        guard let cached = stationsCache.stations, !cached.isEmpty else { return }
        
        let restored: [ChargingStation]
        if let fix = locationManager.currenntLocation {
            restored = cached.sortedByDistance(from: fix)
        } else {
            restored = cached
        }
        
        stations.send(restored)
        stationsMarkers = restored.compactMap({ $0.toGMSMarker() })
    }
    
    /// Called on every first fix of this map (and again after "my location"
    /// resets it). Loads when there is nothing on screen yet, or when this
    /// map has not refreshed its restored list yet; never two requests at
    /// once.
    func refreshStationsIfNeeded(currentLocation: CLLocationCoordinate2D) {
        guard !isLoadingStations else { return }
        guard (stations.value ?? []).isEmpty || !hasRefreshedStations else { return }
        
        getChargingStations(currentLocation: currentLocation)
    }
    
    func getChargingStations(currentLocation: CLLocationCoordinate2D) {
        isLoadingStations = true
        
        worker.getChargingStations(currentLocation: currentLocation)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoadingStations = false
                
                switch completion {
                case .failure(let error):
                    // A failed load keeps whatever list is already on screen -
                    // an earlier answer or the restored one - instead of
                    // blanking the map; the rider is only told when there is
                    // nothing to show at all.
                    if (self.stations.value ?? []).isEmpty {
                        self.errorMessage = error.message
                    }
                default: break
                }
            } receiveValue: { [weak self] stations in
                guard let self else { return }
                self.hasRefreshedStations = true
                self.stationsCache.stations = stations
                self.apply(stations: stations)
            }
            .store(in: &cancellables)
    }
    
    /// Replaces the list in place. A station the rider has selected stays
    /// selected (matched by id, so the highlighted pin and the carousel index
    /// follow it to its new position); one that is gone from the answer
    /// returns the map to its initial state.
    private func apply(stations: [ChargingStation]) {
        self.stations.send(stations)
        
        guard let selectedId = selectedStation?.id else {
            stationsMarkers = stations.compactMap({ $0.toGMSMarker() })
            return
        }
        
        if let stillThere = stations.first(where: { $0.id == selectedId }) {
            selectedStation = stillThere
        } else {
            selectedStation = nil
            if case .chargerList = viewState {
                viewState = .initial
            }
        }
    }
    
    func scan(stationId: String, currentLocation: CLLocationCoordinate2D) {
        worker.scan(stationId: stationId, currentLocation: currentLocation)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] rentedCharger in
                if let index = self?.rentedChargers.firstIndex(where: { $0.data?.powerBank == rentedCharger.data?.powerBank }) {
                    self?.rentedChargers[index] = rentedCharger
                } else {
                    self?.rentedChargers.append(rentedCharger)
                }
            }
            .store(in: &cancellables)
    }
    
    func getState() {
        worker.getChargerState()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] rentedChargers in
                self?.rentedChargers = rentedChargers
            }
            .store(in: &cancellables)
    }
    
    func getNews() {
        worker.getNews()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] news in
                self?.news = news
            }
            .store(in: &cancellables)
    }
    
    func socketConnect() {
        worker.socketConnect()
    }
    
    override func receive(message: MessageKey) {
        switch message {
        case .chargerRentEnded:
            self.getState()
        case .balanceUpdated:
            self.loadBalance()
        default:
            break
        }
    }
    
    override func unsubscribe() {
        messagingService.unsubscribe(self, from: .chargerRentEnded, .balanceUpdated)
    }
}

private extension Array where Element == ChargingStation {
    
    /// The same order `ChargerWorker.getChargingStations` returns: nearest
    /// first, from the given fix.
    func sortedByDistance(from location: CLLocation) -> [ChargingStation] {
        sorted { station1, station2 in
            let location1 = CLLocation(latitude: station1.location?.latitude ?? 0, longitude: station1.location?.longitude ?? 0)
            let location2 = CLLocation(latitude: station2.location?.latitude ?? 0, longitude: station2.location?.longitude ?? 0)
            
            return location1.distance(from: location) < location2.distance(from: location)
        }
    }
}
