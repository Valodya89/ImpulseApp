//
//  HomeRouter.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 04.05.23.
//

import Foundation
import SwiftUI

class HomeRouter {
    
    static let shared = HomeRouter()
    
    private var storyboard: UIStoryboard = UIStoryboard(name: "MimoHome", bundle: nil)
    
    public var fastDecisionViewController: HomeFastDecisionSheetViewController? {
        return HomeFastDecisionSheetViewController.loadFromNib()
    }
    
    private var fastDecisionSheetController: SheetViewController?
    private var height: CGFloat = 0
    
    public func fastDecisionSheetAnimate(to height: CGFloat) {
        if self.height != height {
            self.height = height
            fastDecisionSheetController?.setSizes([.fixed(height), .fullscreen], animated: true)
        }
    }

    public func fastDecisionSheetAnimateIn(to view: UIView, in parent: UIViewController, height: CGFloat, viewModel: MimoHomeViewModel?, delegate: HomeFastDecisionSheetViewControllerDelegate?) {
        guard fastDecisionSheetController == nil else {
            fastDecisionSheetController?.animateIn(size: .fixed(height))
            return
        }
        
        var sheetOptions = SheetOptions()
        sheetOptions.pullBarHeight = 10
        sheetOptions.useInlineMode = true
        sheetOptions.useFullScreenMode = true
        
        let viewController = HomeFastDecisionSheetViewController.loadFromNib()
        viewController.viewModel = viewModel
        viewController.delegate = delegate
        fastDecisionSheetController = SheetViewController(controller: viewController,
                                                              sizes: [.fixed(height), .fullscreen],
                                                              options: sheetOptions)
        fastDecisionSheetController?.setupMimoConfigs()
        fastDecisionSheetController?.allowGestureThroughOverlay = true
        fastDecisionSheetController?.overlayColor = .clear
        fastDecisionSheetController?.allowPullingPastMinHeight = false
        fastDecisionSheetController?.allowPullingPastMaxHeight = true
        fastDecisionSheetController?.minimumSpaceAbovePullBar = (UIApplication.shared.keyWindowInConnectedScenes?.safeAreaTop ?? 0) + 50
        fastDecisionSheetController?.cornerRadius = 20
        fastDecisionSheetController?.shouldRecognizePanGestureWithUIControls = false
        
        fastDecisionSheetController?.animateIn(to: view, in: parent)
    }
    
    public func homeViewController() -> MimoHomeTabBarController? {
        return storyboard.instantiate()
    }

    // MARK: - Station App Link
    
    /// The station code from a scanned sticker link that is waiting for Home.
    /// The app may be cold-starting through the splash when the link arrives,
    /// so the code is parked here and taken by Home when it appears.
    private(set) var pendingStationCode: String?
    
    /// The in-app scanner's rules for a power-bank station code: the numeric
    /// 200... stickers and the lettered MOSH08231025... ones. Impulse rents
    /// power banks only, so any other code is not a station link here.
    static func isStationCode(_ code: String) -> Bool {
        let allowed = CharacterSet.alphanumerics
        guard !code.isEmpty, code.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }
        return code.hasPrefix("200") || code.hasPrefix("MOSH08231025")
    }
    
    /// Parks a station code and tells a running Home about it. Returns false
    /// (and holds nothing) for a code the app does not handle.
    @discardableResult
    func holdStationLink(code: String) -> Bool {
        guard HomeRouter.isStationCode(code) else { return false }
        pendingStationCode = code
        NotificationCenter.default.post(name: Constant.Notifications.stationScanLink, object: code)
        return true
    }
    
    /// Hands over the parked station code once; a second call returns nil.
    func takePendingStationCode() -> String? {
        defer { pendingStationCode = nil }
        return pendingStationCode
    }
    
    func reset() {
        fastDecisionSheetController = nil
    }
    
    func showNotifyMeScreen(_ navigationController: UINavigationController?) {
        let notifyMeViewModel = NotifyMeViewModel(worker: Resolver.resolve())
        let notifyMeView = NotifyMeView(viewModel: notifyMeViewModel)
        let hostingController = UIHostingController(rootView: notifyMeView)
        hostingController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(hostingController, animated: true)
    }
    
    func showProductsSelectionScreen(_ navigationController: UINavigationController?) {
        let productSelectionViewModel = ProductSelectionViewModel(
            worker: Resolver.resolve(),
            locationManager: Resolver.resolve(),
            messagingService: Resolver.resolve()
        )
        let productSelectionView = ProductSelectionView(viewModel: productSelectionViewModel)
        let hostingController = UIHostingController(rootView: productSelectionView)
        hostingController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(hostingController, animated: true)
    }
}
