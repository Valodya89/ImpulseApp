//
//  LoginRouter.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 11.09.23.
//

import Foundation

class LoginRouter {
    public static let shared: LoginRouter = LoginRouter()
    
    private let storyboard = UIStoryboard(name: "Login", bundle: nil)
    
    init() {}
    
    func showStartViewController(_ viewController: UIViewController) {
        if let startViewController: MimoStartViewController = storyboard.instantiate() {
            let navigationController = UINavigationController(rootViewController: startViewController)
            navigationController.modalPresentationStyle = .fullScreen
            viewController.present(navigationController, animated: false)
        }
    }
}
