//
//  UIApplication.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 04.05.23.
//

import Foundation

extension UIApplication {
    
    static func changeRootViewController(with viewController: UIViewController?) {
        let window = shared.windows.first
        window?.rootViewController = viewController
        window?.makeKeyAndVisible()
    }
}

extension UIApplication {
    var keyWindowInConnectedScenes: UIWindow? {
        return windows.first(where: { $0.isKeyWindow })
    }
}

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if self.presentedViewController == nil {
            return self
        }
        if let navigation = self.presentedViewController as? UINavigationController {
            return navigation.visibleViewController!.topMostViewController()
        }
        if let tab = self.presentedViewController as? UITabBarController {
            if let selectedTab = tab.selectedViewController {
                return selectedTab.topMostViewController()
            }
            return tab.topMostViewController()
        }
        return self.presentedViewController!.topMostViewController()
    }
}

extension UIApplication {
    func topMostViewController() -> UIViewController? {
        return keyWindowInConnectedScenes?.rootViewController?.topMostViewController()
    }
}

extension UIWindow {
    static var key: UIWindow? {
        return UIApplication.shared.windows.first { $0.isKeyWindow }
    }
}
