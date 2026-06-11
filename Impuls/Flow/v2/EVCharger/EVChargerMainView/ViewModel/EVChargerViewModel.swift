//
//  EVChargerViewModel.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 25.02.25.
//

import SwiftUI

class EVChargerViewModel: ObservableObject {
    
    var navigationController: UINavigationController?
    @Published var bottomview: BottomViewState = .orderNearest
    @Published var presentFilterSheet: Bool = false
    @Published var presntDetailSheet: Bool = false
    @Published var presentChargingViewFullScreen: Bool = false
    @Published var presentAddresSearchView: Bool = false
    @Published var text: String = ""
    @Published var selectedAdres: AddresItemModel?

    var filterViewModel: MapFiltersViewModel?
    var detailViewModel: EVChargerDetailsViewModel?
    var chargingInfoViewModel: EVChargingInfoViewModel?
    var addressSearchViewModel: AddressSearchViewModel?
    var requestEVChargerViewModel: RequestEVChargerViewModel?
    var chargerLevelViewModel: EVChargerLevelViewModel?
    
    init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
    }
    
    func popViewController() {
        navigationController?.popViewController(animated: true)
    }
    
    func grabBackAction() {
        bottomview = .orderNearest
    }
    
    func grabInfoAction() {
        
    }
    
    func grabGPSInfoAction() {
        
    }
    
    func chooseStation() {
        createChargerDetailViewModel()
    }
    
    func grabFilterAction() {
        createMapFiltersViewModel()
    }
    
    func createMapFiltersViewModel() {
        let viewModel = MapFiltersViewModel()
        viewModel.onAction = { [ weak self] action in
            guard let self else { return }
            switch action {
            case .pop:
                self.presentFilterSheet = false
                filterViewModel = nil
            }
            
        }
        presentFilterSheet = true
        filterViewModel = viewModel
    }
    
    func createChargerDetailViewModel() {
        let viewModel = EVChargerDetailsViewModel(id: "30010000", worker: Resolver.resolve())
        viewModel.onAction = { [ weak self ] action in
            guard let self else { return }
            switch action {
            case .book(let station):
                self.createEVChargingInfoViewModel(station: station)
            case .scan:
                ScanRouter.shared.showQrScanViewController(self.navigationController?.visibleViewController ?? UIViewController(), delegate: self)
            }
        }
        presntDetailSheet = true
        detailViewModel = viewModel
    }
    
    func createEVChargingInfoViewModel(station: EVChargingStation? = nil) {
        navigationController?.dismiss(animated: true)
        
        let viewModel: EVChargingInfoViewModel
        
        if let chargerStation = station {
            viewModel = EVChargingInfoViewModel(chargerStation: chargerStation, worker: Resolver.resolve())
        } else {
            viewModel = EVChargingInfoViewModel(id: "30010000", worker: Resolver.resolve())
        }
        viewModel.onAction = { [ weak self ] action in
            guard let self else { return }
            switch action {
            case .start(let station):
                self.chargerLevelViewModel = EVChargerLevelViewModel(chargerStation: station, worker: Resolver.resolve())
                navigationController?.dismiss(animated: true)
                self.bottomview = .chargeLevel
            case .pop:
                navigationController?.dismiss(animated: true)
            }
        }
        chargingInfoViewModel = viewModel
        presentChargingInfoViewModel()
    }
    
    func presentChargingInfoViewModel() {
        if let viewModel = chargingInfoViewModel {
            let viewController = UIHostingController(rootView: EVChargingInfoView(viewModel: viewModel))
            viewController.modalPresentationStyle = .fullScreen
            navigationController?.present(viewController, animated: true)
        }
    }
    
    func createAddresSearchViewModel() {
        let viewModel = AddressSearchViewModel()
        viewModel.onAction = { [weak self] action in
            guard let self else { return }
            switch action {
            case .didSelectAddres(let adres):
                selectedAdres = adres
                presentAddresSearchView = false
                addressSearchViewModel = nil
            }
        }
        
        addressSearchViewModel = viewModel
    }
    
    func createRequestEvChargerViewModel() {
        let viewModel = RequestEVChargerViewModel()
        viewModel.onAction = { [ weak self ] action in
            guard let self else { return }
            switch action {
            case .pop:
                self.navigationController?.popViewController(animated: true)
            }
        }
        
        requestEVChargerViewModel = viewModel
    }
    
    func pushChooseConnectorView() {
        if let requestEVChargerViewModel {
            let viewController = UIHostingController(rootView: ChooseConectorView(viewModel: requestEVChargerViewModel))
            self.navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    func enterAddresAction() {
        presentAddresSearchView = true
        createAddresSearchViewModel()
    }
    
    func requestEvcharger() {
        createRequestEvChargerViewModel()
        pushChooseConnectorView()
    }
}

extension EVChargerViewModel: MimoScanQrViewControllerDelegate {
    func didFinishScan(with value: String, type: MimoType) {
        
    }
    
    func charginginfoScreen() {
        self.createEVChargingInfoViewModel()
    }
}

enum BottomViewState {
    case cards
    case orderNearest
    case order
    case chargeLevel
}
