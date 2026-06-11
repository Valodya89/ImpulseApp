//
//  BikeRouter.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 30.06.23.
//

import Foundation

class BikeRouter {
    
    static let shared = BikeRouter()
    
    private var storyboard: UIStoryboard = UIStoryboard(name: "Bike", bundle: nil)
    
    var scanSheetViewController: ScanSheetViewController?
    var bikeDetailsSheetViewController: BikeDetailsSheetViewController?
    var bikeTripSheetViewController: BikeTripSheetViewController?
    var endRideAlertView: BikeEndRideAlertView?
    
    func showBikeViewController(_ navigationController: UINavigationController?, scannedQR: String? = nil, selectedQR: String? = nil) {
        if let bikeViewController: BikeViewController = storyboard.instantiate() {
            let viewModel: BikeViewModel? = Resolver.optional(args: ["preScannedQR": scannedQR, "preSelectedQR": selectedQR])
            bikeViewController.viewModel = viewModel
            navigationController?.pushViewController(bikeViewController, animated: true)
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
    
    //MARK: - BikeDetails
    func showBikeDetailsSheet(_ viewController: UIViewController?, data: BikeDetailsData, delegate: BikeDetailsSheetViewControllerDelegate?) {
        guard let viewController, bikeDetailsSheetViewController == nil else {
            bikeDetailsSheetViewController?.viewModel?.bikeData = data.bikeData
            bikeDetailsSheetViewController?.viewModel?.financialState = data.financialState
            bikeDetailsSheetViewController?.viewModel?.walletInfo = data.walletInfo
            bikeDetailsSheetViewController?.viewModel?.bikeState = data.bikeState
            bikeDetailsSheetViewController?.delegate = delegate
            
            return
        }
        
        bikeDetailsSheetViewController = BikeDetailsSheetViewController.loadFromNib()
        bikeDetailsSheetViewController?.viewModel = Resolver.optional(args: data)
        bikeDetailsSheetViewController?.delegate = delegate
        
        var sheetOptions = SheetOptions()
        sheetOptions.pullBarHeight = 10
        sheetOptions.useInlineMode = true
        
        let height = (UIApplication.shared.keyWindowInConnectedScenes?.safeAreaBottom ?? 0) + 470
        let sheetViewController = SheetViewController(controller: bikeDetailsSheetViewController!, sizes: [.fixed(height)], options: sheetOptions)
        sheetViewController.setupMimoConfigs()
        sheetViewController.dismissOnOverlayTap = true
        sheetViewController.dismissOnPull = true
        sheetViewController.allowPullingPastMinHeight = true
        sheetViewController.overlayColor = .mimoBlackWith025alpha
        
        sheetViewController.didDismiss = { [weak self] _ in
            self?.bikeDetailsSheetViewController = nil
        }
        
        sheetViewController.animateIn(to: viewController.view, in: viewController)
    }
    
    func hideBikeDetailsSheet() {
        guard let sheetViewController = bikeDetailsSheetViewController?.parent?.parent as? SheetViewController else { return }
        sheetViewController.attemptDismiss(animated: true)
        bikeDetailsSheetViewController = nil
    }
    
    //MARK: - Trip
    func showBikeTripSheet(_ viewController: UIViewController?, data: TripActionModel) {
        guard let viewController, bikeTripSheetViewController == nil else {
            bikeTripSheetViewController?.viewModel?.tripData = data
            return
        }
        
        bikeTripSheetViewController = BikeTripSheetViewController.loadFromNib()
        bikeTripSheetViewController?.viewModel = Resolver.optional(args: data)
        
        var sheetOptions = SheetOptions()
        sheetOptions.pullBarHeight = 10
        sheetOptions.useInlineMode = true
        
        let height = (UIApplication.shared.keyWindowInConnectedScenes?.safeAreaBottom ?? 0) + 250
        let sheetViewController = SheetViewController(controller: bikeTripSheetViewController!, sizes: [.fixed(height)], options: sheetOptions)
        
        sheetViewController.setupMimoConfigs()
        sheetViewController.allowGestureThroughOverlay = true
        sheetViewController.overlayColor = .clear
        sheetViewController.gripSize = .zero
        sheetViewController.gripColor = .clear
        
        sheetViewController.animateIn(to: viewController.view, in: viewController)
    }
    
    func hideBikeTripSheet() {
        guard let sheetViewController = bikeTripSheetViewController?.parent?.parent as? SheetViewController else { return }
        sheetViewController.attemptDismiss(animated: true)
        bikeTripSheetViewController = nil
    }
    
    //MARK: - Tarifs
    func showTariffsViewController(_ viewController: UIViewController?) {
        let planController = MIPlansNavigationController.initFromStoryboard(name: "MIPlan")
        
        viewController?.present(planController, animated: true)
    }
    
    //MARK: - Onboarding
    func showOnboardingViewController(_ viewController: UIViewController?) {
        let onboardingView = OnboardingViewController.initFromStoryboard(name: "SignIn")
        onboardingView.modalPresentationStyle = .overFullScreen
        onboardingView.isPresentedHome = true
        
        viewController?.present(onboardingView, animated: true)
    }
    
    //MARK: - End Ride
    func showEndRideAlert(_ viewController: UIViewController?, travelTime: String? = nil, price: String) {
        guard endRideAlertView == nil else {
            endRideAlertView?.price = price
            return
        }
        endRideAlertView = BikeEndRideAlertView()
        endRideAlertView?.modalPresentationStyle = .overCurrentContext
        endRideAlertView?.modalTransitionStyle = .crossDissolve
        endRideAlertView?.price = price
        endRideAlertView?.completion = { [weak self] in
            self?.endRideAlertView = nil
        }
        
        if let travelTime {
            endRideAlertView?.travelTime = travelTime
        }
        
        viewController?.present(endRideAlertView!, animated: true)
    }
    
    func reset() {
        scanSheetViewController = nil
        bikeDetailsSheetViewController = nil
        bikeTripSheetViewController = nil
    }
}
