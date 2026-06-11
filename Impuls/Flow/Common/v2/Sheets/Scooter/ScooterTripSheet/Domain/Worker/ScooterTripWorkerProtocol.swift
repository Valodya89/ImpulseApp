//
//  ScooterTripWorkerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 04.06.23.
//

import Foundation
import Combine

protocol ScooterTripWorkerProtocol: AnyObject {
    
    func getScooterDetails(by id: String) -> AnyPublisher<SingleScooterResponse, MimoError>
    func pauseScooter(with id: String) -> AnyPublisher<ScooterStateModel, MimoError>
    func continueScooter(with id: String) -> AnyPublisher<ScooterStateModel, MimoError>
    func changeSpeedTarif(tripId: String, speedId: String) -> AnyPublisher<Bool, MimoError>
    func checkFinish(id: String) -> AnyPublisher<Void, MimoError>
}
