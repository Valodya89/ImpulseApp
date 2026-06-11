//
//  ScooterRouter.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 30.06.23.
//

import Foundation

class ScooterRouter {
    
    static let shared = ScooterRouter()
    
    private var storyboard: UIStoryboard = UIStoryboard(name: "Scooter", bundle: nil)
    
    var scanSheetViewController: ScanSheetViewController?
    var scooterDetailsViewController: ScooterDetailsSheetViewController?
    var scooterTripSheetViewController: ScooterTripSheetViewController?
    
    private init() {}
    
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
        
        let maxHeight: SheetSize = data.mimoType == .scooter ? .fixed(360) : .fixed(430)
        var sheetOptions = SheetOptions()
        sheetOptions.pullBarHeight = 10
        sheetOptions.useInlineMode = true
        
        let sheetViewController = SheetViewController(controller: scanSheetViewController!, sizes: [.fixed(120), maxHeight], options: sheetOptions)
        sheetViewController.setupMimoConfigs()
        sheetViewController.allowGestureThroughOverlay = true
        sheetViewController.overlayColor = .clear
        
        sheetViewController.sizeChanged = { [weak self] sheetController, size, contentHeight in
            self?.scanSheetViewController?.isFullyVisible = size == maxHeight
        }
        
        sheetViewController.animateIn(to: viewController.view, in: viewController)
    }
    
    func hideScanSheet() {
        guard let sheetViewController = scanSheetViewController?.parent?.parent as? SheetViewController else { return }
        sheetViewController.attemptDismiss(animated: true)
        scanSheetViewController = nil
    }
    
    //MARK: - ScooterDetails
    func showScooterDetailsSheet(_ viewController: UIViewController?, viewModel: ScooterDetailsViewModel?, delegate: ScooterDetailsSheetViewControllerDelegate?, dismissible: Bool = true) {
        guard let viewController, scooterDetailsViewController == nil else {
            scooterDetailsViewController?.viewModel?.scooterData = viewModel?.scooterData
            scooterDetailsViewController?.viewModel?.scooterState = viewModel?.scooterState
            scooterDetailsViewController?.viewModel?.walletInfo = viewModel?.walletInfo
            scooterDetailsViewController?.viewModel?.financialState = viewModel?.financialState
            scooterDetailsViewController?.viewModel?.user = viewModel?.user
            scooterDetailsViewController?.setupData()
            
            return
        }
        
        scooterDetailsViewController = ScooterDetailsSheetViewController.loadFromNib()
        scooterDetailsViewController?.viewModel = viewModel
        scooterDetailsViewController?.delegate = delegate
        
        var sheetOptions = SheetOptions()
        sheetOptions.pullBarHeight = 10
        sheetOptions.useInlineMode = true
        
        let height = (UIApplication.shared.keyWindowInConnectedScenes?.safeAreaBottom ?? 0) + 450
        let sheetViewController = SheetViewController(controller: scooterDetailsViewController!, sizes: [.fixed(height)], options: sheetOptions)
        sheetViewController.setupMimoConfigs()
        sheetViewController.dismissOnOverlayTap = dismissible
        sheetViewController.dismissOnPull = dismissible
        sheetViewController.allowPullingPastMinHeight = dismissible
        sheetViewController.overlayColor = .mimoBlackWith025alpha
        
        if !dismissible {
            sheetViewController.gripSize = .zero
            sheetViewController.gripColor = .clear
        }
        
        sheetViewController.didDismiss = { [weak self] _ in
            self?.scooterDetailsViewController = nil
        }
        
        sheetViewController.animateIn(to: viewController.view, in: viewController)
    }
    
    func hideScooterDetailsSheet() {
        guard let sheetViewController = scooterDetailsViewController?.parent?.parent as? SheetViewController else { return }
        sheetViewController.attemptDismiss(animated: true)
        scooterDetailsViewController = nil
    }
    
    //MARK: - ScooterTrip
    func showScooterTripSheet(_ viewController: UIViewController?, viewModel: ScooterTripViewModel?, delegate: ScooterTripSheetViewControllerDelegate?) {
        guard let viewController, scooterTripSheetViewController == nil else {
            scooterTripSheetViewController?.viewModel?.trips = viewModel?.trips ?? []
            return
        }
        
        scooterTripSheetViewController = ScooterTripSheetViewController.loadFromNib()
        scooterTripSheetViewController?.viewModel = viewModel
        scooterTripSheetViewController?.delegate = delegate
        
        var sheetOptions = SheetOptions()
        sheetOptions.pullBarHeight = 10
        sheetOptions.useInlineMode = true
        
        let height = (UIApplication.shared.keyWindowInConnectedScenes?.safeAreaBottom ?? 0) + 320
        let sheetViewController = SheetViewController(controller: scooterTripSheetViewController!, sizes: [.fixed(height)], options: sheetOptions)
        
        sheetViewController.setupMimoConfigs()
        sheetViewController.allowGestureThroughOverlay = true
        sheetViewController.overlayColor = .clear
        sheetViewController.gripSize = .zero
        sheetViewController.gripColor = .clear
        
        sheetViewController.animateIn(to: viewController.view, in: viewController)
    }
    
    func hideScooterTripSheet() {
        guard let sheetViewController = scooterTripSheetViewController?.parent?.parent as? SheetViewController else { return }
        sheetViewController.attemptDismiss(animated: true)
        scooterTripSheetViewController = nil
    }
    
    //MARK: - ScooterViewController
    func showScooterViewController(
        _ navigationController: UINavigationController?,
        scannedQR: String? = nil,
        selectedQR: String? = nil,
        leasedScooters: [String]? = nil
    ) {
        if let scooterViewController: ScooterViewController = storyboard.instantiate() {
            let viewModel: MimoScooterViewModel? = Resolver.optional(args: ["preScannedQR": scannedQR, "preSelectedQR": selectedQR, "leasedScooters": leasedScooters ?? []])
            scooterViewController.viewModel = viewModel
            navigationController?.pushViewController(scooterViewController, animated: true)
        }
    }
    
    //MARK: - Parking
    func showParkingInfo(_ viewController: UIViewController?) {
        if let parkingViewController: ParkingDetailsViewController = storyboard.instantiate() {
            parkingViewController.modalPresentationStyle = .overCurrentContext
            parkingViewController.modalTransitionStyle = .crossDissolve
            
            viewController?.present(parkingViewController, animated: true)
        }
    }
    
    //MARK: - Zone
    func showZoneInfo(_ viewController: UIViewController?, zoneType: ZoneType?) {
        guard let viewController else { return }
        
        let zoneInfoViewController: ZoneInfoViewController = ZoneInfoViewController.loadFromNib()
        zoneInfoViewController.viewModel = Resolver.optional(args: zoneType)
        
        var sheetOptions = SheetOptions()
        sheetOptions.pullBarHeight = 10
        sheetOptions.useInlineMode = true
        
        let contentHeight: CGFloat = zoneType == nil ? 400 : 180
        let height = (UIApplication.shared.keyWindowInConnectedScenes?.safeAreaBottom ?? 0) + contentHeight
        let sheetViewController = SheetViewController(controller: zoneInfoViewController, sizes: [.fixed(height)], options: sheetOptions)
        sheetViewController.setupMimoConfigs()
        sheetViewController.dismissOnOverlayTap = true
        sheetViewController.dismissOnPull = true
        sheetViewController.allowPullingPastMinHeight = true
        
        sheetViewController.animateIn(to: viewController.view, in: viewController)
    }
    
    public func showSpeedTariffChangeViewController(_ viewController: UIViewController?, speedTariff: SpeedTariff?, mode: ScooterPlanMode?, tripId: String?, delegate: SpeedTariffChangeViewControllerDelegate?) {
        let tariffChangeViewController = SpeedTariffChangeViewController.loadFromNib()
        tariffChangeViewController.speedTariff = speedTariff
        tariffChangeViewController.scooterPlanMode = mode
        tariffChangeViewController.tripId = tripId
        tariffChangeViewController.delegate = delegate
        
        tariffChangeViewController.modalPresentationStyle = .overCurrentContext
        tariffChangeViewController.modalTransitionStyle = .crossDissolve
        
        viewController?.present(tariffChangeViewController, animated: true)
    }
    
    func reset() {
        scanSheetViewController = nil
        scooterDetailsViewController = nil
        scooterTripSheetViewController = nil
    }
}
