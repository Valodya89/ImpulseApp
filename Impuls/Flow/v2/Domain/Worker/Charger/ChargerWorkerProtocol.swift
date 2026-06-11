//
//  ChargerWorkerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 20.11.23.
//

import Combine
import CoreLocation

protocol ChargerWorkerProtocol {
    
    var rentedChargerDataPublisher: AnyPublisher<RentedCharger?, Never> { get }
    var socketDataLaggingPublisher: AnyPublisher<Void, Never> { get }
    
    func loadBalance() -> AnyPublisher<WalletModel, MimoError>
    func loadFinancialState() -> AnyPublisher<FinancialStateModel, MimoError>
    func getUser() -> AnyPublisher<UserResponse, MimoError>
    
    func getChargingStations(currentLocation: CLLocationCoordinate2D) -> AnyPublisher<[ChargingStation], MimoError>
    func scan(stationId: String, currentLocation: CLLocationCoordinate2D) -> AnyPublisher<RentedCharger, MimoError>
    func getChargerState() -> AnyPublisher<[RentedCharger], MimoError>
    
    func getNews() -> AnyPublisher<[NewsObject], MimoError>
    
    func socketConnect()
}
