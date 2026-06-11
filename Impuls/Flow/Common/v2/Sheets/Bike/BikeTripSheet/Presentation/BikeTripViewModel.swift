//
//  BikeTripViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 08.08.23.
//

import Foundation
import CoreLocation
import Combine

class BikeTripViewModel: MimoBaseViewModel {
    
    private var cancellables = Set<AnyCancellable>()
    private let worker: BikeTripWorkerProtocol
    
    @Published var tripData: TripActionModel
    @Published private(set) var address: String?
    
    init(worker: BikeTripWorkerProtocol, data: TripActionModel) {
        self.worker = worker
        self.tripData = data
        
        super.init()
        
        worker.addressPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] address in
                self?.address = address
            }
            .store(in: &cancellables)
    }
    
    func getBikeAddress() {
        guard let latitude = tripData.bikeDto?.latitude,
              let longitude = tripData.bikeDto?.longitude else { return }
        Task {
            await worker.getAddress(for: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                    fullAddress: true)
        }
    }
    
    func unlockBike() {
        guard let id = tripData.data?.id else { return }
        
        worker.unlockBike(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] _ in
                
            }
            .store(in: &cancellables)

    }
}
