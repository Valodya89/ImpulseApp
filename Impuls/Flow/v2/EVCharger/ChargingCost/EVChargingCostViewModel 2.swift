//
//  EVChargingCostViewModel.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 2/28/25.
//

import Foundation
import Combine

final class EVChargingCostViewModel: MimoBaseViewModel, ObservableObject {
    var coordinator: EVChargerCoordinator
    private var cancellables = Set<AnyCancellable>()
    private let worker: EVChargerWorkerProtocol
    
    @Published var rating: Int = 0

    init(coordinator: EVChargerCoordinator, id: String, worker: EVChargerWorkerProtocol) {
        self.coordinator = coordinator
        self.worker = worker
        super.init()
    }
    
    func back() {
        coordinator.popViewController()
    }
    
    func `continue`() {
      
    }
}
