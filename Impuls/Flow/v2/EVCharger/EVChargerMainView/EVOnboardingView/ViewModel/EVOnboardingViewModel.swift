//
//  EVOnboardingViewModel.swift
//  MimoBike
//
//  Created by Yurka Babayan on 09.03.25.
//

import Foundation
import SwiftUI
import Combine

final class EVOnboardingViewModel: MimoBaseViewModel, ObservableObject {
    
    private let coordinatoor: EVChargerCoordinator
    private var cancellables = Set<AnyCancellable>()
    private let worker: EVChargerWorkerProtocol
    @Published var items: [EVOnboardingModel] = []
    @Published var currentPage = 0
    
    init(coordinatoor: EVChargerCoordinator, worker: EVChargerWorkerProtocol) {
        self.coordinatoor = coordinatoor
        self.worker = worker
        super.init()
        
        fetchOnboardingData()
    }
    
    func back() {
        coordinatoor.dissmiss()
    }
    
    private func fetchOnboardingData() {
        worker.getGuide()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] guides in
                self?.items = guides.slides
                    .sorted { $0.sort < $1.sort }
                    .compactMap { EVOnboardingModel(id: $0.sort - 1, image: $0.image.url, title: $0.title, subTitle: $0.description) }
                print("guides: \(guides)")
            }
            .store(in: &cancellables)
    }
}
