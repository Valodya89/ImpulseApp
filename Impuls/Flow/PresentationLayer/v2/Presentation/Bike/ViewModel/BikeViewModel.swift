//
//  BikeViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 30.06.23.
//

import Foundation
import Combine
import CoreLocation
import UIKit
import CoreLocation
enum BikeViewState {
    case initial
    case bikeList(Int)
    case trip(TripActionModel)
}

class BikeViewModel: MimoBaseViewModel {
    
    private var cancellables = Set<AnyCancellable>()
    
    private let worker: BikeWorkerProtocol
    private let locationManager: MimoLocationManagerProtocol
    private let messageService: MessageServiceProtocol
    
    @Published var viewState: BikeViewState = .initial
    
    @Published private(set) var preScannedQR: String?
    @Published var preSelectedQR: String?
    
    @Published private(set) var startLocation: CLLocationCoordinate2D?
    @Published private(set) var currentLocation: CLLocationCoordinate2D?
    
    @Published private(set) var scanData: TripActionModel?
    @Published private(set) var tripData: TripActionModel?
    
    @Published private(set) var walletInfo: WalletModel?
    @Published private(set) var financialState: FinancialStateModel?
    @Published private(set) var walletState: FinancialState?
    @Published private(set) var user: UserResponse?
    
    @Published private(set) var bikes: [BikeResult]?
    @Published private(set) var bikesMarkers: [MimoMarker] = []
    @Published private(set) var selectedBikeMarker: MimoMarker?
    
    @Published private(set) var mapZones: [Zone]?
    
    @Published private(set) var isUserInvited: Bool?
    @Published private(set) var news: [NewsObject]?
    
    var zoneDrawerData: ZoneDrawerData?
    
    var selectedBike: BikeResult? {
        willSet {
            selectedBikeMarker?.icon = #imageLiteral(resourceName: "ic_bike_marker")
            
            if newValue == nil {
                selectedBikeMarker = nil
            }
        }
        didSet {
            let selectedBikeMarker = bikesMarkers.first(where: { $0.position.latitude == selectedBike?.latitude && $0.position.longitude == selectedBike?.longitude })
            selectedBikeMarker?.icon = "ic_markerSelected".image
            self.selectedBikeMarker = selectedBikeMarker
        }
    }
    
    init(preScannedQR: String?, preSelectedQR: String?, worker: BikeWorkerProtocol, locationManager: MimoLocationManagerProtocol, messageService: MessageServiceProtocol) {
        self.preScannedQR = preScannedQR
        self.preSelectedQR = preSelectedQR
        self.worker = worker
        self.locationManager = locationManager
        self.messageService = messageService
        
        super.init()
        
        setupPublishers()
        
        messageService.subscribe(self, for: .balanceUpdated)
    }
    
    private func setupPublishers() {
        locationManager.locationPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                guard let self else { return }
                
                if self.startLocation == nil {
                    self.startLocation = location
                }
                
                self.currentLocation = location
            }
            .store(in: &cancellables)
        
        worker.bikesPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                guard let self else { return }
                
                switch result {
                case .success(let bikes):
                    guard let currentLocation = currentLocation?.clLocation else { return }
                    
                    let sortedBikes = bikes.sorted(by: { $0.coordinate.clLocation.distance(from: currentLocation) < $1.coordinate.clLocation.distance(from: currentLocation) })
                    self.bikesMarkers = sortedBikes.compactMap({ $0.toGMSMarker() })
                    self.bikes = sortedBikes
                case .failure:
                    break
                }
            }
            .store(in: &cancellables)
        
        worker.bikeTripDataPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] result in
                switch result {
                case .success(let data):
                    self?.tripData = data
                    if data.action == .TripEnded {
                        self?.loadBalance()
                    }
                case .failure(let error):
                    self?.errorMessage = error.message
                }
                
            }
            .store(in: &cancellables)
        
        worker.socketDataLoggingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                if self?.tripData?.data != nil {
                    self?.getBikeState()
                }
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
    
    func loadBikes(currentLocation: CLLocationCoordinate2D) {
        worker.loadBikes(currentLocation: currentLocation)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] bikes in
                let currentLocation = currentLocation.clLocation
                
                let sortedBikes = bikes.sorted(by: { $0.coordinate.clLocation.distance(from: currentLocation) < $1.coordinate.clLocation.distance(from: currentLocation) })
                self?.bikesMarkers = sortedBikes.compactMap({ $0.toGMSMarker() })
                self?.bikes = sortedBikes
            }
            .store(in: &cancellables)
    }
    
    func scanBike(code: String, location: CLLocationCoordinate2D) {
        worker.scanBike(code: code, location: location)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] data in
                self?.scanData = data
            }
            .store(in: &cancellables)
    }
    
    func getBikeState() {
        worker.getBikeState()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] data in
                self?.tripData = data
                UserManager.share.isHaveBikeTrip = data.data != nil
            }
            .store(in: &cancellables)
    }
    
    func bookBike(id: String, location: CLLocationCoordinate2D) {
        worker.bookBike(id: id, location: location)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] data in
                self?.getBikeState()
            }
            .store(in: &cancellables)
    }
    
    func cancelBikeBooking(id: String) {
        worker.cancelBikeBooking(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] data in
                self?.getBikeState()
            }
            .store(in: &cancellables)
    }
    
    func getMapZones() {
        worker.getMapZones()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] zones in
                self?.mapZones = zones
            }
            .store(in: &cancellables)
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
    
    func socketConnect() {
        worker.socketConnect()
    }
    
    func updateMyLocation() {
        startLocation = nil
        locationManager.sendLastLocation()
    }
    
    override func receive(message: MessageKey) {
        loadBalance()
    }
    
    override func unsubscribe() {
        messageService.unsubscribe(self, from: .balanceUpdated)
    }
}
