//
//  BikeTripUseCase.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 08.08.23.
//

import Foundation
import CoreLocation

class BikeTripUseCase: BikeTripUseCaseProtocol {
    
    private let addressHelper: AddressHelperProtocol
    
    init(addressHelper: AddressHelperProtocol) {
        self.addressHelper = addressHelper
    }
    
    func getAddress(for coordinate: CLLocationCoordinate2D, fullAddress: Bool) async throws -> String {
        return try await addressHelper.getAddress(for: coordinate, fullAddress: fullAddress)
    }
}
