//
//  ChargingSessionViewModel.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 20.04.25.
//

import Combine
import SwiftUI

final class ChargingSessionItem: ObservableObject, Identifiable, Equatable {
    let id: String
    let stationId: String
    @Published var connectorId: String
    @Published var connectorType: String
    @Published var chargingType: String
    @Published var connectorTypeImageName: String
    @Published var totalPrice: String
    @Published var priceKWt: String
    @Published var speed: String
    @Published var kwtsCharged: String
    @Published var percent: Double
    @Published var isFinishing: Bool

    init(charger: EVStateMessagedDTO) {
        self.id = charger.data.id
        self.stationId = charger.station.id
        self.connectorId = ""
        self.connectorType = ""
        self.chargingType = ""
        self.connectorTypeImageName = ""
        self.totalPrice = ""
        self.priceKWt = ""
        self.speed = ""
        self.kwtsCharged = ""
        self.percent = 0
        self.isFinishing = false
        apply(charger: charger)
    }

    func apply(charger: EVStateMessagedDTO) {
        let connectorIdInt = charger.data.connectorId
        let connector = charger.station.connectors?.first(where: { $0.connectorId == connectorIdInt })

        let total: String
        if let amount = charger.data.price?.amount, let currency = charger.data.price?.currency {
            total = "\(amount) \(currency)"
        } else {
            total = ""
        }

        connectorId = String(connectorIdInt)
        connectorType = connector?.type?.title ?? "--"
        chargingType = connector?.chargingType?.title ?? "--"
        connectorTypeImageName = connector?.type?.iconName ?? "--"
        totalPrice = total
        priceKWt = "\(charger.data.priceConfig.pricePerKWt) \(charger.data.priceConfig.currency)"
        speed = "\(charger.data.powerKw) " + "EV_CHARGER_kw".localized()
        kwtsCharged = "\(charger.data.kwtsCharged) " + "EV_CHARGER_kw".localized()
        percent = charger.data.percent
    }

    static func == (lhs: ChargingSessionItem, rhs: ChargingSessionItem) -> Bool {
        lhs.id == rhs.id
    }
}

class ChargingSessionViewModel: MimoBaseViewModel, ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    var coordinator: EVChargerCoordinator
    private let worker: EVChargerWorker
    private let initialStationId: String
    private var didApplyInitialIndex: Bool = false

    @Published private(set) var sessions: [ChargingSessionItem] = []
    @Published var currentIndex: Int = 0
    @Published private(set) var isInitialLoading: Bool = false

    var isLoading: Bool { sessions.contains(where: { $0.isFinishing }) }

    var currentSession: ChargingSessionItem? {
        guard sessions.indices.contains(currentIndex) else { return nil }
        return sessions[currentIndex]
    }

    init(coordinator: EVChargerCoordinator, worker: EVChargerWorker, id: String) {
        self.coordinator = coordinator
        self.worker = worker
        self.initialStationId = id
        super.init()
    }

    func onAppear() {
        coordinator.navigationController?.isNavigationBarHidden = true
        bindChargerState()
        worker.socketConnect()
        fetchAllSessions()
    }

    func onDisappear() {
    }

    private func fetchAllSessions() {
        isInitialLoading = sessions.isEmpty
        worker.fetchStates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isInitialLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.message
                }
            } receiveValue: { [weak self] states in
                guard let self else { return }
                self.applyAll(states: states)
            }
            .store(in: &cancellables)
    }

    private func applyAll(states: [EVStateMessagedDTO]) {
        let newStatesByID = Dictionary(uniqueKeysWithValues: states.map { ($0.data.id, $0) })

        var keptItems: [ChargingSessionItem] = []
        for existingItem in sessions {
            if let state = newStatesByID[existingItem.id] {
                existingItem.apply(charger: state)
                keptItems.append(existingItem)
            }
        }

        let keptIds = Set(keptItems.map(\.id))
        let appended = states
            .filter { !keptIds.contains($0.data.id) }
            .map { ChargingSessionItem(charger: $0) }
        keptItems.append(contentsOf: appended)

        if sessions.map(\.id) != keptItems.map(\.id) {
            sessions = keptItems
        }

        if !didApplyInitialIndex, !sessions.isEmpty {
            if let idx = sessions.firstIndex(where: { $0.stationId == initialStationId }) {
                currentIndex = idx
            }
            didApplyInitialIndex = true
        } else if currentIndex >= sessions.count {
            currentIndex = max(0, sessions.count - 1)
        }
    }

    private func bindChargerState() {
        worker.chargerState
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] charger in
                guard let self else { return }
                if charger.state == "FINISHED" {
                    self.fetchAndRouteSuccess(sessionId: charger.data.id)
                    return
                }
                self.upsert(charger)
            }
            .store(in: &cancellables)

        worker.socketDataLaggingPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.fetchAllSessions()
            }
            .store(in: &cancellables)
    }

    private func upsert(_ charger: EVStateMessagedDTO) {
        if let item = sessions.first(where: { $0.id == charger.data.id }) {
            item.apply(charger: charger)
        } else {
            sessions.append(ChargingSessionItem(charger: charger))
        }
    }

    func back() {
        coordinator.navigationController?.isNavigationBarHidden = false
        coordinator.navigationController?.tabBarController?.tabBar.isHidden = false
        coordinator.popToRootViewController()
    }

    func wallet() {
        coordinator.routeWalletView()
    }

    func notifications() {
        coordinator.routeNotificationsView()
    }

    func completeSlider(for sessionId: String) {
        finishCharger(sessionId: sessionId)
    }

    private func finishCharger(sessionId: String) {
        guard let item = sessions.first(where: { $0.id == sessionId }) else { return }
        item.isFinishing = true
        print("finish item.id = ", item.id)
        worker.finishCharger(id: item.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    item.isFinishing = false
                    self?.errorMessage = error.message
                }
            } receiveValue: { [weak self] _ in
                self?.worker.socketConnect()
                print("get finished charging data sessionId = ", sessionId)
                
            }
            .store(in: &cancellables)
    }

    private func fetchAndRouteSuccess(sessionId: String) {
        guard let item = sessions.first(where: { $0.id == sessionId }) else { return }
        worker.getCharging(id: item.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    item.isFinishing = false
                    self?.errorMessage = error.message
                }
            } receiveValue: { [weak self] info in
                guard let self else { return }
                self.sessions.removeAll(where: { $0.id == sessionId })
                if self.currentIndex >= self.sessions.count {
                    self.currentIndex = max(0, self.sessions.count - 1)
                }
                self.coordinator.routeToSuccessView(chargingInfo: info)
            }
            .store(in: &cancellables)
    }
}
