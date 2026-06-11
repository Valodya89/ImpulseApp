//
//  ProfileRouter.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 15.04.24.
//

import UIKit
import SwiftUI

final class ProfileRouter {
    
    private let navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func showHistoryScreen() {
        let coordinator = EVChargerCoordinator(navigationController: navigationController, provider: EVChargerProvider())
        let historyViewController = UIHostingController(rootView: HistoryView(viewModel: HistoryViewModel(coordinatoor: coordinator, worker: TripWorker())))
        
        navigationController.present(historyViewController, animated: true)
    }
    
    func showRateScreen() {
        let coordinator = EVChargerCoordinator(navigationController: navigationController, provider: EVChargerProvider())
        
        let partnershipView = UIHostingController(rootView: RatesView(viewModel: RatesViewModel(coordinatoor: coordinator)))
        
        navigationController.present(partnershipView, animated: true)
    }
    
    func showSupportScreen() {
        let supportViewController = SupportNavigationViewController.initFromStoryboard(name: Constant.Storyboards.accountCover)
        
        navigationController.present(supportViewController, animated: true)
    }
    
    func showHowToUseScreen() {
        let howtoUseViewController = HowToUseNavigationViewController.initFromStoryboard(name: Constant.Storyboards.accountCover)
        
        navigationController.present(howtoUseViewController, animated: true)
    }
    
    func showSettingsScreen() {
        let settingViewController = SettingNavigationViewController.initFromStoryboard(name: Constant.Storyboards.accountCover)
        
        navigationController.present(settingViewController, animated: true)
    }
    
    func showPartnershipScreen() {
        let partnershipView = UIHostingController(rootView: PartnershipView())
        
        navigationController.present(partnershipView, animated: true)
    }
    
    func showPrivacyPolicyScreen() {
        let privacyPolicyViewController = PrivacyPolicyNavigationViewController.initFromStoryboard(name: Constant.Storyboards.accountCover)
        
        navigationController.present(privacyPolicyViewController, animated: true)
    }
    
    func showAgreementScreen() {
        let agreementViewController = AgreementNavigationViewController.initFromStoryboard(name: Constant.Storyboards.accountCover)
        
        navigationController.present(agreementViewController, animated: true)
    }
    
    func showEmailVerifyScreen(email: String) {
        let verifyController = VerifyEmailConfigurator.config(with: email)
        let navVC = UINavigationController(rootViewController: verifyController)
        verifyController.addCloseButton()
        
        navigationController.present(navVC, animated: true)
    }
    
    func showEditProfileScreen(user: UserResponse?) {
        let completeAccountViewController = CompleteProfileViewController.config(with: true, existingModel: user, delegate: nil)
        navigationController.present(completeAccountViewController, animated: true, completion: nil)
    }
    
    func showWalletScreen() {
        navigationController.openWallet()
    }
    
    func showPackagesScreen() {
        let planController = MIPlansViewController.initFromStoryboard(name: "MIPlan")
        let navVC = UINavigationController(rootViewController: planController)
        planController.addCloseButton()
        
        navigationController.present(navVC, animated: true)
    }
}
