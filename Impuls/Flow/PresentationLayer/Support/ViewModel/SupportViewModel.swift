//
//  SupportViewModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import UIKit

struct SupportViewModel {

    /// The contacts GET /contact-info returned for this app and country (or
    /// the bundled fallback until it answers); nil = the server has no
    /// contacts for the app, every entry point is hidden.
    var contacts: SupportContacts? { SupportContactsStore.shared.contacts }

    /// Asks the store for the contacts (a no-op once loaded).
    func loadContacts() {
        SupportContactsStore.shared.loadIfNeeded()
    }

    /// Dials the hotline the server returned, exactly as returned (E.164).
    func call() {
        guard let phone = contacts?.phone else { return }
        call(phoneNumber: phone)
    }

    func call(phoneNumber: String) {
        if let url = URL(string: "tel://\(phoneNumber)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    /// Opens the support chat on `messenger` (the same chat as the map
    /// support banner and the live-session row). The `telegramUrl` /
    /// `whatsappUrl` links are opened as the server returned them: an
    /// `https://t.me` link is routed to the Telegram app when it is installed
    /// and to the browser otherwise, an `https://wa.me` link to WhatsApp or
    /// WhatsApp Web, so no `canOpenURL` check and no custom scheme is used.
    func openChat(_ messenger: SupportContacts.Messenger) {
        guard let url = contacts?.url(for: messenger) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
