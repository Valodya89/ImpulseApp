//
//  MimoRatesViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.11.23.
//

import Foundation
import Combine

class MimoRatesViewModel: MimoBaseViewModel {
    
    private var cancellables = Set<AnyCancellable>()
    
    private let worker: RatesWorkerProtocol
    
    private(set) var supportedTypes: [MimoType]
    
    var bikeTariffs: CurrentValueSubject<[TariffModel], Never> = .init([])
    var bikePcakages: CurrentValueSubject<[PackageModel], Never> = .init([])
    
    var chargerTariffs: CurrentValueSubject<[ChargerTariff], Never> = .init([])
    var chargerPackages: CurrentValueSubject<[ChargerPackage], Never> = .init([])
    
    var mimoType: CurrentValueSubject<MimoType, Never>
    var rateType: CurrentValueSubject<RateType, Never> = .init(.tariff)
    
    var chargerDiscounts: [ChargerDiscount] = ChargerDiscount.staticData
    
    var alreadyActivatedChargerPackage: ActivatedPackage?
    
    @Published var activatedPackage: ActivatedPackage?
    @Published var bikeActivatedPackage: ActivatedPackage?
    
    init(worker: RatesWorkerProtocol, supportedTypes: [MimoType], mimoType: MimoType) {
        self.worker = worker
        self.mimoType = CurrentValueSubject(mimoType)
        self.supportedTypes = supportedTypes
        super.init()
        
        switch mimoType {
        case .scooter:
            break
        case .bike:
            getBikeTariffs()
        case .charger:
            break
        case .evCharger:
            break
        }
    }
    
    func rateTypes(for mimoType: MimoType) -> [RateType] {
        switch mimoType {
        case .scooter:
            return [.tariff]
        case .bike:
            return [.tariff, .plan]
        case .charger:
            return [.tariff, .plan, .discounts]
        case .evCharger:
            return [.tariff, .plan, .discounts]
        }
    }
    
    // MARK: - Bike
    func getBikeTariffs() {
        guard bikeTariffs.value.isEmpty else { bikeTariffs.send(bikeTariffs.value); return }
        
        worker.getBikeTariffs()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] tariffs in
                self?.bikeTariffs.send(tariffs)
            }
            .store(in: &cancellables)
    }
    
    func getBikePackages() {
        guard bikePcakages.value.isEmpty else { bikePcakages.send(bikePcakages.value); return }
        
        worker.getBikePackages()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] packages in
                self?.bikePcakages.send(packages)
            }
            .store(in: &cancellables)
    }
    
    func bikePackageActivate(id: String) {
        worker.activateBikePackage(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default:
                    break
                }
            } receiveValue: { [weak self] data in
                self?.bikeActivatedPackage = data
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Charger
    func getChargerTariffs() {
        guard chargerTariffs.value.isEmpty else { chargerTariffs.send(chargerTariffs.value); return }
        
        worker.getChargerTariffs()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] tariffs in
                self?.chargerTariffs.send(tariffs.sorted(by: { $0.order < $1.order }))
            }
            .store(in: &cancellables)
    }
    
    func getChargerPackages() {
        guard chargerPackages.value.isEmpty else { chargerPackages.send(chargerPackages.value); return }
        
        worker.getChargerPackages()
            .combineLatest(worker.getChargerAccount())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default: break
                }
            } receiveValue: { [weak self] packages, activatedPackage in
                self?.alreadyActivatedChargerPackage = activatedPackage
                self?.chargerPackages.send(packages.sorted(by: { $0.duration < $1.duration }))
            }
            .store(in: &cancellables)
    }
    
    func chargerPackageActivate(id: String) {
        worker.activateChargerPackage(id: id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.mimoError = error
                default:
                    break
                }
            } receiveValue: { [weak self] data in
                self?.alreadyActivatedChargerPackage = data
                self?.activatedPackage = data
            }
            .store(in: &cancellables)
    }
    
    func getTariffsForSelectedType() {
        switch mimoType.value {
        case .scooter:
            break
        case .bike:
            getBikeTariffs()
        case .charger:
            getChargerTariffs()
        case .evCharger:
            break
        }
    }
    
    func getPackagesForSelectedType() {
        switch mimoType.value {
        case .scooter:
            break
        case .bike:
            getBikePackages()
        case .charger:
            getChargerPackages()
        case .evCharger:
            break
        }
    }
}

enum RateType: Int {
    case tariff
    case plan
    case discounts
}
