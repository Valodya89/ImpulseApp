//
//  AddressHelperProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.05.23.
//

import Foundation
import CoreLocation

protocol AddressHelperProtocol {
    
    func getAddress(for coordinate: CLLocationCoordinate2D, fullAddress: Bool) async throws -> String
}
