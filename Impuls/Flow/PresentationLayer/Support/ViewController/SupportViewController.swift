//
//  SupportViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import UIKit

final class SupportViewController: UIViewController, StoryboardInitializable {
    
    let supportViewModel = SupportViewModel()
    /// The Telegram card title; re-localised when translations arrive.
    private weak var telegramTitleLabel: UILabel?
    private weak var telegramButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()

        installTelegramCard()
        NotificationCenter.default.addObserver(self, selector: #selector(localizeTelegramCard), name: Constant.Notifications.LanguageUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(localizeTelegramCard), name: Constant.Notifications.TranslationsUpdate, object: nil)
    }
    
    @IBAction func call(_ sender: UIButton) {
        supportViewModel.call(phoneNumber: "+79165132326")
    }
    
    @IBAction func informProblem(_ sender: UIButton) {
        let informProblemViewController = ImportProblemViewController.initFromStoryboard(name: Constant.Storyboards.account)
        
        self.navigationController?.pushViewController(informProblemViewController, animated: true)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    @objc private func contactSupportTapped() {
        supportViewModel.contactSupport()
    }

    // MARK: - Telegram card

    private static var telegramTitle: String {
        "MOBILE_mimo_support".localized(fallback: "Contact Impulse Support")
    }

    @objc private func localizeTelegramCard() {
        let title = Self.telegramTitle
        telegramTitleLabel?.text = title
        telegramButton?.accessibilityLabel = title
    }

    /// The "Contact Impulse Support" card is added from code: the storyboard
    /// scene (AccountCover > Support) is a vertical stack of illustration, title
    /// and the "Call now" row, and the card goes right above that row so
    /// Telegram is the first contact option. The scene exposes no outlets, so
    /// the stack is looked up by type; when it cannot be found the card is
    /// pinned to the bottom of the screen instead of being dropped.
    private func installTelegramCard() {
        let card = makeTelegramCard()

        if let stack = view.subviews.compactMap({ $0 as? UIStackView }).first(where: { $0.axis == .vertical }) {
            let callRowIndex = max(stack.arrangedSubviews.count - 1, 0)
            // The stack fills its rows edge to edge; the card keeps the same
            // 10 pt side inset as the "Call now" row through its own layout.
            stack.insertArrangedSubview(card, at: callRowIndex)
        } else {
            view.addSubview(card)
            NSLayoutConstraint.activate([
                card.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                card.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                card.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            ])
        }
    }

    /// Same visual language as the storyboard "Call now" row (white card,
    /// 5 pt corners, leading glyph, Roboto 17 title, bold chevron) so the two
    /// contact options read as one list.
    private func makeTelegramCard() -> UIView {
        let title = Self.telegramTitle

        // Transparent row container with the same 10 pt side insets as the
        // storyboard's "Call now" row, so both cards line up.
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        row.backgroundColor = .clear
        row.isAccessibilityElement = false

        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .mimoWhite
        card.layer.cornerRadius = 5
        card.isUserInteractionEnabled = false

        let icon = UIImageView(image: UIImage(named: "ic_telegram")?.withRenderingMode(.alwaysTemplate))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.tintColor = .mimoBlack
        icon.contentMode = .scaleAspectFit

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = title
        label.textColor = .mimoBlack
        label.font = UIFont(name: "Roboto-Regular", size: 17) ?? .systemFont(ofSize: 17)
        label.numberOfLines = 2
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.85
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        telegramTitleLabel = label

        let chevron = UIImageView(image: UIImage(named: "ic_arrow_right_bold"))
        chevron.translatesAutoresizingMaskIntoConstraints = false
        chevron.contentMode = .scaleAspectFit
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        // A full-size button on top of the card gives the whole surface the
        // tap target and the pressed state.
        let button = TelegramCardButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.addTarget(self, action: #selector(contactSupportTapped), for: .touchUpInside)
        button.accessibilityLabel = title
        button.accessibilityTraits = .button
        button.accessibilityIdentifier = "support.contactTelegram"
        button.highlightTarget = card
        telegramButton = button

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

        return row
    }
}

/// Transparent hit-area button that dims the card it covers while pressed,
/// the way the SwiftUI `EVContactSupportButton` does.
private final class TelegramCardButton: UIButton {
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
