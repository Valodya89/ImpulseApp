//
//  BikeDetailsWorker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.07.23.
//

import Foundation
import Combine
import CoreLocation

class BikeDetailsWorker: BikeDetailsWorkerProtocol {
    
    private let useCase: BikeDetailsUseCaseProtocol
    
    var addressPublisher: AnyPublisher<String, Never> {
        return addressSubject.eraseToAnyPublisher()
    }
    
    private let addressSubject = PassthroughSubject<String, Never>()
    
    init(useCase: BikeDetailsUseCaseProtocol) {
        self.useCase = useCase
    }
    
    func getAddress(for coordinate: CLLocationCoordinate2D, fullAddress: Bool) async {
        guard let address = try? await useCase.getAddress(for: coordinate, fullAddress: fullAddress) else { return }
        
        addressSubject.send(address)
    }
}
