//
//  WalletHostingController.swift
//  Impuls
//
//  UIKit bridge for the SwiftUI wallet. Every legacy screen that used to
//  instantiate `WalletViewController` from Wallet.storyboard (the debt and
//  minimum-balance prompts on Home, Scan, Account, Trips, Scooter plan and
//  Plans) presents this instead.
//
//  The storyboard wallet published `balanceUpdated` and posted `updateUserUI`
//  as it went away; the legacy callers still refresh on those, so this does
//  the same when it is dismissed.
//

import UIKit
import SwiftUI

final class WalletHostingController: UIHostingController<WalletView> {

    /// - Parameters:
    ///   - productType: what the rider was about to pay for, if known.
    ///   - initialAmount: an amount to open with (a trip's debt); the wallet
    ///     also prefills a negative balance on its own.
    init(productType: MimoProductType? = nil, initialAmount: Double? = nil) {
        let viewModel = MimoWalletViewModel(worker: Resolver.resolve(),
                                            productType: productType,
                                            initialAmount: initialAmount)
        super.init(rootView: WalletView(viewModel: viewModel))

        modalPresentationStyle = .pageSheet
        view.backgroundColor = .appSecondaryBackground
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        guard isBeingDismissed || presentingViewController == nil else { return }

        Resolver.resolve(MessageServiceProtocol.self).publish(.balanceUpdated)
        NotificationCenter.default.post(name: Constant.Notifications.updateUserUI, object: nil)
    }
}
