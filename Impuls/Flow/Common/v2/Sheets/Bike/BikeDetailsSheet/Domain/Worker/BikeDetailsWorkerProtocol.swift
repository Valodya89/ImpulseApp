//
//  BikeDetailsWorkerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.07.23.
//

import Foundation
import CoreLocation
import Combine

protocol BikeDetailsWorkerProtocol {
    var addressPublisher: AnyPublisher<String, Never> { get }
    
    func getAddress(for coordinate: CLLocationCoordinate2D, fullAddress: Bool) async
}
