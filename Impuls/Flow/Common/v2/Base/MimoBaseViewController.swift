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
    /// The camera was refused: Impulse can only read a station's QR code with
    /// it, so the only way forward is iOS Settings. Every text comes from the
    /// locale service with an English fallback; a bare key never reaches the
    /// screen.
    func showCameraAccessAlert() {
        let alertController = UIAlertController(
            title: "MOBILE__global_camera".localized(fallback: "Camera"),
            message: "MOBILE__global_camera_access".localized(fallback: "To scan a station's QR code, we need access to your phone's camera."),
            preferredStyle: .alert
        )
        alertController.addAction(UIAlertAction(title: "MOBILE_global_cancel".localized(fallback: "Cancel"), style: .cancel))
        alertController.addAction(UIAlertAction(title: "MOBILE_profile_settings".localized(fallback: "Settings"), style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        })

        present(alertController, animated: true)
    }
    
    func openAppOrSystemSettingsAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "MOBILE_profile_settings".localized(fallback: "Settings"), style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "MOBILE_global_cancel".localized(fallback: "Cancel"), style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
