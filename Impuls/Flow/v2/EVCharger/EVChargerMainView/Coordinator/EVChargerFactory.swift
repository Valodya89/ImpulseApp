//
//  EVChargerFactory.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 07.03.25.
//

protocol EVChargerFactory {
    func createEVMapFilterViewModel(coordinator: EVChargerCoordinator, selectedFilters: SelectedFilters) -> MapFiltersViewModel
    func createEVChargerDetailViewModel(coordinator: EVChargerCoordinator, id: String, byStationId: Bool) -> EVChargerDetailsViewModel
    func createEVOnboardingViewModel(coordinator: EVChargerCoordinator) -> EVOnboardingViewModel
    func createChargerAmountViewModel(coordinator: EVChargerCoordinator, station: EVChargingStation, connector: EVChargingConnector, isPopToMain: Bool) -> SelectAmountViewModel
    func createChargingSessionViewModel(coordinator: EVChargerCoordinator, id: String) -> ChargingSessionViewModel
}
