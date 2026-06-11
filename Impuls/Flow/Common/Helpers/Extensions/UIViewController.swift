//
//  UIViewController.swift
//  MimoBike
//
//  Created by Vardan on 12.05.21.
//

import UIKit

extension UIViewController {
    
    func showAlertMessage(_ title: String, meassage: String = "") {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: meassage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showAlertMessage(_ title: String, meassage: String = "", actionText: String, action: @escaping (() -> ())) {
//        DispatchQueue.main.async {
//            let alert = UIAlertController(title: title, message: meassage, preferredStyle: .alert)
//            alert.addAction(UIAlertAction(title: actionText, style: .default, handler: {_ in
//                action()
//            }))
//            self.present(alert, animated: true, completion: nil)
//        }
        
        let alert = MiAlertView()
        alert.addButton(actionText, action: action)
        alert.showError(title, subTitle: meassage, colorStyle: 0xFFEB3B, colorTextButton: 0x000000, animationStyle: .topToBottom)
    }
    
    func showAlertMessage(_ title: String, meassage: String = "", actionText: [String], action: @escaping ((String) -> ())) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: meassage, preferredStyle: .alert)
            
            actionText.forEach { (actionTitlte) in
                alert.addAction(UIAlertAction(title: actionTitlte, style: .default, handler: {_ in
                    action(actionTitlte)
                }))
            }
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showAlertMessageWithDismiss(_ title: String, meassage: String = "", actionText: [String], action: @escaping ((String) -> ())) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: meassage, preferredStyle: .alert)
            
            actionText.forEach { (actionTitlte) in
                alert.addAction(UIAlertAction(title: actionTitlte, style: .default, handler: {_ in
                    alert.dismiss(animated: true, completion: nil)
                    action(actionTitlte)
                }))
            }
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showErrorAlertMessage(_ message: String = "Something went wrong") {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: message, message: "", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    /// Set view controller as root
    func setRootViewController(_ vc: UIViewController?) {
        UIApplication.shared.windows.first?.rootViewController = vc
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    func goToNextVC(_ vc: UIViewController) {
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true, completion: nil)
    }
}

extension UIAlertController {
    static func showAction(title: String, message: String, actions: (String,UIAlertAction.Style, (UIAlertController)->())...) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        guard let window = UIApplication.topController() else { return }
        
        actions.forEach { action in
            let action = UIAlertAction(title: action.0, style: action.1, handler: {_ in
                action.2(alertController)
            })
            alertController.addAction(action)
        }
        window.present(alertController, animated: true, completion: nil)
    }
    
    static func showError(message: String) {
        let alert = MiAlertView()
//        _ = alert.addButton("OK".localized(), action: alert.hideView)
        _ = alert.showError("MOBILE__global_attention".localized().localized(), subTitle: message, closeButtonTitle: "OK".localized(), colorStyle: SCLAlertViewStyle.error.defaultColorInt, colorTextButton: 0x000000, animationStyle: .topToBottom)
        
//        UIAlertController.showAction(title: "Error".localized(), message: message, actions: ("OK".localized(), .default, {
//            action in
//            action.dismiss(animated: true, completion: nil)
//        }))
    }

    static func showLocationDeniedAlert() {
        UIAlertController.showAction(title: "MOBILE_global_warning".localized(), message: "SHARING_location_to_show_bikes_near_to_you".localized(), actions: ("MOBILE_profile_settings".localized(), .default, { controller in
            controller.dismiss(animated: true, completion: nil)
            AppDelegate.redirectSettings()
        }))
    }
}

extension AppDelegate {
    
    static func redirectSettings() {
    
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
}

extension UIViewController {
    
    func showErrorPopUp(message: String, service: MimoType) {
        let isReplenishable: Bool = (message == "SHARING_no_minimal_requirements") || (message == "MOBILE_map_minimum_requirments") || (message == "CHARGER_no_minimal_requirements")
        
        let vc: UIViewController
        switch service {
        case .scooter:
            vc = ScooterErrorViewController(message: message.localized(), isReplenishable: isReplenishable, onReplenish: { [weak self] in
                self?.openWallet()
            })
        case .bike:
            vc = BikeErrorViewController(message: message.localized(), isReplenishable: isReplenishable, onReplenish: { [weak self] in
                self?.openWallet()
            })
        case .charger:
            vc = ChargerErrorViewController(message: message.localized(), isReplenishable: isReplenishable, onReplenish: { [weak self] in
                self?.openWallet()
            })
        case .evCharger:
            vc = ChargerErrorViewController(message: message.localized(), isReplenishable: isReplenishable, onReplenish: { [weak self] in
                self?.openWallet()
            })
        }
        
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
}
