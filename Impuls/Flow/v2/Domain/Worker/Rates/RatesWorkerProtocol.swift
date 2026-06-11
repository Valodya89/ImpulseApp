//
//  RatesWorkerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.11.23.
//

import Combine

protocol RatesWorkerProtocol {
    
    func getBikeTariffs() -> AnyPublisher<[TariffModel], MimoError>
    func getBikePackages() -> AnyPublisher<[PackageModel], MimoError>
    func getChargerTariffs() -> AnyPublisher<[ChargerTariff], MimoError>
    func getChargerPackages() -> AnyPublisher<[ChargerPackage], MimoError>
    func activateChargerPackage(id: String) -> AnyPublisher<ActivatedPackage, MimoError>
    func activateBikePackage(id: String) -> AnyPublisher<ActivatedPackage, MimoError>
    func getChargerAccount() -> AnyPublisher<ActivatedPackage?, MimoError>
}
