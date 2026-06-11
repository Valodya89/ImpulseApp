//
//  MimoHomeWorkerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.06.23.
//

import Foundation
import Combine
import CoreLocation

protocol MimoHomeWorkerProtocol: AnyObject {
    
    var chargerDataPublisher: AnyPublisher<RentedCharger?, Never> { get }
    
    func loadScooters() -> AnyPublisher<[ScooterResult], MimoError>
    func loadBikes() -> AnyPublisher<[BikeResult], MimoError>
    func loadChargers() -> AnyPublisher<[ChargingStation], MimoError>
    func loadEvChargers() -> AnyPublisher<[EVChargingStation], MimoError>
    func loadBalance() -> AnyPublisher<WalletModel, MimoError>
    func loadFinancialState() -> AnyPublisher<FinancialStateModel, MimoError>
    func checkAppVersion() -> AnyPublisher<Bool, Never>
    func updateDeviceInfo(token: String) -> AnyPublisher<Void, Never>
    
    func getActiveScooters() -> AnyPublisher<[ScooterStateModel], MimoError>
    func getActiveBikes() -> AnyPublisher<TripActionModel?, MimoError>
    func getActiveChargers() -> AnyPublisher<[RentedCharger], MimoError>
    func getActiveEvChargers() -> AnyPublisher<[EVStateMessagedDTO], MimoError>
    
    func getAvailableServices(countryCode: String) -> AnyPublisher<[MimoProductType], MimoError>
    func updateAllowedServices(_ services: [String]) -> AnyPublisher<Void, MimoError>
    
    func getLeasedScooters() -> AnyPublisher<[String], MimoError>
}
