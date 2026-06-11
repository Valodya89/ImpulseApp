//
//  ScooterDetailsWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.05.23.
//

import Foundation
import Combine
import CoreLocation

class ScooterDetailsWorker: ScooterDetailsWorkerProtocol {
    
    private let useCase: ScooterDetailsUseCaseProtocol
    private let homeRepasitory = HomeRepository()
    
    var addressPublisher: AnyPublisher<String, Never> {
        return addressSubject.eraseToAnyPublisher()
    }
    
    private let addressSubject = PassthroughSubject<String, Never>()
    
    init(useCase: ScooterDetailsUseCaseProtocol) {
        self.useCase = useCase
    }
    
    func getAddress(for coordinate: CLLocationCoordinate2D, fullAddress: Bool) async {
        guard let address = try? await useCase.getAddress(for: coordinate, fullAddress: fullAddress) else { return }
        
        addressSubject.send(address)
    }
    
    func ringBookedScooter() -> AnyPublisher<Void, MimoError> {
        Deferred {
            Future<Void, MimoError> { promise in
                self.homeRepasitory.beepBookedScooter { result in
                    switch result {
                    case .success:
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(.init(error: error)))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
