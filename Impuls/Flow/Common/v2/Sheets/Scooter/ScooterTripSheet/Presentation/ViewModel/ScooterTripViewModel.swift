//
//  ScooterTripViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 04.06.23.
//

import Foundation
import Combine
import CoreLocation

class ScooterTripViewModel: MimoBaseViewModel {
    
    private var cancellables = Set<AnyCancellable>()
    private let worker: ScooterTripWorkerProtocol
    private let messageService: MessageServiceProtocol
    
    @Published var trips: [ScooterStateModel]
    @Published var scooterDetails: [SingleScooterResponse] = []
    @Published var speedTarifChanged: Bool = false
    
    var pausedScooter: CurrentValueSubject<ScooterStateModel?, Never> = .init(nil)
    var continueScooter: CurrentValueSubject<ScooterStateModel?, Never> = .init(nil)
    
    private var pauseId: String?
    
    var parkingLocations: [CLLocationCoordinate2D] = []
    
    init(worker: ScooterTripWorkerProtocol, messageService: MessageServiceProtocol, trips: [ScooterStateModel]) {
        self.worker = worker
        self.messageService = messageService
        self.trips = trips
        super.init()
        
        pausedScooter.send(trips.first(where: { $0.state == .TripPaused }))
    }
    
    func getScooterDetails() {
        let ids = trips.compactMap({ $0.scooter?.qr })
        
        ids.forEach { id in
            worker.getScooterDetails(by: id)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] completion in
                    switch completion {
                    case .failure(let error):
                        self?.errorMessage = error.message
                    default: break
                    }
                } receiveValue: { [weak self] data in
                    self?.scooterDetails.append(data)
                }
                .store(in: &cancellables)
        }
    }
    
    func set(scooterStateModel: ScooterStateModel?) {
        if let scooterStateModel, let index = trips.firstIndex(where: { $0.scooter?.qr == scooterStateModel.scooter?.qr }) {
            trips[index] = scooterStateModel
        }
    }
    
    func pauseScooter(with id: String) {
        self.pauseId = id
        
        worker.pauseScooter(with: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] data in
                self?.pausedScooter.send(data)
                self?.continueScooter.send(nil)
            }
            .store(in: &cancellables)
    }
    
    func continueScooter(with id: String) {
        worker.continueScooter(with: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] data in
                self?.pausedScooter.send(nil)
                self?.continueScooter.send(data)
            }
            .store(in: &cancellables)
    }
    
    func changeSpeedTarif(tripId: String, speedId: String) {
        worker.changeSpeedTarif(tripId: tripId, speedId: speedId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] data in
                self?.speedTarifChanged = true
                self?.messageService.publish(.speedTariffChanged)
            }
            .store(in: &cancellables)
    }
    
    func finishCheck(id: String) -> AnyPublisher<Void, MimoError> {
        worker.checkFinish(id: id)
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
