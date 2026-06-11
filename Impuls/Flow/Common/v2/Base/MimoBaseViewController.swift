//
//  MimoBaseViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 01.06.23.
//

import UIKit

class MimoBaseViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    deinit {
        print("deinit - \(String(describing: self))")
    }
    
    func set(balance: WalletModel?, financialState: FinancialStateModel?) {
        let balanceView = self.navigationItem.titleView?.subviews.first(where: { $0 is BalanceTitleView }) as? BalanceTitleView
        balanceView?.set(balance: balance, financialState: financialState)
    }
    
    func registerTransferToFriendViewControllerObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(transferToFriendViewControllerDismisses),
                                               name: NSNotification.Name("TransferToFriendViewController"),
                                               object: nil)
    }
    
    @objc func transferToFriendViewControllerDismisses() {
        
    }
}

extension MimoBaseViewController {
    func showCameraAccessAlert() {
        let alertController = UIAlertController(title: "Error",
                                      message: "Camera access is denied",
                                      preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .default))
        alertController.addAction(UIAlertAction(title: "Settings", style: .cancel) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                    // Handle
                })
            }
        })

        present(alertController, animated: true)
    }
    
    func openAppOrSystemSettingsAlert(title: String, message: String) {
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
