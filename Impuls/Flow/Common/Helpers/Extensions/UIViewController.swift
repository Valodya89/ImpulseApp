//
//  UIViewController.swift
//  Impuls
//
//  Created by Vardan on 12.05.21.
//
//  Alert helpers. Every one of them raises the Mimo alert card
//  (`MimoAlertController`) instead of a system `UIAlertController` or the old
//  SCL-derived `MiAlertView`, with the same signatures the call sites use.
//

import UIKit
import SwiftMessages

extension UIViewController {

    func showAlertMessage(_ title: String, meassage: String = "") {
        MimoAlertController.present(.info(title, message: meassage), on: self)
    }

    func showAlertMessage(_ title: String, meassage: String = "", actionText: String, action: @escaping (() -> ())) {
        MimoAlertController.present(
            .info(title, message: meassage, actions: [MimoAlertAction(title: actionText, tone: .primary, handler: action)]),
            on: self
        )
    }

    /// Several choices. A title that reads as "cancel" / "no" gets the hairline
    /// pill and the rest the yellow one; otherwise the last title is treated as
    /// the affirmative one and the others stay quiet.
    func showAlertMessage(_ title: String, meassage: String = "", actionText: [String], action: @escaping ((String) -> ())) {
        let quietTitles = Set([
            "MOBILE_global_cancel".localized(),
            "MOBILE__confirmation_no".localized(),
            "Cancel", "No", "Ok", "OK"
        ].map { $0.lowercased() })
        let quiet = actionText.map { quietTitles.contains($0.lowercased()) }
        let hasQuiet = actionText.count > 1 && quiet.contains(true) && quiet.contains(false)

        let actions = actionText.enumerated().map { index, actionTitle -> MimoAlertAction in
            let tone: MimoAlertAction.Tone
            if hasQuiet {
                tone = quiet[index] ? .secondary : .primary
            } else {
                tone = index == actionText.count - 1 ? .primary : .secondary
            }
            return MimoAlertAction(title: actionTitle, tone: tone) { action(actionTitle) }
        }
        MimoAlertController.present(.info(title, message: meassage, actions: actions), on: self)
    }

    func showAlertMessageWithDismiss(_ title: String, meassage: String = "", actionText: [String], action: @escaping ((String) -> ())) {
        showAlertMessage(title, meassage: meassage, actionText: actionText, action: action)
    }

    func showErrorAlertMessage(_ message: String = "MOBILE_something_wrong".localized(fallback: "Something went wrong. Please try again.")) {
        MimoAlertController.present(.error(message), on: self)
    }

    /// Set view controller as root
    func setRootViewController(_ vc: UIViewController?) {
        UIApplication.shared.windows.first?.rootViewController = vc
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }

    func goToNextVC(_ vc: UIViewController) {
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
}

extension UIAlertController {

    /// Kept under its old name for the managers that call it without a view
    /// controller. `.cancel` becomes the quiet pill, `.destructive` the red one.
    /// The closure still receives an alert controller for the callers that
    /// dismiss it themselves; it is never on screen, so that is a no-op.
    static func showAction(title: String, message: String, actions: (String,UIAlertAction.Style, (UIAlertController)->())...) {
        let placeholder = UIAlertController(title: title, message: message, preferredStyle: .alert)

        let mapped = actions.map { action -> MimoAlertAction in
            let tone: MimoAlertAction.Tone
            switch action.1 {
            case .cancel: tone = .secondary
            case .destructive: tone = .destructive
            case .default: tone = .primary
            @unknown default: tone = .primary
            }
            return MimoAlertAction(title: action.0, tone: tone) { action.2(placeholder) }
        }

        MimoAlertController.present(MimoAlertContent(kind: .info, title: title, message: message, actions: mapped))
    }

    static func showError(message: String) {
        MimoAlertController.present(.error(message))
    }

    static func showLocationDeniedAlert() {
        MimoAlertController.present(
            .important("MOBILE_global_location".localized(fallback: "Location"),
                       message: "MOBILE__global_location_access".localized(fallback: "In order to find the closest powerbanks for you and save your time, we need access to your location."),
                       actions: [
                        MimoAlertAction(title: "MOBILE_profile_settings".localized(fallback: "Settings"), tone: .primary) {
                            AppDelegate.redirectSettings()
                        },
                        .cancel()
                       ])
        )
    }
}

extension AppDelegate {
    
    static func redirectSettings() {
    
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
}

extension UIViewController {

    /// Green in-place banner (same style as the wallet screen).
    func showSuccessMessage(title: String, body: String, dismissed: (() -> Void)? = nil) {
        showBanner(MessageHostingView(message: SuccessMessage(title: title, body: body)), dismissed: dismissed)
    }

    /// Red in-place banner (same style as the wallet screen).
    func showErrorMessage(title: String, body: String, dismissed: (() -> Void)? = nil) {
        showBanner(MessageHostingView(message: ErrorMessage(title: title, body: body)), dismissed: dismissed)
    }

    private func showBanner(_ view: UIView, dismissed: (() -> Void)?) {
        var config = SwiftMessages.defaultConfig
        // Own window: the banner stays visible even when the presenting screen is dismissed.
        config.presentationContext = .window(windowLevel: .normal)
        config.duration = .seconds(seconds: 3)
        if let dismissed {
            config.eventListeners.append { event in
                if case .didHide = event { dismissed() }
            }
        }
        SwiftMessages.show(config: config, view: view)
    }
}

extension UIViewController {
    
    /// The backend refused to start a rent or ride. One shared card for every
    /// product (`ChargerErrorViewController`); a balance below the minimum also
    /// offers the two ways to top up and a Continue that opens the wallet in
    /// that product's context.
    /// - Parameters:
    ///   - resumeAfterRequirements: whether `retry` runs by itself once the
    ///     rules of a refusal are met (`ActionEligibilityFlow`). False for a
    ///     place-bound action such as a power bank scan: the checklist closes
    ///     by itself but the action is not re-sent; `requirementsMet` runs
    ///     instead (re-arm the scanner). A debt always resumes `retry`.
    ///   - retry: runs the refused action again once what held it back
    ///     is settled (a debt paid, rules met).
    ///   - walletRefusal: shown instead of the checklist when the refusal's
    ///     only violations are the wallet's (balance under the rule's minimum,
    ///     no card) - the product's own top-up popup with the amount the rule
    ///     reported (`ActionEligibilityFlow.run(walletRefusal:)`). Nil keeps
    ///     the presenter the pre-check of the same action remembered, if any.
    func showErrorPopUp(message: String,
                        service: MimoType,
                        resumeAfterRequirements: Bool = true,
                        requirementsMet: (() -> Void)? = nil,
                        retry: (() -> Void)? = nil,
                        walletRefusal: ((EligibilityViolation) -> Void)? = nil) {
        // A start held back by a debt (SHARING_user_has_debt / _device_ / _card_,
        // powerbank docs/error-codes.md 'Rent rule violations') opens the debt
        // screen: pay by card or wallet, or settle another account's debt by a
        // transfer; the action is re-sent once the debt is cleared.
        if DebtHostingController.isDebtRefusal(message) {
            // Drop the recorded refusal so the requirements sheet does not pick
            // it up for an unrelated error later.
            ActionRejectionStore.shared.take(matching: message)
            BaseRouter.shared.showDebtScreen(self, financialState: nil, wallet: nil, onPaid: retry)
            return
        }

        // An action refused for unmet rules is walked through step by step
        // instead of being shown as an error.
        if ActionEligibilityFlow.handleRejection(message: message, from: self,
                                                 resumeAfterRequirements: resumeAfterRequirements,
                                                 requirementsMet: requirementsMet,
                                                 retry: retry,
                                                 walletRefusal: walletRefusal) { return }

        // A refusal without rule violations: the plain card. The wallet codes
        // also offer the ways to top up - without a number, since no rule
        // reported one (the minimum is the backend's, never the app's).
        let isReplenishable: Bool = (message == "SHARING_no_minimal_requirements") || (message == "MOBILE_map_minimum_requirments") || (message == "WALLET_min_balance_required") || (message == "WALLET_min_balance_or_card_required") || (message == "WALLET_card_required")

        showServiceBlockedPopup(message: UIViewController.userFacingErrorMessage(from: message),
                                service: service,
                                isReplenishable: isReplenishable,
                                minimumBalance: nil,
                                topUpAmount: nil)
    }

    /// The wallet alone refused to start a rent: the product's "Let's start"
    /// popup with the served refusal text, the attach-card and top-up options
    /// and Continue, which opens the wallet in the product's context with the
    /// rule's amount prefilled. Amount and currency are the violation's
    /// `details.amount` / `details.currency`; when the rule sent none the
    /// popup shows no number. The action is never started from here: the
    /// rider tops up or attaches a card and scans again.
    func showWalletRefusalPopup(_ violation: EligibilityViolation, service: MimoType) {
        showServiceBlockedPopup(message: UIViewController.userFacingErrorMessage(from: violation.code),
                                service: service,
                                isReplenishable: true,
                                minimumBalance: ChargerErrorViewController.minimumBalance(from: violation),
                                topUpAmount: ChargerErrorViewController.minimumAmount(from: violation))
    }

    private func showServiceBlockedPopup(message: String,
                                         service: MimoType,
                                         isReplenishable: Bool,
                                         minimumBalance: String?,
                                         topUpAmount: Double?) {
        let vc = ChargerErrorViewController(message: message,
                                            isReplenishable: isReplenishable,
                                            service: service,
                                            minimumBalance: minimumBalance,
                                            onReplenish: { [weak self] in
            self?.openWallet(productType: service.walletProductType, initialAmount: topUpAmount)
        })

        self.present(vc, animated: true)
    }

    /// Converts a raw error string into a user-facing message.
    /// Localization keys are localized as usual, but raw system/network error
    /// descriptions (e.g. "The operation couldn't be completed.
    /// (Impuls.NetworkSessionErrors error 0.)") are replaced with a friendly
    /// localized message so technical text is never shown to the user.
    static func userFacingErrorMessage(from message: String) -> String {
        // The one resolver: in-memory texts, then the dictionaries saved on disk
        // (this language, then English), then the generic error for an unknown
        // machine code; human text is shown unchanged.
        let localized = message.localizedMessage()

        let technicalMarkers = [
            "NetworkSessionErrors",
            "operation couldn't be completed",
            "operation couldn’t be completed",
            "Impuls.",
            "Error Domain"
        ]

        let isTechnical = technicalMarkers.contains { marker in
            localized.range(of: marker, options: .caseInsensitive) != nil
        }

        if isTechnical || localized.isEmpty {
            return "MOBILE_lostConnection_message".localized()
        }

        return localized
    }
}

private extension MimoType {
    /// The wallet opens in the product's context so the top-up lands where the
    /// rider was refused.
    var walletProductType: MimoProductType {
        switch self {
        case .scooter: return .scooter
        case .bike: return .bike
        case .charger: return .charger
        case .evCharger: return .evCharger
        }
    }
}
