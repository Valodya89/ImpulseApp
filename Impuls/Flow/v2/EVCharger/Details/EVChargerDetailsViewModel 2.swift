//
//  EVChargerDetailsViewModel.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/25/25.
//

import Foundation
import Combine
import CoreLocation
import SwiftUI
import UIKit

final class EVChargerDetailsViewModel: MimoBaseViewModel, ObservableObject {
    private var BAG = Set<AnyCancellable>()
    
    var coordinator: EVChargerCoordinator
    private var cancellables = Set<AnyCancellable>()
    private let evChargerWorker: EVChargerWorkerProtocol
    private let walletWorker: WalletWorkerProtocol
    private let locationManager: MimoLocationManagerProtocol
    private let stationId: String
    @Published private(set) var station: EVChargingStation?
    @Published private(set) var feedbacks: [EVStationFeedback] = []
    @Published var selectedMediaIcon: Int?
    @Published var selectedLogoIconURL: URL?
    let cardWidth: CGFloat = UIScreen.screenWidth - 80
    
    private(set) var user: UserResponse?
    @Published private(set) var wallet: WalletModel?
    @Published private(set) var financialState: FinancialStateModel?
    
    @Published private(set) var currency: String = ""
    @Published private(set) var balance: String = "0.0"
    @Published private(set) var isBalanceNegative: Bool = false
    @Published private(set) var freeMinutes: String = "0"
    
    @Published private(set) var distance: String = ""
    
    @State private var showVC = false
    
    init(
        coordinator: EVChargerCoordinator,
        id: String,
        evChargerWorker: EVChargerWorkerProtocol,
        walletWorker: WalletWorkerProtocol,
        locationManager: MimoLocationManagerProtocol
    ) {
        self.coordinator = coordinator
        self.evChargerWorker = evChargerWorker
        self.walletWorker = walletWorker
        self.locationManager = locationManager
        self.stationId = id
        super.init()
        
        loadData()
        
        locationManager.locationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentLocation in
                guard let self,
                      let stationCoordinate = station?.coordinate
                else { return }
                
                let distance = currentLocation.distance(to: stationCoordinate)
                self.distance = "MOBILE_global_distance".localized() + ": \(distance.prettyDistance)"
            }
            .store(in: &cancellables)
        locationManager.sendLastLocation()
    }
    
    func loadData() {
        Publishers.Zip5(
            evChargerWorker.getChargingStationDetailed(id: stationId),
            walletWorker.loadBalance(),
            walletWorker.loadFinancialState(),
            walletWorker.getUser(),
            walletWorker.getAccount()
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            if case .failure(let error) = completion {
                self?.mimoError = error
            }
        } receiveValue: { [weak self] stationData, wallet, financialState, user, account in
            self?.handleWalletResponse(wallet: wallet, financialState: financialState)
            
            self?.user = user
            self?.freeMinutes = String(format: "%.1f", account.minutes ?? 0)
            
            self?.station = stationData.0
            self?.feedbacks = stationData.1
        }
        .store(in: &BAG)
    }
    
    func getChargingStation(id: String) {
        evChargerWorker.getChargingStationDetailed(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] (station, feedbacks) in
                self?.station = station
                self?.feedbacks = feedbacks
                print("station: \(station)")
            }
            .store(in: &cancellables)
    }
    
    private func handleWalletResponse(wallet: WalletModel, financialState: FinancialStateModel) {
        self.wallet = wallet
        self.financialState = financialState
        
        self.currency = wallet.currency.currencySymbol
        
        let balance = (wallet.balance - (financialState.additional ?? 0))
        self.balance = String(format: "%.2f", balance)
        self.isBalanceNegative = balance < 0
    }
    
    
    func connectorTapped(connector: EVChargingConnector) {
        guard connector.state == .available || connector.state == .preparing, let station else { return }
        
        coordinator.dissmiss(isAnimated: true)
        coordinator.routeToSelectAmountView(station: station, connector: connector, isPopToMain: false)
    }
}
