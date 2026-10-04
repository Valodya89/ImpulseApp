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
    
    /// The redesigned full-screen debt screen (DebtHostingController). Presented
    /// by the power-bank map when ipay GET /api/state is DEBT / DEBT_ON_DEVICE,
    /// and for a scan held back by a debt. Pass the state and wallet the map
    /// already has; with either missing the screen loads them itself.
    /// `onPaid` runs once the screen closed because nothing is left to settle.
    func showDebtScreen(_ viewController: UIViewController?, financialState: FinancialStateModel?, wallet: WalletModel?, onPaid: (() -> Void)?) {
        let debtScreen = DebtHostingController(financialState: financialState, wallet: wallet, onPaid: onPaid)
        (viewController ?? UIApplication.shared.topMostViewController())?.present(debtScreen, animated: true)
    }
    
    func showTransferToFirendViewController(_ viewController: UIViewController?, phoneNumber: String, transferUser: ContactsListModel?, debt: Double?) {
        // v2 transfer flow, opened straight on the amount step with the debtor
        // prefilled (see TransferHostingController). Paying a debt is a
        // transfer, so the sender's TRANSFER payment rules are checked first;
        // an unreadable pre-check opens the flow anyway.
        ActionEligibilityFlow.run(.transfer, from: viewController) { [weak viewController] in
            let transferToFirendViewController = TransferHostingController(wallet: UserManager.share.walletModel,
                                                                           phoneNumber: phoneNumber,
                                                                           transferUser: transferUser,
                                                                           debt: debt)
            (viewController ?? UIApplication.shared.topMostViewController())?.present(transferToFirendViewController, animated: true)
        }
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
