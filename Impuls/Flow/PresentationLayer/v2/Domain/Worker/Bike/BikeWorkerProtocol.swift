//
//  BikeWorkerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 19.07.23.
//

import Foundation
import Combine
import CoreLocation

protocol BikeWorkerProtocol {
    
    var bikesPublisher: AnyPublisher<Result<[BikeResult], Error>, Never> { get }
    var bikeTripDataPublisher: AnyPublisher<Result<TripActionModel, MimoError>, Never> { get }
    var socketDataLoggingPublisher: AnyPublisher<Void, Never> { get }
    
    func loadBalance() -> AnyPublisher<WalletModel, MimoError>
    func loadFinancialState() -> AnyPublisher<FinancialStateModel, MimoError>
    func loadBikes(currentLocation: CLLocationCoordinate2D) -> AnyPublisher<[BikeResult], MimoError>
    func scanBike(code: String, location: CLLocationCoordinate2D) -> AnyPublisher<TripActionModel, MimoError>
    func getBikeState() -> AnyPublisher<TripActionModel, MimoError>
    func bookBike(id: String, location: CLLocationCoordinate2D) -> AnyPublisher<Void, MimoError>
    func cancelBikeBooking(id: String) -> AnyPublisher<Void, MimoError>
    func getMapZones() -> AnyPublisher<[Zone], MimoError>
    func isMimoUser(phoneNumber: String, completion: @escaping (MimoUserCheckModel?) -> Void) async
    func inviteUser(phoneNumber: String) -> AnyPublisher<Void, MimoError>
    func getNews() -> AnyPublisher<[NewsObject], MimoError>
    func getUser() -> AnyPublisher<UserResponse, MimoError>
    
    func socketConnect()
    func subscribeToBikeStateChange()
}
