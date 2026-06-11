//
//  EVChargerRouter.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 05.02.25.
//

import SwiftUI

class EVChargerRouter {
    
    static var shared = EVChargerRouter()
    
    private init() {}
    
    var actionsViewController: EVChargerHostingController<EVVerticalDoubleButtonView>?
    
    private var storyboard: UIStoryboard = UIStoryboard(name: "EVCharger", bundle: nil)
    
    func showEvChargerViewController(
        _ navigationController: UINavigationController?,
        selectedId: String? = nil,
        scanedStation: (EVChargingStation? , EVChargingConnector? ),
        isFromFastDecision: Bool
    ) {
        let coordinator = EVChargerCoordinator(navigationController: navigationController, provider: EVChargerProvider())
        coordinator.start(selectedId: selectedId, scanedStation: scanedStation, isFromFastDecision: isFromFastDecision)
    }
    
    func showSheet(_ viewController: EVChargerMapViewController) {
        guard actionsViewController == nil else {
//            scanSheetViewController?.data = data
            return
        }
        
        let vc = EVChargerHostingController(
            rootView: EVVerticalDoubleButtonView(orderAction: {
//                withAnimation {
//                    viewModel.bottomview = .order
//                }
            }, nearestStationAction: { [weak self, weak viewController] in
                
//                withAnimation {
//                    viewModel.bottomview = .cards
//                }
                viewController?.viewModel?.selectedStation = viewController?.viewModel?.stations?.first
//                viewController?.viewModel?.viewState = .scooterList(0)
            })
        )
        actionsViewController = vc
        
        var sheetOptions = SheetOptions()
        sheetOptions.pullBarHeight = 10
        sheetOptions.useInlineMode = true
        
        let sheetViewController = SheetViewController(controller: vc, sizes: [.fixed(120)], options: sheetOptions)
        sheetViewController.setupMimoConfigs()
        sheetViewController.allowGestureThroughOverlay = true
        sheetViewController.overlayColor = .clear
        
        sheetViewController.didDismiss = { [weak self] _ in
            self?.actionsViewController = nil
        }
        
        sheetViewController.animateIn(to: viewController.view, in: viewController)
    }
    
    func hideScanSheet() {
        guard let sheetViewController = actionsViewController?.parent?.parent as? SheetViewController else { return }
        sheetViewController.attemptDismiss(animated: true)
        actionsViewController = nil
    }
    
    func reset() {
        actionsViewController = nil
    }
}
