//
//  EVChargerUseCaseProtocol.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/19/25.
//

import Foundation
import CoreLocation

protocol EVChargerUseCaseProtocol {
    func isMimoUser(phoneNumber: String) async -> Result<MimoUserCheckModel, MimoError>
}
