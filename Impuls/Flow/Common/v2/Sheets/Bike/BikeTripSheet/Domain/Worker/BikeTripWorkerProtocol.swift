//
//  BikeTripWorkerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 08.08.23.
//

import Foundation
import CoreLocation
import Combine

protocol BikeTripWorkerProtocol {
    var addressPublisher: AnyPublisher<String, Never> { get }
    
    func getAddress(for coordinate: CLLocationCoordinate2D, fullAddress: Bool) async
    func unlockBike(id: String) -> AnyPublisher<Void, MimoError>
}
