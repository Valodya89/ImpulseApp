//
//  BikeDetailsViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.07.23.
//

import Foundation
import Combine
import CoreLocation

class BikeDetailsViewModel: MimoBaseViewModel {
    
    private var cancellables = Set<AnyCancellable>()
    
    private let worker: BikeDetailsWorkerProtocol
    private let locationManager: MimoLocationManagerProtocol
    
    var bikeData: BikeResult?
    var walletInfo: WalletModel?
    var financialState: FinancialStateModel?
    var user: UserResponse?
    
    @Published private(set) var address: String?
    @Published private(set) var currentLocation: CLLocationCoordinate2D?
    @Published var bikeState: TripActionModel?
    
    init(worker: BikeDetailsWorkerProtocol, locationManager: MimoLocationManagerProtocol, data: BikeDetailsData?) {
        self.worker = worker
        self.locationManager = locationManager
        self.bikeData = data?.bikeData
        self.walletInfo = data?.walletInfo
        self.financialState = data?.financialState
        self.user = data?.user
        self.bikeState = data?.bikeState
        super.init()
        
        locationManager.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.currentLocation = location
            }
            .store(in: &cancellables)
        
        worker.addressPublisher
            .receive(on: DispatchQueue.main)
            .sink { address in
                self.address = address
            }
            .store(in: &cancellables)
    }
    
    func getBikeAddress() {
        guard let coordinate = bikeData?.coordinate else { return }
        Task {
            await worker.getAddress(for: coordinate, fullAddress: true)
        }
    }
}
