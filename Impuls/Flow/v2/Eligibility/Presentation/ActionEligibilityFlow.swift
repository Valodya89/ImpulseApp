//
//  ActionEligibilityFlow.swift
//  Impuls
//
//  The one handler for rules that hold an action back, before or after the
//  action is sent:
//
//    1. read the rules (pre-check, or `content.violations` of a refusal);
//    2. show them all, and open the screen of the first one;
//    3. when the rider comes back, read the rules again - never tick an item
//       off locally, the rules depend on live data (balance) and on a rule
//       set an admin can change at any time;
//    4. repeat until satisfied, then run the action.
//

import UIKit
import SwiftUI

enum ActionEligibilityFlow {

    private static let repository = EligibilityRepository()

    /// Runs `perform` once the rules for `check` are met, walking the rider
    /// through the missing steps first. If the pre-check cannot be read the
    /// action runs anyway: the backend still enforces the rules, and its
    /// refusal is handled by `handleRejection`.
    ///
    /// - Parameter blocked: called when the rules are shown instead of the
    ///   action running, e.g. to stop a loading state.
    static func run(_ check: EligibilityCheck,
                    from presenter: UIViewController? = nil,
                    blocked: (() -> Void)? = nil,
                    perform: @escaping () -> Void) {
        repository.check(check) { result in
            guard case .success(let eligibility) = result,
                  !eligibility.satisfied, !eligibility.violations.isEmpty else {
                perform()
                return
            }

            blocked?()
            present(violations: eligibility.violations, check: check, from: presenter, onSatisfied: perform)
        }
    }

    /// Takes over an error that came from an action refused for unmet rules.
    ///
    /// - Parameters:
    ///   - message: the error message the screen received.
    ///   - check: the action's pre-check, if the screen knows it; otherwise it
    ///     is derived from the refused request.
    ///   - retry: runs the action again once the rules are met.
    /// - Returns: false when the error is not such a refusal, so the caller
    ///   shows it as usual.
    @discardableResult
    static func handleRejection(message: String?,
                                check: EligibilityCheck? = nil,
                                from presenter: UIViewController? = nil,
                                retry: (() -> Void)? = nil) -> Bool {
        guard let rejection = ActionRejectionStore.shared.take(matching: message) else { return false }

        present(violations: rejection.violations, check: check ?? rejection.check, from: presenter, onSatisfied: retry)

        return true
    }

    private static func present(violations: [EligibilityViolation],
                                check: EligibilityCheck?,
                                from presenter: UIViewController?,
                                onSatisfied: (() -> Void)?) {
        guard let presenter = presenter ?? UIApplication.shared.topMostViewController() else { return }

        // Already walking the rider through the rules: refresh the list.
        if let current = presenter as? RequirementsHostingController {
            current.update(violations: violations, check: check, onSatisfied: onSatisfied)
            return
        }

        let controller = RequirementsHostingController(violations: violations,
                                                       check: check,
                                                       repository: repository,
                                                       onSatisfied: onSatisfied)
        presenter.present(controller, animated: true)
    }
}

final class RequirementsHostingController: UIHostingController<RequirementsView> {

    private let viewModel: RequirementsViewModel
    private let repository: EligibilityRepository
    private let profileService = RequirementsProfileService()

    private var check: EligibilityCheck?
    private var onSatisfied: (() -> Void)?

    init(violations: [EligibilityViolation],
         check: EligibilityCheck?,
         repository: EligibilityRepository,
         onSatisfied: (() -> Void)?) {
        self.viewModel = RequirementsViewModel(violations: violations, purpose: check.purposeTitle)
        self.check = check
        self.repository = repository
        self.onSatisfied = onSatisfied

        super.init(rootView: RequirementsView(viewModel: viewModel))

        viewModel.primaryAction = { [weak self] in self?.openPrimaryTarget() }
        viewModel.close = { [weak self] in self?.dismiss(animated: true) }

        modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            sheetPresentationController?.detents = [.medium(), .large()]
            sheetPresentationController?.prefersGrabberVisible = true
        }
        view.backgroundColor = .appSecondaryBackground
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func update(violations: [EligibilityViolation], check: EligibilityCheck?, onSatisfied: (() -> Void)?) {
        viewModel.violations = violations
        viewModel.checkFailed = false
        self.check = check ?? self.check
        self.onSatisfied = onSatisfied ?? self.onSatisfied
        viewModel.purpose = self.check.purposeTitle
    }

    // MARK: - Redirect

    private func openPrimaryTarget() {
        guard let primary = viewModel.violations.first else { return }

        let fields = viewModel.violations.primaryFields

        switch primary.target {
        case .wallet, .card:
            // Cards are attached from the wallet screen.
            open(WalletHostingController())
        case .support:
            open(SupportNavigationViewController.initFromStoryboard(name: Constant.Storyboards.accountCover))
        case .profile:
            openFields(fields, isAddress: false)
        case .address:
            openFields(fields, isAddress: true)
        case .documents:
            let viewModel = DocumentUploadViewModel(fields: fields, check: check)
            open(UIHostingController(rootView: DocumentUploadView(viewModel: viewModel)))
        case .emailVerification:
            openEmailVerification()
        case .none:
            dismiss(animated: true)
        }
    }

    private func openFields(_ fields: [RequirementField], isAddress: Bool) {
        let viewModel = RequirementFieldsViewModel(fields: fields, isAddress: isAddress)
        open(UIHostingController(rootView: RequirementFieldsView(viewModel: viewModel)))
    }

    private func openEmailVerification() {
        viewModel.isChecking = true

        profileService.loadProfile { [weak self] profile in
            guard let self else { return }

            self.viewModel.isChecking = false

            guard let email = profile?["email"] as? String, !email.isEmpty else {
                // Nothing to verify yet: ask for the address first.
                self.openFields([.email], isAddress: false)
                return
            }

            AuthRepository().sendCodeToEmail(userId: "", deviceID: "") { _ in }

            let verifyController = VerifyEmailConfigurator.config(with: email)
            let navigationController = UINavigationController(rootViewController: verifyController)
            verifyController.addCloseButton()

            self.open(navigationController)
        }
    }

    private func open(_ screen: UIViewController) {
        let container = RedirectContainerViewController(content: screen) { [weak self] in
            self?.recheck()
        }

        present(container, animated: true)
    }

    // MARK: - Re-check

    private func recheck() {
        guard let check else {
            // No pre-check for this action: let the action itself answer.
            finish()
            return
        }

        viewModel.isChecking = true
        viewModel.checkFailed = false
        repository.check(check) { [weak self] result in
            guard let self else { return }

            self.viewModel.isChecking = false

            switch result {
            case .success(let eligibility):
                if eligibility.satisfied || eligibility.violations.isEmpty {
                    self.finish()
                } else {
                    self.viewModel.violations = eligibility.violations
                }
            case .failure:
                // Keep the list and say so; the rider can try the step again.
                self.viewModel.checkFailed = true
            }
        }
    }

    private func finish() {
        let onSatisfied = onSatisfied

        dismiss(animated: true) {
            onSatisfied?()
        }
    }
}

/// Wraps a redirect screen to tell when the rider has left it, whichever way
/// the screen closes itself.
private final class RedirectContainerViewController: UIViewController {

    private let content: UIViewController
    private var closed: (() -> Void)?

    init(content: UIViewController, closed: @escaping () -> Void) {
        self.content = content
        self.closed = closed

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = content.modalPresentationStyle == .fullScreen ? .fullScreen : .pageSheet
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .appSecondaryBackground

        addChild(content)
        content.view.frame = view.bounds
        content.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(content.view)
        content.didMove(toParent: self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // Covered by another screen (a payment page) is not closed.
        guard isBeingDismissed || presentingViewController == nil else { return }

        closed?()
        closed = nil
    }
}
