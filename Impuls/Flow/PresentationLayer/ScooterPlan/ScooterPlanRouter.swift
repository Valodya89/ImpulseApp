//
//  ScooterPlanRouter.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 02.06.23.
//

import Foundation

class ScooterPlanRouter {
    
    private let storyboard = UIStoryboard(name: "ScooterPlan", bundle: nil)
    
    public static let shared = ScooterPlanRouter()
    
    var pauseViewController: MimoPauseViewController?
    
    func showScooterPlanViewController(
        _ viewController: UIViewController?,
        scooterId: String,
        leasedScooters: [String]?,
        delegate: ScooterPlanViewControllerDelegate?,
        completion: (() -> Void)? = nil
    ) {
        if let scooterPlanViewController: ScooterPlanViewController = storyboard.instantiate() {
            scooterPlanViewController.modalPresentationStyle = .fullScreen
            scooterPlanViewController.scooterId = scooterId
            scooterPlanViewController.leasedScooters = leasedScooters
            scooterPlanViewController.delegate = delegate
            
            viewController?.present(scooterPlanViewController, animated: true, completion: completion)
        }
    }
    
    func showPauseViewController(_ viewController: UIViewController?, lastPause: Double, pauseSum: Double, delegate: MimoPauseViewControllerDelegate?) {
        if pauseViewController == nil {
            pauseViewController = MimoPauseViewController.loadFromNib()
        } else {
            pauseViewController?.lastPause = lastPause
            pauseViewController?.pauseSum = pauseSum
            pauseViewController?.delegate = delegate
            return
        }
        
        pauseViewController?.modalPresentationStyle = .overCurrentContext
        
        pauseViewController?.lastPause = lastPause
        pauseViewController?.pauseSum = pauseSum
        pauseViewController?.delegate = delegate
        
        viewController?.present(pauseViewController!, animated: true)
    }
    
    func showDebtViewController(_ viewController: UIViewController?, additional: Double?, wallets: [WalletDebts]?) {
        if let debtViewController: ShowDebtViewController = storyboard.instantiate() {
            debtViewController.modalPresentationStyle = .fullScreen
            debtViewController.updateUI(amount: additional ?? 0, wallets: wallets ?? [])
            
            viewController?.present(debtViewController, animated: true)
        }
    }
}
