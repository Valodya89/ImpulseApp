//
//  BikeTripUseCaseProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 08.08.23.
//

import Foundation
import CoreLocation

protocol BikeTripUseCaseProtocol {
    
    func getAddress(for coordinate: CLLocationCoordinate2D, fullAddress: Bool) async throws -> String
}
