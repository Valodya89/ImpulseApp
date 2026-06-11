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
