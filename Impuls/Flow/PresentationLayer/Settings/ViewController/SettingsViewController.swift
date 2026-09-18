//
//  SettingsViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/4/21.
//

import UIKit

final class SettingsViewController: UIViewController {
    
    @IBOutlet weak var `switch`: UISwitch!
    @IBOutlet weak var themeLabel: UILabel!
    @IBOutlet weak var themeSegmentedControl: UISegmentedControl!
    let viewModel = SettingsViewModel()
    
    var languages: [LanguageResult]?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: Constant.Notifications.LanguageUpdate, object: nil)
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
    
    @objc func updateUI() {
        self.navigationItem.title = "MOBILE_profile_settings".localized()
        updateThemeTitles()
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
