//
//  EVChargerCoordinator.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 07.03.25.
//

import SwiftUI

class EVChargerCoordinator: BaseCoordinator {
    
    var provider: EVChargerProvider
    
    init(navigationController: UINavigationController? = nil, provider: EVChargerProvider) {
        self.provider = provider
        super.init(navigationController: navigationController)
    }
    
    func start(selectedId: String? = nil, scanedStation: (EVChargingStation?, EVChargingConnector?), isFromFastDecision: Bool) {
        if let selectedId {
            if !isFromFastDecision {
                showChargingSessionView(id: selectedId)
            } else {
                if let evChargerViewController: EVChargerMapViewController = UIStoryboard(name: "EVCharger", bundle: nil).instantiate() {
                    let viewModel: EVChargerMapViewModel? = Resolver.optional(args: ["preSelectedId": selectedId])
                    viewModel?.coordinator = self
                    evChargerViewController.viewModel = viewModel
                    navigationController?.pushViewController(evChargerViewController, animated: true)
                }
            }
        } else if let station = scanedStation.0, let connector = scanedStation.1 {
            routeToSelectAmountView(station: station, connector: connector, isPopToMain: true)
        } else {
            if let evChargerViewController: EVChargerMapViewController = UIStoryboard(name: "EVCharger", bundle: nil).instantiate() {
                let viewModel: EVChargerMapViewModel? = Resolver.optional(args: ["preSelectedId": scanedStation.0?.id])
                viewModel?.coordinator = self
                evChargerViewController.viewModel = viewModel
                navigationController?.pushViewController(evChargerViewController, animated: true)
            }
        }
        
        navigationController?.isNavigationBarHidden = false
        navigationController?.tabBarController?.tabBar.isHidden = true
    }
    
    func popToMainScreen() {
        popViewController()
        navigationController?.isNavigationBarHidden = false
        navigationController?.tabBarController?.tabBar.isHidden = false
    }
    
    func routeWalletView() {
        presentViewController(Destination.wallet(MimoWalletViewModel(worker: Resolver.resolve(), productType: .evCharger)).contentView)
    }
    
    func routeNotificationsView() {
        let notListVC = NotificationListViewController.initFromStoryboard(name: Constant.Storyboards.home)
        let navVC = UINavigationController(rootViewController: notListVC)
        
        presentViewController(navVC)
    }
    
    func routeEVChargerDetailView(id: String, byStationId: Bool = false) {
        presentViewController(Destination.detail(provider.createEVChargerDetailViewModel(coordinator: self, id: id, byStationId: byStationId)).contentView)
    }
    
    func routeEVChargerFilter(selectedFilters: SelectedFilters) {
        presentViewController(Destination.filter(provider.createEVMapFilterViewModel(coordinator: self, selectedFilters: selectedFilters)).contentView)
    }
    
    func routeOnBoardingview() {
        presentViewController(Destination.onboarding(provider.createEVOnboardingViewModel(coordinator: self)).contentView)
    }
    
    func routeToSelectAmountView(station: EVChargingStation, connector: EVChargingConnector, isPopToMain: Bool) {
        pushViewController(Destination.chargerAmount(provider.createChargerAmountViewModel(coordinator: self, station: station, connector: connector, isPopToMain: isPopToMain)).contentView)
    }
    
    func routeToSuccessView(chargingInfo: ChargingListDto) {
        pushViewController(Destination.succsess(provider.createSuccessViewModel(coordinator: self, chargingInfo: chargingInfo)).contentView)
    }
    
    func showChargingSessionView(id: String) {
        pushViewController(Destination.chargingSession(provider.createChargingSessionViewModel(coordinator: self, id: id)).contentView)
    }
}

extension EVChargerCoordinator {
    
    enum Destination: Routable {
        case filter(MapFiltersViewModel)
        case detail(EVChargerDetailsViewModel)
        case onboarding(EVOnboardingViewModel)
        case chargerAmount(SelectAmountViewModel)
        case chargingSession(ChargingSessionViewModel)
        case wallet(MimoWalletViewModel)
        case succsess(EVSuccessViewModel)
        
        @ViewBuilder
        var contentView: some View {
            switch self {
            case .filter(let viewModel):
                MapFiltersView(viewModel: viewModel)
            case .detail(let viewModel):
                EVChargerDetailsView(viewModel: viewModel)
            case .onboarding(let viewModel):
                EVOnboardingView(viewModel: viewModel)
            case .chargerAmount(let viewModel):
                SelectAmountView(viewModel: viewModel)
            case .chargingSession(let viewModel):
                ChargingSessionView(viewModel: viewModel)
            case .wallet(let viewModel):
                WalletView(viewModel: viewModel)
            case .succsess(let viewModel):
                EVChargerSuccessView(viewModel: viewModel)
            }
        }
        
        var id: String {
            switch self {
            case .filter:
                return "EV_Filter"
            case .detail:
                return "EV_Detail"
            case .onboarding:
                return "EV_Onboarding"
            case .chargerAmount:
                return "EV_ChargerAmount"
            case .chargingSession:
                return "EV_ChargingSession"
            case .wallet:
                return "EV_Wallet"
            case .succsess:
                return "EV_Succsess"
            }
        }
        
        static func == (lhs: Destination, rhs: Destination) -> Bool {
            return lhs.id == rhs.id
        }
    }
}
