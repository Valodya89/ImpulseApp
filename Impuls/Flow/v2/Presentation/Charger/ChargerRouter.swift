//
//  ChargerRouter.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 16.11.23.
//

import Foundation

class ChargerRouter {
    
    static var shared = ChargerRouter()
    
    private let storyboard = UIStoryboard(name: "Charger", bundle: nil)
    
    var scanSheetViewController: ScanSheetViewController?
    var chargerDetailsSheetViewController: ChargingStationSheetViewController?
    var rentedChargerSheetViewController: RentedChargerSheetViewController?
    
    private var autoHiddenDetailsSheet = true
    
    private init() {}
    
    func showChargerViewController(_ navigationController: UINavigationController?, scannedQR: String? = nil, selectedQR: String? = nil) {
        if let chargerViewController: ChargerViewController = storyboard.instantiate() {
            chargerViewController.viewModel = Resolver.optional(args: ["preScannedQR": scannedQR, "preSelectedQR": selectedQR])
            navigationController?.pushViewController(chargerViewController, animated: true)
        }
    }
    
    //MARK: - ScanSheet
    func showScanSheet(_ viewController: UIViewController?, data: ScanSheetViewController.Data, delegate: ScanSheetViewControllerDelegate?) {
        guard let viewController, scanSheetViewController == nil else {
            scanSheetViewController?.data = data
            return
        }
        
        scanSheetViewController = ScanSheetViewController.loadFromNib()
        scanSheetViewController?.data = data
        scanSheetViewController?.delegate = delegate
        scanSheetViewController?.isFullyVisible = false
        
        let scanSheetMaxHeight = (UIApplication.shared.keyWindowInConnectedScenes?.safeAreaBottom ?? 0) + 320
        var sheetOptions = SheetOptions()
        sheetOptions.pullBarHeight = 10
        sheetOptions.useInlineMode = true
        
        let scanSheetMinHeight = (UIApplication.shared.keyWindowInConnectedScenes?.safeAreaBottom ?? 0) + 90
        let sheetViewController = SheetViewController(controller: scanSheetViewController!, sizes: [.fixed(scanSheetMinHeight), .fixed(scanSheetMaxHeight)], options: sheetOptions)
        sheetViewController.setupMimoConfigs()
        sheetViewController.allowGestureThroughOverlay = true
        sheetViewController.overlayColor = .clear
        
        sheetViewController.sizeChanged = { [weak self] sheetController, size, contentHeight in
            self?.scanSheetViewController?.isFullyVisible = size == .fixed(scanSheetMaxHeight)
        }
        
        sheetViewController.animateIn(to: viewController.view, in: viewController)
    }
    
    func hideScanSheet() {
        guard let sheetViewController = scanSheetViewController?.parent?.parent as? SheetViewController else { return }
        sheetViewController.attemptDismiss(animated: true)
        scanSheetViewController = nil
    }
    
    func showChargerDetailsSheet(_ viewController: UIViewController?, viewModel: ChargingStationDetailsViewModel?, delegate: ChargingStationSheetViewControllerDelegate?, autoHiddenDetailsSheet: Bool = true) {
        guard let viewController, chargerDetailsSheetViewController == nil else { return }
        self.autoHiddenDetailsSheet = autoHiddenDetailsSheet
        
        chargerDetailsSheetViewController = ChargingStationSheetViewController.loadFromNib()
        chargerDetailsSheetViewController?.viewModel = viewModel
        chargerDetailsSheetViewController?.delegate = delegate
        
        var sheetOptions = SheetOptions()
        sheetOptions.pullBarHeight = 10
        sheetOptions.useInlineMode = true
        
        let contentHeight1 = (UIApplication.shared.keyWindowInConnectedScenes?.screen.bounds.height ?? 0) - 44 - 40
        let contentHeight2 = (UIApplication.shared.keyWindowInConnectedScenes?.safeAreaBottom ?? 0) + 708
        
        let height = min(contentHeight1, contentHeight2)
        
        let sheetViewController = SheetViewController(controller: chargerDetailsSheetViewController!, sizes: [.fixed(height)], options: sheetOptions)
        sheetViewController.setupMimoConfigs()
        sheetViewController.dismissOnOverlayTap = true
        sheetViewController.dismissOnPull = true
        sheetViewController.allowPullingPastMinHeight = true
        sheetViewController.overlayColor = .mimoBlackWith025alpha
        
        sheetViewController.didDismiss = { [weak self] _ in
            self?.chargerDetailsSheetViewController = nil
        }
        
        sheetViewController.animateIn(to: viewController.view, in: viewController)
    }
    
    func hideChargerDetailsSheet(force: Bool = true) {
        if autoHiddenDetailsSheet {
            hide()
        } else if force {
            hide()
        }
        
        func hide() {
            guard let sheetViewController = chargerDetailsSheetViewController?.parent?.parent as? SheetViewController else { return }
            sheetViewController.attemptDismiss(animated: true)
            chargerDetailsSheetViewController = nil
        }
    }
    
    func showRentedChargerSheet(_ viewController: UIViewController?, rentedChargers: [RentedCharger]?, delegate: RentedChargerSheetViewControllerDelegate?) {
        guard let viewController, rentedChargerSheetViewController == nil else { rentedChargerSheetViewController?.viewModel?.rentedChargers.send(rentedChargers); return }
        
        rentedChargerSheetViewController = RentedChargerSheetViewController.loadFromNib()
        rentedChargerSheetViewController?.viewModel = RentedChargerViewModel(rentedChargers: rentedChargers)
        rentedChargerSheetViewController?.delegate = delegate
        
        var sheetOptions = SheetOptions()
        sheetOptions.pullBarHeight = 10
        sheetOptions.useInlineMode = true
        
        let height = (UIApplication.shared.keyWindowInConnectedScenes?.safeAreaBottom ?? 0) + 220
        let sheetViewController = SheetViewController(controller: rentedChargerSheetViewController!, sizes: [.fixed(height)], options: sheetOptions)
        
        sheetViewController.setupMimoConfigs()
        sheetViewController.allowGestureThroughOverlay = true
        sheetViewController.overlayColor = .clear
        sheetViewController.gripSize = .zero
        sheetViewController.gripColor = .clear
        
        sheetViewController.animateIn(to: viewController.view, in: viewController)
    }
    
    func showChargerSuccessViewController(_ viewController: UIViewController, rentedCharger: RentedCharger?) {
        if let successViewController: ChargerSuccessViewController = storyboard.instantiate() {
            successViewController.rentedCharger = rentedCharger
            
            viewController.present(successViewController, animated: true)
        }
    }
    
    func showSpecialDiscountsScreen(_ rootViewController: UIViewController) {
        let viewController = ChargerSpecialDiscountsViewController()
        viewController.title = "MOBILE_charger_special_discounts_title".localized()
        
        let button = UIButton()
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .black
        button.addAction(UIAction(handler: { _ in
            viewController.dismiss(animated: true)
        }), for: .touchUpInside)
        
        viewController.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: button)
        
        let navigationController = UINavigationController(rootViewController: viewController)
        rootViewController.present(navigationController, animated: true)
    }
    
    func hideRentedChargerSheet() {
        guard let sheetViewController = rentedChargerSheetViewController?.parent?.parent as? SheetViewController else { return }
        sheetViewController.attemptDismiss(animated: true)
        rentedChargerSheetViewController = nil
    }
    
    func reset() {
        scanSheetViewController = nil
        chargerDetailsSheetViewController = nil
        rentedChargerSheetViewController = nil
    }
}
