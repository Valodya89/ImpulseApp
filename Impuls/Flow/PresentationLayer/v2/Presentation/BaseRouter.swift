//
//  BaseRouter.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.07.23.
//

import Foundation
import SwiftUI

class BaseRouter {
    
    public static let shared: BaseRouter = BaseRouter()
    
    private init() {}
    
    func showSplashView() {
        HomeRouter.shared.reset()
        UIApplication.shared.connectedScenes.flatMap({ ($0 as? UIWindowScene)?.windows ?? [] }).first(where: { $0.isKeyWindow })?.rootViewController = UIHostingController(rootView: SplashView())
    }
    
    func showLoginView() {
        HomeRouter.shared.reset()
        UIApplication.shared.connectedScenes.flatMap({ ($0 as? UIWindowScene)?.windows ?? [] }).first(where: { $0.isKeyWindow })?.rootViewController = UIHostingController(rootView: LoginView(viewModel: LoginViewModel(locationManager: Resolver.resolve(), activeTrips: [])))
    }
    
    func showDebtViewController(_ viewController: UIViewController?, debtAmount: Double?, debtWallets: [WalletDebts]?, delegate: ShowDebtViewControllerDdelegate?) {
        let scooterPlanStoryboard: UIStoryboard = UIStoryboard(name: Constant.Storyboards.scooterPlan, bundle: nil)
        if let debtViewController: ShowDebtViewController = scooterPlanStoryboard.instantiate() {
            debtViewController.modalPresentationStyle = .fullScreen
            debtViewController.amount = debtAmount ?? 0
            debtViewController.wallets = debtWallets ?? []
            debtViewController.delegate = delegate
            
            viewController?.present(debtViewController, animated: true)
        }
    }
    
    func showTransferToFirendViewController(_ viewController: UIViewController?, phoneNumber: String, transferUser: ContactsListModel?, debt: Double?) {
        let user = UserResult(userResponse: UserManager.share.userResponse)
        let transferToFirendViewController = TransferToFriendViewController.initiateFromStoryboard(phoneNumber,
                                                                                                   user: user,
                                                                                                   avatarUrl: nil,
                                                                                                   wallet: UserManager.share.walletModel,
                                                                                                   transferUser: transferUser)
        transferToFirendViewController.debt = debt
        viewController?.present(transferToFirendViewController, animated: true)
    }
    
    func showNewsViewController(_ viewController: UIViewController?, news: [NewsObject]) {
        let newsViewController = StoriNewsViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
        newsViewController.modalPresentationStyle = .fullScreen
        newsViewController.news = news.first
        
        viewController?.present(newsViewController, animated: true)
    }
    
    func showForceUpdateViewController(_ viewController: UIViewController?) {
        let forceUpdateViewController = ForceUpdateViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
        forceUpdateViewController.modalPresentationStyle = .fullScreen
        
        viewController?.present(forceUpdateViewController, animated: true)
    }
}
