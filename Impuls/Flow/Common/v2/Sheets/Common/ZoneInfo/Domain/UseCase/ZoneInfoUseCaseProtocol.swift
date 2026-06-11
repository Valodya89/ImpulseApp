//
//  ZoneInfoUseCaseProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 19.07.23.
//

import Foundation

protocol ZoneInfoUseCaseProtocol {
    func getZoneInfo() async throws -> Result<[ZoneInfo], MimoError>
}
