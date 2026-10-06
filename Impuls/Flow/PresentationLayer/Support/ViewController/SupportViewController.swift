//
//  SupportViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import UIKit

final class SupportViewController: UIViewController, StoryboardInitializable {
    
    let supportViewModel = SupportViewModel()

    /// One "Contact Impulse Support" card per messenger the server returned.
    private struct ChatCard {
        let messenger: SupportContacts.Messenger
        let row: UIView
        let titleLabel: UILabel
        let button: UIButton
    }

    private var chatCards: [ChatCard] = []
    /// The storyboard "Call now" row (the arranged subview holding the `call:`
    /// button); hidden when the server returns no hotline.
    private weak var callRow: UIView?
    /// Where the chat cards go when the storyboard stack cannot be found.
    private weak var fallbackStack: UIStackView?

    override func viewDidLoad() {
        super.viewDidLoad()

        callRow = findCallRow()
        renderContacts()
        supportViewModel.loadContacts()
        NotificationCenter.default.addObserver(self, selector: #selector(renderContacts), name: SupportContactsStore.didChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(localizeChatCards), name: Constant.Notifications.LanguageUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(localizeChatCards), name: Constant.Notifications.TranslationsUpdate, object: nil)
    }
    
    @IBAction func call(_ sender: UIButton) {
        supportViewModel.call()
    }
    
    @IBAction func informProblem(_ sender: UIButton) {
        let informProblemViewController = ImportProblemViewController.initFromStoryboard(name: Constant.Storyboards.account)
        
        self.navigationController?.pushViewController(informProblemViewController, animated: true)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func chatCardTapped(_ sender: UIButton) {
        guard let card = chatCards.first(where: { $0.button === sender }) else { return }
        supportViewModel.openChat(card.messenger)
    }

    // MARK: - Contacts

    /// Rebuilds the contact rows from the store: one chat card per non-null
    /// messenger (Telegram first, then WhatsApp) above the "Call now" row,
    /// which is hidden when there is no hotline. When the server has no
    /// contacts for the app at all, every contact entry point is hidden.
    @objc private func renderContacts() {
        let contacts = supportViewModel.contacts

        chatCards.forEach { $0.row.removeFromSuperview() }
        chatCards = []

        for messenger in contacts?.messengers ?? [] {
            let card = makeChatCard(for: messenger)
            insert(cardRow: card.row)
            chatCards.append(card)
        }
        callRow?.isHidden = contacts?.phone == nil
        localizeChatCards()
    }

    private func insert(cardRow: UIView) {
        if let stack = storyboardStack {
            // Right above the "Call now" row so the chats are the first
            // contact options; chat cards keep their relative order.
            let callIndex = callRow.flatMap { stack.arrangedSubviews.firstIndex(of: $0) }
            let index = min(callIndex ?? max(stack.arrangedSubviews.count - 1, 0), stack.arrangedSubviews.count)
            stack.insertArrangedSubview(cardRow, at: index)
        } else {
            fallbackContainer.addArrangedSubview(cardRow)
        }
    }

    /// The storyboard scene (AccountCover > Support) is a vertical stack of
    /// illustration, title and the "Call now" row and exposes no outlets, so
    /// the stack is looked up by type.
    private var storyboardStack: UIStackView? {
        view.subviews.compactMap { $0 as? UIStackView }.first { $0.axis == .vertical }
    }

    /// When the stack cannot be found the cards are pinned to the bottom of
    /// the screen instead of being dropped.
    private var fallbackContainer: UIStackView {
        if let fallbackStack { return fallbackStack }
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
        fallbackStack = stack
        return stack
    }

    private func findCallRow() -> UIView? {
        storyboardStack?.arrangedSubviews.first { containsCallButton($0) }
    }

    private func containsCallButton(_ view: UIView) -> Bool {
        if let button = view as? UIButton,
           button.actions(forTarget: self, forControlEvent: .touchUpInside)?.contains("call:") == true {
            return true
        }
        return view.subviews.contains { containsCallButton($0) }
    }

    // MARK: - Chat cards

    /// With a single messenger the card keeps the generic "Contact Impulse
    /// Support" title; with both, each card names its messenger.
    private func chatTitle(for messenger: SupportContacts.Messenger) -> String {
        let generic = "MOBILE_mimo_support".localized(fallback: "Contact Impulse Support")
        guard chatCards.count > 1 else { return generic }
        switch messenger {
        case .telegram:
            return "MOBILE_support_chat_telegram".localized(fallback: "Chat on Telegram")
        case .whatsapp:
            return "MOBILE_support_chat_whatsapp".localized(fallback: "Chat on WhatsApp")
        }
    }

    @objc private func localizeChatCards() {
        for card in chatCards {
            let title = chatTitle(for: card.messenger)
            card.titleLabel.text = title
            card.button.accessibilityLabel = title
        }
    }

    /// The messenger glyph. Telegram has an asset; WhatsApp uses a system
    /// chat symbol until a `ic_whatsapp` asset is added to the catalog.
    private static func icon(for messenger: SupportContacts.Messenger) -> UIImage? {
        switch messenger {
        case .telegram:
            return UIImage(named: "ic_telegram")?.withRenderingMode(.alwaysTemplate)
        case .whatsapp:
            return UIImage(systemName: "message.fill")?.withRenderingMode(.alwaysTemplate)
        }
    }

    /// Same visual language as the storyboard "Call now" row (white card,
    /// 5 pt corners, leading glyph, Roboto 17 title, bold chevron) so the
    /// contact options read as one list.
    private func makeChatCard(for messenger: SupportContacts.Messenger) -> ChatCard {
        // Transparent row container with the same 10 pt side insets as the
        // storyboard's "Call now" row, so all cards line up.
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.backgroundColor = .clear
        row.isAccessibilityElement = false

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .mimoWhite
        card.layer.cornerRadius = 5
        card.isUserInteractionEnabled = false

        let icon = UIImageView(image: Self.icon(for: messenger))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = .mimoBlack
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .mimoBlack
        label.font = UIFont(name: "Roboto-Regular", size: 17) ?? .systemFont(ofSize: 17)
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let chevron = UIImageView(image: UIImage(named: "ic_arrow_right_bold"))
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.contentMode = .scaleAspectFit
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        // A full-size button on top of the card gives the whole surface the
        // tap target and the pressed state.
        let button = ChatCardButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(chatCardTapped(_:)), for: .touchUpInside)
        button.accessibilityTraits = .button
        switch messenger {
        case .telegram: button.accessibilityIdentifier = "support.contactTelegram"
        case .whatsapp: button.accessibilityIdentifier = "support.contactWhatsApp"
        }
        button.highlightTarget = card

        card.addSubview(icon)
        card.addSubview(label)
        card.addSubview(chevron)
        row.addSubview(card)
        row.addSubview(button)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: row.topAnchor),
            card.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            card.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 10),
            card.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -10),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 44),

            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 13),
            icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 18),
            icon.heightAnchor.constraint(equalToConstant: 18),

            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 8),
            label.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            label.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -10),

            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -15),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 14),
            chevron.heightAnchor.constraint(equalToConstant: 14),

            button.topAnchor.constraint(equalTo: card.topAnchor),
            button.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            button.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: card.trailingAnchor)
        ])

        return ChatCard(messenger: messenger, row: row, titleLabel: label, button: button)
    }
}

/// Transparent hit-area button that dims the card it covers while pressed,
/// the way the SwiftUI `EVContactSupportButton` does.
private final class ChatCardButton: UIButton {
    weak var highlightTarget: UIView?

    override var isHighlighted: Bool {
        didSet {
            guard oldValue != isHighlighted else { return }
            UIView.animate(withDuration: 0.12, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
                self.highlightTarget?.alpha = self.isHighlighted ? 0.7 : 1
            }
        }
    }
}
