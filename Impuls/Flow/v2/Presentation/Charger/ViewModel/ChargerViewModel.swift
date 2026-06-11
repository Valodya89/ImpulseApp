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
    
    private var cancellables = Set<AnyCancellable>()
    
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
    
    init(preScannedQR: String?, preSelectedQR: String?, worker: ChargerWorkerProtocol, locationManager: MimoLocationManagerProtocol, messagingService: MessageServiceProtocol) {
        self._scannedQR = preScannedQR
        self.preSelectedQR = preSelectedQR
        self.worker = worker
        self.locationManager = locationManager
        self.messagingService = messagingService
        super.init()
        
        setupPublishers()
        
        self.messagingService.subscribe(self, for: .chargerRentEnded)
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
    
    func getChargingStations(currentLocation: CLLocationCoordinate2D) {
        worker.getChargingStations(currentLocation: currentLocation)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] stations in
                self?.stations.send(stations)
                self?.stationsMarkers = stations.compactMap({ $0.toGMSMarker() })
            }
            .store(in: &cancellables)
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
        default:
            break
        }
    }
    
    override func unsubscribe() {
        messagingService.unsubscribe(self, from: .chargerRentEnded)
    }
}
