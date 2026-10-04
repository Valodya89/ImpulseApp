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

    // MARK: - Fast decision sheet

    /// The collapsed sheet never shows less than this, whatever the home
    /// layout above it leaves over.
    static let minimumSheetPeekHeight: CGFloat = 200

    /// The sheet hosts itself in Home: laid out once at its open height and
    /// slid by offset between its peek and the top (see
    /// `HomeFastDecisionSheetViewController`).
    private var fastDecisionSheet: HomeFastDecisionSheetViewController?
    private var peekHeight: CGFloat = 0

    /// Home's layout left `height` for the collapsed sheet; the sheet follows
    /// when that changes (the active-sessions strip came or went).
    public func fastDecisionSheetAnimate(to height: CGFloat) {
        let peek = max(Self.minimumSheetPeekHeight, height)
        guard peekHeight != peek else { return }
        peekHeight = peek
        fastDecisionSheet?.setPeekHeight(peek, animated: true)
    }

    public func fastDecisionSheetAnimateIn(to view: UIView, in parent: UIViewController, height: CGFloat, viewModel: MimoHomeViewModel?, delegate: HomeFastDecisionSheetViewControllerDelegate?) {
        peekHeight = max(Self.minimumSheetPeekHeight, height)

        if let sheet = fastDecisionSheet, sheet.parent === parent {
            sheet.setPeekHeight(peekHeight, animated: false)
            sheet.animateIn()
            return
        }

        // A sheet left over from an earlier Home belongs to a view that is gone.
        fastDecisionSheet?.remove()

        let sheet = HomeFastDecisionSheetViewController.loadFromNib()
        sheet.viewModel = viewModel
        sheet.delegate = delegate
        sheet.install(in: parent, hostView: view, peekHeight: peekHeight)
        sheet.animateIn()
        fastDecisionSheet = sheet
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
        fastDecisionSheet?.remove()
        fastDecisionSheet = nil
        peekHeight = 0
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
