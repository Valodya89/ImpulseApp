//
//  TransferContactPicker.swift
//  Impuls
//
//  Presents the system address-book picker for "Find from contacts" on top
//  of the transfer sheet. Only contacts with at least one phone number are
//  selectable; the chosen contact's numbers are handed back as strings once
//  the picker is off screen.
//
//  It is presented with UIKit on purpose. `CNContactPickerViewController` is
//  a remote view controller that dismisses itself after a pick; hosted in a
//  SwiftUI `.sheet` that dismissal took the whole transfer screen down with
//  it, so the rider never reached the amount step.
//

import UIKit
import ContactsUI
import ObjectiveC

final class TransferContactPicker: NSObject, CNContactPickerDelegate {

    private let onPick: ([String]) -> Void

    private init(onPick: @escaping ([String]) -> Void) {
        self.onPick = onPick
    }

    /// Presents the picker on `presenter`, or on whatever controller is
    /// currently on top. `onPick` runs on the main thread after the picker
    /// has been dismissed, so a loader or a dialog can follow it straight away.
    static func present(from presenter: UIViewController? = nil, onPick: @escaping ([String]) -> Void) {
        guard let presenter = presenter ?? UIApplication.shared.topMostViewController() else { return }

        let delegate = TransferContactPicker(onPick: onPick)
        let picker = CNContactPickerViewController()
        picker.delegate = delegate
        picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
        // `delegate` is weak on the picker; tie this object's lifetime to it.
        objc_setAssociatedObject(picker, &delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        presenter.present(picker, animated: true)
    }

    // MARK: - CNContactPickerDelegate

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let numbers = contact.phoneNumbers.map { $0.value.stringValue }
        VibrateManager.vibrate()

        let onPick = self.onPick
        afterDismissal(of: picker) {
            onPick(numbers)
        }
    }

    // MARK: - Private

    /// Runs `completion` once the picker is gone. The picker dismisses itself
    /// after a pick, and whether that has already started when the delegate
    /// is called is not guaranteed, so every ordering is handled: not yet
    /// started (dismiss it here and wait), in progress (wait for the
    /// transition), or already done.
    private func afterDismissal(of picker: UIViewController, completion: @escaping () -> Void) {
        guard picker.presentingViewController != nil else {
            completion()
            return
        }

        if picker.isBeingDismissed {
            if let coordinator = picker.transitionCoordinator {
                coordinator.animate(alongsideTransition: nil) { _ in completion() }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: completion)
            }
            return
        }

        picker.dismiss(animated: true, completion: completion)
    }
}

private var delegateKey = 0
