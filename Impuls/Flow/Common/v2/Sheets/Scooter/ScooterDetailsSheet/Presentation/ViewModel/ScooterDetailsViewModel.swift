//
//  ScooterDetailsViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.05.23.
//

import Foundation
import Combine
import CoreLocation

class ScooterDetailsViewModel: MimoBaseViewModel {
    
    private let worker: ScooterDetailsWorkerProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    var scooterData: ScooterResult?
    var scooterState: ScooterStateModel?
    var walletInfo: WalletModel?
    var financialState: FinancialStateModel?
    var user: UserResponse?
    let hasLeasedScooters: Bool
    
    @Published private(set) var address: String?
    
    init(
        worker: ScooterDetailsWorkerProtocol,
        scooterData: ScooterResult?,
        scooterState: ScooterStateModel?,
        hasLeasedScooters: Bool?,
        walletInfo: WalletModel?,
        financialState: FinancialStateModel?,
        user: UserResponse?
    ) {
        self.worker = worker
        self.scooterData = scooterData
        self.scooterState = scooterState
        self.walletInfo = walletInfo
        self.financialState = financialState
        self.user = user
        self.hasLeasedScooters = hasLeasedScooters ?? false
        
        super.init()
        
        worker.addressPublisher
            .receive(on: DispatchQueue.main)
            .sink { address in
                self.address = address
            }
            .store(in: &cancellables)
    }
    
    func getScooterAddress() {
        guard let latitude = scooterData?.latitude ?? scooterState?.scooter?.located?.latitude,
                let longitude = scooterData?.longitude ?? scooterState?.scooter?.located?.longitude else { return }
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        Task {
            await worker.getAddress(for: coordinate, fullAddress: true)
        }
    }
    
    func beepBookedScooter() -> AnyPublisher<Void, Never> {
        worker.ringBookedScooter()
            .replaceError(with: ())
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
