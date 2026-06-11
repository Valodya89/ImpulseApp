//
//  ScooterDetailsWorkerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.05.23.
//

import Foundation
import CoreLocation
import Combine

protocol ScooterDetailsWorkerProtocol {
    
    var addressPublisher: AnyPublisher<String, Never> { get }
    
    func getAddress(for coordinate: CLLocationCoordinate2D, fullAddress: Bool) async
    func ringBookedScooter() -> AnyPublisher<Void, MimoError>
}
