//
//  MimoScooterViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.05.23.
//

import Foundation
import CoreLocation
import Combine
import GoogleMaps

enum MimoScooterViewState {
    case initial
    case scooterList(Int)
    case trip([ScooterStateModel]?)
}

class MimoScooterViewModel: MimoBaseViewModel {
    
    private let locationManager: MimoLocationManagerProtocol
    private let worker: ScooterWorkerProtocol
    private let messagingService: MessageServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    @Published var preScannedQR: String?
    @Published var preSelectedQR: String?
    let leasedScooters: [String]
    
    @Published var viewState: MimoScooterViewState = .initial
    
    @Published private(set) var startLocation: CLLocationCoordinate2D?
    @Published private(set) var currentLocation: CLLocationCoordinate2D?
    
    @Published private(set) var scooters: [ScooterResult]?
    @Published private(set) var parkingMarkers: [GMSMarker] = []
    
    @Published private(set) var walletInfo: WalletModel?
    @Published private(set) var financialState: FinancialStateModel?
    @Published private(set) var walletState: FinancialState?
    @Published private(set) var user: UserResponse?
    
    @Published private(set) var selectedScooterMarker: GMSMarker?
    
    @Published private(set) var scooterTripData: ScooterStateModel?
    @Published private(set) var scooterStateData: [ScooterStateModel]?
    
    @Published private(set) var selectedTrip: ScooterStateModel?
    @Published private(set) var isProfileCompleted: Bool = false
    
    @Published private(set) var mapZones: [Zone]?
    
    @Published private(set) var isUserInvited: Bool?
    @Published private(set) var news: [NewsObject]?
    
    private(set) var tripStartedList: [ScooterStateModel] = []
    private(set) var tripEndedList: [ScooterStateModel] = []
    private(set) var tripPausedList: [ScooterStateModel] = []
    private(set) var bookingStartedList: [ScooterStateModel] = []
    private(set) var bookingEndedList: [ScooterStateModel] = []
    
    @Published private(set) var scooterMarkers: [GMSMarker] = []
    
    @Published private(set) var showInfoMessage: Bool = false
    
    var zoneDrawerData: ZoneDrawerData?
    
    var selectedScooter: ScooterResult? {
        willSet {
            selectedScooterMarker?.icon = selectedScooter?.batteryPercent.scooterMarkerIcon
            
            if newValue == nil {
                selectedScooterMarker = nil
            }
        }
        didSet {
            let selectedScooterMarker = scooterMarkers.first(where: { $0.position.latitude == selectedScooter?.latitude && $0.position.longitude == selectedScooter?.longitude })
            selectedScooterMarker?.icon = selectedScooter?.batteryPercent.scooterMarkerSelectedIcon
            self.selectedScooterMarker = selectedScooterMarker
        }
    }
    
    private var selectedTripIndex: Int?
    
    init(
        preScannedQR: String?,
        preSelectedQR: String?,
        leasedScooters: [String],
        worker: ScooterWorkerProtocol,
        locationManager: MimoLocationManagerProtocol,
        messagingService: MessageServiceProtocol
    ) {
        self.preScannedQR = preScannedQR
        self.preSelectedQR = preSelectedQR
        self.leasedScooters = leasedScooters
        self.worker = worker
        self.locationManager = locationManager
        self.messagingService = messagingService
        super.init()
        
        setupPublishers()
        
        self.messagingService.subscribe(self, for: .scooterScanned, .scooterTripEnded, .balanceUpdated, .speedTariffChanged)
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
            }
            .store(in: &cancellables)
        
        worker.scooterTripDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                guard let self else { return }
                
                if data?.state == .TripEnded {
                    self.scooterTripData = nil
                } else {
                    self.scooterTripData = data
                    if self.selectedScooter?.qr == data?.scooter?.qr {
                        if let lat = data?.scooter?.located?.latitude, let lng = data?.scooter?.located?.longitude {
                            self.selectedScooterMarker?.position = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                        }
                    }
                }
            }
            .store(in: &cancellables)
        
        worker.scootersDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] scooters in
                self?.scooters = scooters
                self?.updateSelectedTrip(with: self?.selectedTripIndex ?? 0)
            }
            .store(in: &cancellables)
        
        worker.socketDataLoggingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                
                if let data = self.scooterStateData, !data.isEmpty {
                    self.fetchScooterTrips()
                }
            }
            .store(in: &cancellables)
        
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                
                if let currentLocation {
                    self.loadScooters(currentLocation: currentLocation)
                }
            }
            .store(in: &cancellables)
    }
    
    func loadScooters(currentLocation: CLLocationCoordinate2D) {
        worker.loadScooters(currentLocation: currentLocation)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
//                    self?.mimoError = error
                    print(error)
                default: break
                }
            } receiveValue: { [weak self] scooters in
                self?.scooters = scooters
                self?.updateSelectedTrip(with: self?.selectedTripIndex ?? 0)
            }
            .store(in: &cancellables)
    }
    
    func loadParkings() {
        worker.loadParkings()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] parkings in
                self?.parkingMarkers = parkings.compactMap({ $0.toGMSMarker() })
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
    
    func socketConnect() {
        worker.socketConnect()
    }
    
    func fetchScooterTrips() {
        worker.fetchScooterState()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] data in
                guard let self else { return }
                
                self.tripStartedList = data.filter({ $0.state == .TripStarted })
                self.tripEndedList = data.filter({ $0.state == .TripEnded })
                self.tripPausedList = data.filter({ $0.state == .TripPaused })
                self.bookingStartedList = data.filter({ $0.state == .Booking_Started })
                self.bookingEndedList = data.filter({ $0.state == .BookingEnded })
                
                self.scooterStateData = data
                
                if !showInfoMessage {
                    self.showInfoMessage = !self.tripStartedList.isEmpty
                }
                
                if self.tripStartedList.isEmpty {
                    self.showInfoMessage = false
                }
                
                if data.isEmpty {
                    self.selectedTrip = nil
                }
                
                UserManager.share.isHaveScooterTrip = !data.isEmpty
                
                if self.selectedTrip == nil {
                    self.updateSelectedTrip(with: 0)
                }
            }
            .store(in: &cancellables)
    }
    
    func bookScooter(id: String, location: CLLocationCoordinate2D) {
        worker.bookScooter(id: id, location: location)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] _ in
                self?.fetchScooterTrips()
            }
            .store(in: &cancellables)
    }
    
    func cancelScooterBooking(id: String) {
        worker.cancelBooking(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] _ in
                self?.fetchScooterTrips()
            }
            .store(in: &cancellables)
    }
    
    func startLeasedScooter(id: String) {
        worker.unlockLeasedScooter(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] _ in
                self?.fetchScooterTrips()
            }
            .store(in: &cancellables)
    }
    
    func stopLeasedScooter(id: String) {
        worker.lockLeasedScooter(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] _ in
                self?.fetchScooterTrips()
            }
            .store(in: &cancellables)
    }
    
    func openLeasedScooter(id: String) {
        worker.openBatteryCover(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] _ in
                self?.fetchScooterTrips()
            }
            .store(in: &cancellables)
    }
    
    func getMapZones() {
        worker.loadZones()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] zones in
                self?.mapZones = zones
            }
            .store(in: &cancellables)
    }
    
    func updateSelectedTrip(with index: Int) {
        self.selectedTripIndex = index
        
        if !tripStartedList.isEmpty {
            selectedTrip = index < tripStartedList.count ? tripStartedList[index] : tripStartedList.first
        }
        
        if !bookingStartedList.isEmpty {
            selectedTrip = self.bookingStartedList[index]
        }
        
        guard let tripScooter = selectedTrip?.scooter else {
            self.scooterMarkers = scooters?.compactMap({ $0.toGMSMarker(animate: scooterMarkers.isEmpty) }) ?? []
            self.selectedScooter = scooters?.first(where: { $0.qr == selectedScooter?.qr })
            return
        }
        
        var _scootersMarkers: [GMSMarker] = []
        scooters?.forEach({ scooter in
            let marker = scooter.toGMSMarker(animate: scooterMarkers.isEmpty)
            
            if scooter.id == tripScooter.id {
                marker.icon = tripScooter.batteryPercent?.scooterMarkerSelectedIcon
                self.selectedScooter = scooter
            }
            
            _scootersMarkers.append(marker)
        })
        
        scooterStateData?.compactMap({ $0.scooter }).forEach({ scooter in
            if !(scooters?.contains(where: { $0.id == tripScooter.id }) ?? true) {
                let tripScooterResult = ScooterResult(
                    id: scooter.id ?? "",
                    qr: scooter.qr ?? "",
                    type: scooter.type ?? "",
                    batteryPercent: scooter.batteryPercent ?? 0,
                    remainingMileage: scooter.remainingMileage ?? 0,
                    longitude: scooter.located?.longitude ?? 0,
                    latitude: scooter.located?.latitude ?? 0)
                
                let marker = tripScooterResult.toGMSMarker(animate: scooterMarkers.isEmpty)
                marker.icon = scooter.id == tripScooter.id ? tripScooterResult.batteryPercent.scooterMarkerSelectedIcon : tripScooterResult.batteryPercent.scooterMarkerIcon
                self.selectedScooter = tripScooterResult
                
                _scootersMarkers.append(marker)
            }
        })
        
        self.scooterMarkers = _scootersMarkers
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
    
    override func receive(message: MessageKey) {
        switch message {
        case .scooterScanned, .speedTariffChanged:
            fetchScooterTrips()
        case .scooterTripEnded:
            if let currentLocation {
                loadScooters(currentLocation: currentLocation)
            }
            fetchScooterTrips()
            loadBalance()
            if let currentLocation {
                loadScooters(currentLocation: currentLocation)
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
