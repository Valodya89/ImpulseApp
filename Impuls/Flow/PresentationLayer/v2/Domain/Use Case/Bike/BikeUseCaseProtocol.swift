//
//  BikeUseCaseProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 19.07.23.
//

import Foundation
import CoreLocation

protocol BikeUseCaseProtocol {
    func isMimoUser(phoneNumber: String) async -> Result<MimoUserCheckModel, MimoError>
}
