//
//  SupportViewModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import UIKit

struct SupportViewModel {
    
    func call(phoneNumber: String) {
        if let url = URL(string: "tel://\(phoneNumber)") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
    }

    /// Opens the Impulse support chat in Telegram (the same chat as the map
    /// support banner and the live-session row, see `SupportContact`). The
    /// `https://t.me` link is routed to the Telegram app when it is installed
    /// and to the browser otherwise, so it is opened without a `canOpenURL`
    /// check.
    func contactSupport() {
        guard let url = SupportContact.telegramChatURL else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
