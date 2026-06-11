//
//  ScooterUseCaseProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 12.05.23.
//

import Foundation
import CoreLocation

protocol ScooterUseCaseProtocol {
    func isMimoUser(phoneNumber: String) async -> Result<MimoUserCheckModel, MimoError>
}
