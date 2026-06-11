//
//  EVChargerProvider.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 07.03.25.
//


class EVChargerProvider: EVChargerFactory {
    func createEVMapFilterViewModel(coordinator: EVChargerCoordinator, selectedFilters: SelectedFilters) -> MapFiltersViewModel {
        let viewModel = MapFiltersViewModel(coordinator: coordinator, selectedFilters: selectedFilters)
        return viewModel
    }
    
    func createEVChargerDetailViewModel(coordinator: EVChargerCoordinator, id: String, byStationId: Bool) -> EVChargerDetailsViewModel {
        let viewModel = EVChargerDetailsViewModel(
            coordinator: coordinator,
            id: id,
            byStationId: byStationId,
            evChargerWorker: Resolver.resolve(),
            walletWorker: Resolver.resolve(),
            locationManager: Resolver.resolve()
        )
        return viewModel
    }
    
    func createEVOnboardingViewModel(coordinator: EVChargerCoordinator) -> EVOnboardingViewModel {
        let viewModel = EVOnboardingViewModel(coordinatoor: coordinator, worker: Resolver.resolve())
        return viewModel
    }
    
    func createChargerAmountViewModel(coordinator: EVChargerCoordinator, station: EVChargingStation, connector: EVChargingConnector, isPopToMain: Bool) -> SelectAmountViewModel {
        let viewModel = SelectAmountViewModel(coordinatoor: coordinator, station: station, connector: connector, isPopToMain: isPopToMain)
        return viewModel
    }
    
    func createChargingSessionViewModel(coordinator: EVChargerCoordinator, id: String) -> ChargingSessionViewModel {
        return ChargingSessionViewModel(coordinator: coordinator, worker: Resolver.resolve(), id: id)
    }
    
    func createSuccessViewModel(coordinator: EVChargerCoordinator, chargingInfo: ChargingListDto) -> EVSuccessViewModel {
        return EVSuccessViewModel(coordinatoor: coordinator, chargingInfo: chargingInfo)
    }
}
