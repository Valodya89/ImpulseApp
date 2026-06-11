//
//  SessionExpiredAlert.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/13/21.
//

import Foundation

final class SessionExpiredAlert {
        
    static func showAlert() {
        UIApplication.topController()?.showAlertMessage("Session Expired", meassage: "Your current session expired, please login again.", actionText: ["Ok"], action: { _ in
            AccountViewModel().logout(complation: {
                
//                let splashVC = SplashViewController.initFromStoryboard(name: Constant.Storyboards.splash)
//                UIApplication.topController()?.setRootViewController(splashVC)
                BaseRouter.shared.showSplashView()
            })
        })
    }
}
