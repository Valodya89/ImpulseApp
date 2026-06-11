//
//  MimoSplashWorkerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 03.09.23.
//

import Combine

protocol MimoSplashWorkerProtocol {
    
    var isUserLoggedIn: Bool { get }
    var isAccountComplated: Bool { get }
    
    func getTranslations(languageCode: String) -> AnyPublisher<[String: String], Never>
    func getLanguages() -> AnyPublisher<[LanguageResult], Error>
    
    func getActiveScooters() -> AnyPublisher<[ScooterStateModel], MimoError>
    func getActiveBikes() -> AnyPublisher<TripActionModel?, MimoError>
    func getActiveChargers() -> AnyPublisher<[RentedCharger], MimoError>
    func getActiveEvChargers() -> AnyPublisher<[EVStateMessagedDTO], MimoError>
}
