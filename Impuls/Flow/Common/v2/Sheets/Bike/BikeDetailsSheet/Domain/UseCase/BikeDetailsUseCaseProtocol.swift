//
//  BikeDetailsUseCaseProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.07.23.
//

import Foundation
import CoreLocation

protocol BikeDetailsUseCaseProtocol {
    func getAddress(for coordinate: CLLocationCoordinate2D, fullAddress: Bool) async throws -> String
}
