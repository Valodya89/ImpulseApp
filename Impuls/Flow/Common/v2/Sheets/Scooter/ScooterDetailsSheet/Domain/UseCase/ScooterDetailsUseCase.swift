//
//  ScooterDetailsUseCase.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.05.23.
//

import Foundation
import CoreLocation

class ScooterDetailsUseCase: ScooterDetailsUseCaseProtocol {
    
    private let addressHelper: AddressHelperProtocol
    
    init(addressHelper: AddressHelperProtocol) {
        self.addressHelper = addressHelper
    }
    
    func getAddress(for coordinate: CLLocationCoordinate2D, fullAddress: Bool) async throws -> String {
        return try await addressHelper.getAddress(for: coordinate, fullAddress: fullAddress)
    }
}
