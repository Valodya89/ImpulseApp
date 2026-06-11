//
//  SelectAmountViewModel.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 25.03.25.
//

import Foundation
import Combine

class SelectAmountViewModel: MimoBaseViewModel, ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let worker: EVChargerWorkerProtocol = Resolver.resolve()
    private let coordinatoor: EVChargerCoordinator
    private let station: EVChargingStation
    let connector: EVChargingConnector
    @Published private(set) var isLoading: Bool = false
    @Published var showAttentionAlert: Bool = false
    @Published var heightOnChanged: CGFloat = 1
    @Published var selectedOption: Bool = true
    @Published var price: String = ""
    let minValue = 0
    let maxValue = 100
    let priceKW: Double
    let currency: String
    let isPopToMain: Bool
//    var sessionCounter = 0
    var chargingId: String?
    
    init(coordinatoor: EVChargerCoordinator, station: EVChargingStation, connector: EVChargingConnector, isPopToMain: Bool) {
        self.coordinatoor = coordinatoor
        self.station = station
        self.connector = connector
        self.priceKW = connector.pricePerKW
        self.currency = station.currency.currencySymbol
        self.isPopToMain = isPopToMain
        super.init()
        
        fillData()
    }
    
    private func fillData() {
        price = "\(station.currency.currencySymbol) \(priceKW.description)/" + "EV_CHARGER_kw".localized()
    }
    
    func onAppear() {
        coordinatoor.navigationController?.isNavigationBarHidden = true
        if cancellables.isEmpty {
            bindChargerState()
        }
    }
    
    func back() {
        if isPopToMain {
            coordinatoor.popToMainScreen()
        } else {
            coordinatoor.popViewController()
        }
    }
    
    func attetionOkTapped() {
        back()
    }
    
    func showChargingSessionView() {
        coordinatoor.showChargingSessionView(id: connector.stationId ?? "")
    }
    
    func startCharging() {
        isLoading = true
        worker.startCharging(id: connector.stationId ?? station.id, connectorId: connector.id, kwts: Double(heightOnChanged) * Double(maxValue))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                    self?.isLoading = false
                default: break
                }
            } receiveValue: { [weak self] (station, chargingModel) in
                print("station: \(station)")
                print("chargingModel: \(chargingModel)")
                self?.chargingId = chargingModel.id
                self?.showChargingSessionView()
//                self?.worker.startPolling(for: station.id, timeinterval: 15)
            }
            .store(in: &cancellables)
    }
    
    func bindChargerState() {
        worker.chargerState
            .compactMap { $0 }
            .first(where: { $0.state == "CHARGING" })
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isLoading = false
//                self?.showChargingSessionView()
            }.store(in: &cancellables)
        
        worker.chargingFinished
            .receive(on: DispatchQueue.main)
            .sink { [weak self] charger in
                guard let self = self else { return }
//                self.sessionCounter += 1
//                if self.sessionCounter >= 4 {
//                    self.sessionCounter = 0
//                    self.worker.stopPolling()
//                    self.isLoading = false
//                    self.showAttentionAlert = true
//                }
                
                self.getChargingInfo()
                
            }.store(in: &cancellables)
    }
    
    private func getChargingInfo() {
        guard let chargingId else {
//            self.worker.stopPolling()
            self.isLoading = false
            return
        }
        
        worker.getCharging(id: chargingId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                switch completion {
                case .failure(let error):
                    self.isLoading = false
                    self.errorMessage = error.message
                case .finished:
                    break
                }
            } receiveValue: { [weak self] chargingInfo in
                guard let self else { return }
                print("Get Charging info")
                
//                self.worker.stopPolling()
                self.isLoading = false
                
                switch chargingInfo.state {
                case .failed:
                    self.showAttentionAlert = true
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
}
