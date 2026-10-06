//
//  MimoSupportView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 13.08.23.
//

import UIKit

/// The map support banner. Opens the same support chat as Profile > Support,
/// taken from GET /contact-info (`SupportContactsStore`): the only messenger
/// directly, a chooser when both Telegram and WhatsApp exist, the hotline
/// when there is no chat, and the banner is hidden when the server has no
/// contacts for the app.
class MimoSupportView: UIView {
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet private weak var containerView: UIView!

    /// The messenger glyph of the nib (the only non-symbol image view; the
    /// trailing chevron is a system symbol). Follows the single channel.
    private weak var messengerIcon: UIImageView?

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("MimoSupportView", owner: self)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        containerView.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)

        messengerIcon = Self.imageViews(in: contentView).first { $0.image?.isSymbolImage == false }

        SupportContactsStore.shared.loadIfNeeded()
        NotificationCenter.default.addObserver(self, selector: #selector(renderContacts), name: SupportContactsStore.didChange, object: nil)
        renderContacts()
    }

    private var contacts: SupportContacts? { SupportContactsStore.shared.contacts }

    /// Only the nib content is hidden, not the view itself: the hosting
    /// screens toggle `isHidden` on the banner for their own reasons (trips,
    /// zone status) and must keep doing so.
    @objc private func renderContacts() {
        let contacts = contacts
        contentView.isHidden = !(contacts?.hasAnyContact ?? false)
        guard let messengerIcon else { return }
        if contacts?.messengers == [.whatsapp] {
            messengerIcon.image = UIImage(systemName: "message.fill")?.withRenderingMode(.alwaysTemplate)
        } else {
            messengerIcon.image = UIImage(named: "ic_telegram")
        }
    }

    private static func imageViews(in view: UIView) -> [UIImageView] {
        view.subviews.flatMap { subview -> [UIImageView] in
            if let imageView = subview as? UIImageView { return [imageView] }
            return imageViews(in: subview)
        }
    }
    
    @IBAction private func supportAction() {
        guard let contacts else { return }
        let messengers = contacts.messengers
        switch messengers.count {
        case 0:
            // No chat for this country: the hotline is the only contact.
            if let url = contacts.dialURL, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        case 1:
            open(contacts.url(for: messengers[0]))
        default:
            presentChooser(for: contacts)
        }
    }

    /// Opened as returned: `https://t.me` goes to Telegram when installed and
    /// the browser otherwise, `https://wa.me` to WhatsApp or WhatsApp Web.
    private func open(_ url: URL?) {
        guard let url else { return }
        UIApplication.shared.open(url)
    }

    /// Both messengers exist: let the rider pick, Telegram first.
    private func presentChooser(for contacts: SupportContacts) {
        guard let presenter = UIApplication.topController() else {
            open(contacts.telegramURL)
            return
        }
        let sheet = UIAlertController(title: "MOBILE_mimo_support".localized(fallback: "Contact Impulse Support"),
                                      message: nil,
                                      preferredStyle: .actionSheet)
        for messenger in contacts.messengers {
            let title: String
            switch messenger {
            case .telegram: title = "MOBILE_support_chat_telegram".localized(fallback: "Chat on Telegram")
            case .whatsapp: title = "MOBILE_support_chat_whatsapp".localized(fallback: "Chat on WhatsApp")
            }
            sheet.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.open(contacts.url(for: messenger))
            })
        }
        sheet.addAction(UIAlertAction(title: "MOBILE_global_cancel".localized(fallback: "Cancel"), style: .cancel))
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = containerView
            popover.sourceRect = containerView.bounds
        }
        presenter.present(sheet, animated: true)
    }
}
