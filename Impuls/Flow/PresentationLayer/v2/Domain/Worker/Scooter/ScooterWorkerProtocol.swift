//
//  ScooterWorkerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 12.05.23.
//

import Foundation
import Combine
import CoreLocation

protocol ScooterWorkerProtocol {
    var scooterTripDataPublisher: AnyPublisher<ScooterStateModel?, Never> { get }
    var scootersDataPublisher: AnyPublisher<[ScooterResult], Never> { get }
    var socketDataLoggingPublisher: AnyPublisher<Void, Never> { get }
    
    func loadScooters(currentLocation: CLLocationCoordinate2D) -> AnyPublisher<[ScooterResult], MimoError>
    func loadParkings() -> AnyPublisher<[ParkingResponse], MimoError>
    func loadZones() -> AnyPublisher<[Zone], MimoError>
    func loadBalance() -> AnyPublisher<WalletModel, MimoError>
    func loadFinancialState() -> AnyPublisher<FinancialStateModel, MimoError>
    func getUser() -> AnyPublisher<UserResponse, MimoError>
    
    func fetchScooterState() -> AnyPublisher<[ScooterStateModel], MimoError>
    func bookScooter(id: String, location: CLLocationCoordinate2D) -> AnyPublisher<Void, MimoError>
    func cancelBooking(id: String) -> AnyPublisher<Void, MimoError>
    func inviteUser(phoneNumber: String) -> AnyPublisher<Void, MimoError>
    func isMimoUser(phoneNumber: String, completion: @escaping (MimoUserCheckModel?) -> Void) async
    func getNews() -> AnyPublisher<[NewsObject], MimoError>
    
    func lockLeasedScooter(id: String) -> AnyPublisher<Void, MimoError>
    func unlockLeasedScooter(id: String) -> AnyPublisher<Void, MimoError>
    func openBatteryCover(id: String) -> AnyPublisher<Void, MimoError>
    
    func socketConnect()
}
