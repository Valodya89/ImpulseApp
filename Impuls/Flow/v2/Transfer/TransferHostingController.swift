//
//  TransferHostingController.swift
//  Impuls
//
//  UIKit bridge for the v2 transfer flow. Replaces the storyboard pair
//  TransferViewController + TransferToFriendViewController at every entry
//  point: the wallet (SwiftUI and legacy) opens it on the search step, the
//  debt flows open it straight on the amount step with the debtor prefilled.
//
//  Posting "TransferToFriendViewController" on dismiss is what the old
//  screen did in `viewDidDisappear`; `MimoBaseViewController` observers
//  (the scooter screen) reload the balance on it.
//

import UIKit
import SwiftUI

final class TransferHostingController: UIHostingController<TransferMoneyView> {

    /// Opens on the search step: find a rider by phone number or contact.
    convenience init(wallet: WalletModel?) {
        self.init(wallet: wallet, recipient: nil, debt: nil)
    }

    /// Opens straight on the amount step for a known rider (debt payment).
    convenience init(wallet: WalletModel?, phoneNumber: String, transferUser: ContactsListModel?, debt: Double?) {
        self.init(wallet: wallet,
                  recipient: TransferRecipient(phoneNumber: phoneNumber, contact: transferUser),
                  debt: debt)
    }

    private init(wallet: WalletModel?, recipient: TransferRecipient?, debt: Double?) {
        let viewModel = TransferMoneyViewModel(wallet: wallet, recipient: recipient, debt: debt)
        // Filled in below, once `self` exists.
        var closeAction: () -> Void = {}
        super.init(rootView: TransferMoneyView(viewModel: viewModel, onClose: { closeAction() }))

        closeAction = { [weak self] in self?.dismiss(animated: true) }

        modalPresentationStyle = .pageSheet
        view.backgroundColor = UIColor(named: "AppSecondaryBackground")
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        NotificationCenter.default.post(name: NSNotification.Name("TransferToFriendViewController"), object: nil)
    }
}
