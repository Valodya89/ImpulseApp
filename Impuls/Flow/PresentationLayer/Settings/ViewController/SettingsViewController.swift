//
//  SettingsViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import UIKit
import UserNotifications

final class SettingsViewController: UIViewController {

    @IBOutlet weak var `switch`: UISwitch!
    @IBOutlet weak var themeLabel: UILabel!
    @IBOutlet weak var themeSegmentedControl: UISegmentedControl!
    let viewModel = SettingsViewModel()

    var languages: [LanguageResult]?

    /// Shown under the push switch when notifications are off for the app in
    /// iOS Settings: the account-level switch above it only tells the backend
    /// whether to send, and cannot help with a system-level denial.
    private let systemNotificationsHint = UIView()
    private let systemNotificationsHintLabel = UILabel()
    private let systemNotificationsButton = UIButton(type: .system)


    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: Constant.Notifications.LanguageUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshSystemNotificationsHint), name: UIApplication.didBecomeActiveNotification, object: nil)
        setupSystemNotificationsHint()
        setupThemeControl()
        UserManager.share.getUser { [weak self] result in
            switch result {
            case .success(let user):
                self?.switch.setOn(user.settings?.sendPush ?? true, animated: true)
            case .failure(let error):
                self?.showErrorAlertMessage("Can not get user information")
            }
        }
        self.viewModel.getLanguages { [weak self] (result) in
            switch result {
            case .success(let languages):
                self?.languages = languages
            case .failure: break
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        refreshSystemNotificationsHint()
    }

    @objc func updateUI() {
        self.navigationItem.title = "MOBILE_profile_settings".localized()
        updateThemeTitles()
        updateSystemNotificationsHintTitles()
    }

    // MARK: - System notification permission

    /// Builds the hint card and slots it right under the push-switch row of
    /// the storyboard's preferences stack; hidden until a denial is known.
    private func setupSystemNotificationsHint() {
        // The switch sits in a card inside the row that the stack arranges.
        var row: UIView? = `switch`
        while let candidate = row, !(candidate.superview is UIStackView) {
            row = candidate.superview
        }
        guard let row, let stack = row.superview as? UIStackView,
              let index = stack.arrangedSubviews.firstIndex(of: row) else { return }

        let card = UIView()
        card.backgroundColor = .mimoWhite
        card.layer.cornerRadius = 5
        card.translatesAutoresizingMaskIntoConstraints = false

        systemNotificationsHintLabel.font = UIFont(name: "Roboto-Regular", size: 14) ?? .systemFont(ofSize: 14)
        systemNotificationsHintLabel.textColor = .appSecondaryLabel
        systemNotificationsHintLabel.numberOfLines = 0

        systemNotificationsButton.titleLabel?.font = UIFont(name: "Roboto-Medium", size: 15) ?? .systemFont(ofSize: 15, weight: .medium)
        systemNotificationsButton.setTitleColor(.onBrandLabel, for: .normal)
        systemNotificationsButton.backgroundColor = .mimoYellow500
        systemNotificationsButton.layer.cornerRadius = 8
        systemNotificationsButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        systemNotificationsButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        systemNotificationsButton.addTarget(self, action: #selector(openSystemNotificationSettings), for: .touchUpInside)

        let content = UIStackView(arrangedSubviews: [systemNotificationsHintLabel, systemNotificationsButton])
        content.axis = .vertical
        content.alignment = .leading
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)

        systemNotificationsHint.addSubview(card)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 15),
            card.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: 15),
            card.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: 14),

            card.topAnchor.constraint(equalTo: systemNotificationsHint.topAnchor),
            card.leadingAnchor.constraint(equalTo: systemNotificationsHint.leadingAnchor, constant: 10),
            systemNotificationsHint.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: 10),
            systemNotificationsHint.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])

        systemNotificationsHint.isHidden = true
        stack.insertArrangedSubview(systemNotificationsHint, at: index + 1)
        updateSystemNotificationsHintTitles()
    }

    private func updateSystemNotificationsHintTitles() {
        systemNotificationsHintLabel.text = "MOBILE_settings_system_notifications_disabled".localized(fallback: "Notifications are turned off for Impulse in iOS Settings, so you will not hear about top-ups, transfers and your rentals. Turn them on to get them back.")
        systemNotificationsButton.setTitle("MOBILE_settings_open_notification_settings".localized(fallback: "Open notification settings"), for: .normal)
    }

    /// Re-read on every appearance and on return from iOS Settings: the rider
    /// may have just flipped the switch there.
    @objc private func refreshSystemNotificationsHint() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            let denied = settings.authorizationStatus == .denied
            DispatchQueue.main.async {
                self?.systemNotificationsHint.isHidden = !denied
            }
        }
    }

    /// The app's own notification page in iOS Settings (iOS 16+), else the
    /// app's settings page.
    @objc private func openSystemNotificationSettings() {
        let urlString: String
        if #available(iOS 16.0, *) {
            urlString = UIApplication.openNotificationSettingsURLString
        } else {
            urlString = UIApplication.openSettingsURLString
        }
        guard let url = URL(string: urlString) else { return }

        UIApplication.shared.open(url)
    }

    // MARK: - Appearance (light / dark mode)
    
    private func setupThemeControl() {
        updateThemeTitles()
        themeSegmentedControl.selectedSegmentTintColor = .mimoYellow500
        themeSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.onBrandLabel], for: .selected)
        themeSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.appLabel], for: .normal)
        themeSegmentedControl.selectedSegmentIndex = AppTheme.ordered.firstIndex(of: ThemeManager.shared.theme) ?? 0
    }
    
    private func updateThemeTitles() {
        themeLabel.text = "MOBILE_settings_appearance".localized(fallback: "Appearance")
        for (index, theme) in AppTheme.ordered.enumerated() where index < themeSegmentedControl.numberOfSegments {
            themeSegmentedControl.setTitle(theme.title, forSegmentAt: index)
        }
    }
    
    @IBAction func themeChanged(_ sender: UISegmentedControl) {
        guard AppTheme.ordered.indices.contains(sender.selectedSegmentIndex) else { return }
        ThemeManager.shared.set(AppTheme.ordered[sender.selectedSegmentIndex])
    }
    
    func selectOneItem(index: Int) {
        for i in 0..<(languages?.count ?? 0) {
            if i == index {
                languages?[i].isSelected = true
            } else {
                languages?[i].isSelected = false
            }
        }
    }
    
    
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func settinTapped(_ sender: Any) {
        guard let languages = languages else { return }
        
        let languageViewController = LanguageViewController.initFromStoryboard(name: Constant.Storyboards.signIn)
        
        languageViewController.languages = languages
        languageViewController.delegate = self
        present(languageViewController, animated: true, completion: nil)
    }
    
    @IBAction func switchTapped(_ sender: UISwitch) {
        UserManager.share.getUser { [weak self] result in
            switch result {
            case .failure(let error):
                self?.showErrorAlertMessage(error.localizedDescription)
            case .success(let user):
                var settings = user.settings
                settings?.sendPush = sender.isOn
                
                UserManager.share.updateSettings(settings: settings) { [weak self] result in
                    switch result {
                    case .failure(let error):
                        sender.setOn(!sender.isOn, animated: true)
                    case .success(let user):
                        sender.setOn(user.settings?.sendPush ?? true, animated: true)
                    }
                }
            }
        }
    }
}


// MARK: - Language ViewController Delegate
extension SettingsViewController: LanguageViewControllerDelegate {
    
    func didChoose(index: Int) {
       selectOneItem(index: index)
    }
}
