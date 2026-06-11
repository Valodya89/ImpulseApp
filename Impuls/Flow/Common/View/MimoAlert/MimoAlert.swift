//
//  MimoAlert.swift
//  Mimo
//
//  Created by Vardan on 29.05.21.
//

import UIKit

class MimoAlert: NSObject {
    
    private static var mimoAlert: MimoAlert?
    private static var mimoConnectionAlert: MimoAlert?
    
    let bgView = UIView()
    var tapGesture = UITapGestureRecognizer()
    var tapOnScreen: (()->())?
    
    /// Show alert view
    public static func show(_ type: AlertType, in viewController: UIViewController) {
        DispatchQueue.main.async {
            if mimoAlert == nil && mimoConnectionAlert == nil {
                let mimoAlert = MimoAlert()
                mimoAlert.commonInit(type, in: viewController)
                MimoAlert.mimoAlert = mimoAlert
            } else {
                let mimoAlert = MimoAlert()
                mimoAlert.commonInit(type, in: viewController)
                MimoAlert.mimoConnectionAlert = mimoAlert
            }
        }
    }
    
    /// Dismiss alert view
    public static func dismiss(_ viewController: UIViewController) {
        DispatchQueue.main.async {
            if let nc = viewController.navigationController {
                MimoAlert.mimoAlert?.enableNCGestures(true, nc)
            }
            MimoAlert.mimoAlert?.bgView.removeFromSuperview()
            MimoAlert.mimoAlert = nil
        }
    }
    
    /// Init MimoAlert view.
    private func commonInit(_ type: AlertType, in viewController: UIViewController) {
        
        switch type {
        case .errorNotification(let message):
            break
        case .important:
            createImportant(alertType: type, in: viewController)
        }
    }
    
    private func createImportant(alertType: AlertType, in viewController: UIViewController) {
        
        var parentVC = UIViewController()
        if let nc = viewController.navigationController {
            parentVC = nc
        } else {
            parentVC = viewController
        }
        
        bgView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        bgView.frame = parentVC.view.frame
        parentVC.view.addSubview(bgView)
        
        var width = Constant.Width.width250

        
        
        if case let .important(_, title, message, _) = alertType {
            if title == "" && message == "" {
                width = Constant.Width.width200
            }
        }
        
        
    
        
        let importantView = MimoImportantView.initFromNib() as MimoImportantView
        importantView.frame.size = CGSize(width: width, height: width)
        importantView.center = bgView.center
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideAlert))

        if case let .important(isSuccess, title, message, action) = alertType {
            importantView.commonInit(isSuccess: isSuccess, title: title, message: message)
            if let action = action {
                tapOnScreen = action
            }
        }
        
        importantView.layer.cornerRadius = 30
        importantView.layer.cornerCurve = .continuous
        
        bgView.addGestureRecognizer(tapGesture)
        bgView.addSubview(importantView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.hideAlert()
        }
    }
    
    
    /// Enable or disable navication controller gestures
    private func enableNCGestures(_ isEnable: Bool, _ nc: UINavigationController) {
        nc.interactivePopGestureRecognizer?.isEnabled = isEnable
        nc.barHideOnSwipeGestureRecognizer.isEnabled = isEnable
        nc.barHideOnTapGestureRecognizer.isEnabled = isEnable
    }

    @objc func hideAlert() {
        if MimoAlert.mimoConnectionAlert != nil {
            MimoAlert.mimoConnectionAlert?.bgView.removeFromSuperview()
            MimoAlert.mimoConnectionAlert = nil
        } else if MimoAlert.mimoAlert != nil {
            MimoAlert.mimoAlert?.bgView.removeFromSuperview()
            MimoAlert.mimoAlert = nil
        }
        
        if let tapOnScreen = tapOnScreen {
            tapOnScreen()
        }
    }
}


// MARK: - Mimo Alert Types
enum AlertType {
    case errorNotification(message: String)
    case important(isSuccess: Bool, title: String? = nil, message: String, action: (()->())? = nil)
}

// MARK: - UIViewController for LTActivityIndicator
extension UIViewController {
    /// Show activity indicator
    func showMimoAlert(_ type: AlertType) {
        MimoAlert.dismiss(self)
        MimoAlert.show(type, in: self)
    }
    
    /// Dismiss activity indicator
    func dismissMimoAlert() {
        MimoAlert.dismiss(self)
    }
}
