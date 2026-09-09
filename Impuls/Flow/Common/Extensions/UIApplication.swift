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

    /// Dismisses the keyboard whichever view owns the first responder. `endEditing`
    /// on a view only reaches responders inside that view, which is not enough when
    /// the window's root view controller is swapped out from under the text field -
    /// the field is detached without resigning and the keyboard stays up.
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
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
