//
//  ZoneInfoWorkerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 19.07.23.
//

import Foundation
import Combine

protocol ZoneInfoWorkerProtocol {
    
    var zoneInfoPublisher: AnyPublisher<Result<[ZoneInfo], MimoError>, Never> { get }
    
    func getZoneInfo() async
}
