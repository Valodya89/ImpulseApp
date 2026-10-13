//
//  DeviceCheckManager.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 04.09.22.
//

import Foundation
import UIKit
import DeviceCheck

class DeviceCheckManager {
    
    static let shared = DeviceCheckManager()
    
    var deviceUnicToken = ""
    private var retriesWhenUnlocked = false

    /// Reads (or creates) the device identifier at launch. A launch that happens
    /// while the phone is still locked - a push waking the app in the background
    /// before the first unlock - cannot read the keychain; the identifier is then
    /// left empty and read again as soon as protected data becomes available,
    /// never regenerated.
    func sendEphemeralToken() {
        self.deviceUnicToken = checkAndSaveValueInKeychain()
        print("deviceUnicToken = \(self.deviceUnicToken)")

        if deviceUnicToken.isEmpty, !retriesWhenUnlocked {
            retriesWhenUnlocked = true
            NotificationCenter.default.addObserver(
                forName: UIApplication.protectedDataDidBecomeAvailableNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                guard let self, self.deviceUnicToken.isEmpty else { return }
                self.deviceUnicToken = self.checkAndSaveValueInKeychain()
            }
        }
    }
    
    /// The backend keys every device row on this value (and POST
    /// /account/refresh-token rebinds the account's active device to the id it
    /// receives), so it has to be generated once and then returned
    /// byte-identical forever - including on a launch that happens before the
    /// device has been unlocked, where it is left empty rather than replaced.
    func checkAndSaveValueInKeychain() -> String {
        if !deviceUnicToken.isEmpty { return deviceUnicToken }

        let (stored, status) = KeychainHelper.standard.read(service: "access-token", account: "Service")
        if let stored, let identifier = String(data: stored, encoding: .utf8), !identifier.isEmpty {
            // An item written by an older version is readable only while the
            // phone is unlocked; widen it now, while it can be read, so the next
            // locked launch finds it too.
            KeychainHelper.standard.widenAccessibility(service: "access-token", account: "Service")
            return identifier
        }

        // The item may well exist but cannot be read while the phone is locked
        // (a push woke the app before the first unlock): generating another id
        // now would give this install two identities. Report nothing, answer
        // nothing; `sendEphemeralToken` reads again once protected data is back.
        if status == errSecInteractionNotAllowed || !KeychainHelper.isProtectedDataAvailable {
            return ""
        }

        let newIdentifier = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        KeychainHelper.standard.save(Data(newIdentifier.utf8), service: "access-token", account: "Service")

        // Read back so a pre-existing item (the save is a no-op then) wins over the
        // value we just generated - two ids for one install is exactly the 404 case.
        if let stored = KeychainHelper.standard.read(service: "access-token", account: "Service").data,
           let identifier = String(data: stored, encoding: .utf8),
           !identifier.isEmpty {
            return identifier
        }

        return newIdentifier
    }
}

final class KeychainHelper {
    
    static let standard = KeychainHelper()
    private init() {}
    
    // Class implementation here...
    
    func save(_ data: Data, service: String, account: String) {

        // Create query
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            // Two properties matter here.
            // `AfterFirstUnlock`: the id is read during launch, which can happen
            // before the user unlocked the phone after a reboot - the default
            // (`WhenUnlocked`) made that read fail and the app fall back to an
            // empty id.
            // `ThisDeviceOnly`: the id identifies a device row the backend created
            // through SMS verification. Letting it ride along an iCloud/encrypted
            // backup onto new hardware would point two phones at one device row;
            // a restored phone should get a fresh id and go through sign-on again.
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ] as CFDictionary

        // Add data in query to keychain
        let status = SecItemAdd(query, nil)

        if status == errSecDuplicateItem {
            // Already stored - keep the existing value, it is the identity the
            // backend knows. Only widen its accessibility.
            widenAccessibility(service: service, account: account)
            return
        }

        // Locked phone (before the first unlock): the keychain refuses every
        // write. Expected, and retried once protected data is available.
        if status == errSecInteractionNotAllowed { return }

        if status != errSecSuccess {
            // A failed save means the next launch generates a different device id,
            // which the backend answers with 404 NO_SUCH_DEVICE.
            ErrorReporter.shared.reportAbnormalBehavior(
                "Keychain save failed for the device identifier",
                extra: ["osStatus": "\(status)", "service": service]
            )
        }
    }

    /// The item and the status of the read: `errSecInteractionNotAllowed`
    /// (-25308) means the item may exist but the phone is locked, which is not
    /// "no item" (`errSecItemNotFound`).
    func read(service: String, account: String) -> (data: Data?, status: OSStatus) {

        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary

        var result: AnyObject?
        let status = SecItemCopyMatching(query, &result)

        return (result as? Data, status)
    }

    /// Makes an existing item readable after the first unlock (older versions
    /// stored it with the default "while unlocked" accessibility).
    func widenAccessibility(service: String, account: String) {
        let identity = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as CFDictionary

        SecItemUpdate(identity, [kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly] as CFDictionary)
    }

    /// Whether the keychain can be read right now (false before the first
    /// unlock after a reboot). Safe off the main thread: a background read of
    /// the flag is tolerated and only used to avoid pointless keychain calls.
    static var isProtectedDataAvailable: Bool {
        if Thread.isMainThread { return UIApplication.shared.isProtectedDataAvailable }
        return DispatchQueue.main.sync { UIApplication.shared.isProtectedDataAvailable }
    }
}
