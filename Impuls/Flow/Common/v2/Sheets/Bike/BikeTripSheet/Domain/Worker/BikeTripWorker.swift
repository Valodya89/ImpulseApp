//
//  BikeTripWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 08.08.23.
//

import Foundation
import CoreLocation
import Combine

class BikeTripWorker: BikeTripWorkerProtocol {
    private let useCase: BikeTripUseCaseProtocol
    private let homeRepository = HomeRepository()
    
    var addressPublisher: AnyPublisher<String, Never> {
        return addressSubject.eraseToAnyPublisher()
    }
    
    private let addressSubject = PassthroughSubject<String, Never>()
    
    init(useCase: BikeTripUseCaseProtocol) {
        self.useCase = useCase
    }
    
    func getAddress(for coordinate: CLLocationCoordinate2D, fullAddress: Bool) async {
        guard let address = try? await useCase.getAddress(for: coordinate, fullAddress: fullAddress) else { return }
        
        addressSubject.send(address)
    }
    
    func unlockBike(id: String) -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.homeRepository.unlockBikeTrip(id: id) { result in
                    switch result {
                    case .success(let data):
                        promise(.success(data))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
