//
//  BaseCoordinator.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 09.03.25.
//

import SwiftUI

class BaseCoordinator {
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController? = nil) {
        self.navigationController = navigationController
    }
    
    func pushViewController(_ view: some View, isAnimated: Bool = true) {
        self.navigationController?.pushViewController(EVChargerHostingController(rootView: view), animated: isAnimated)
    }
    
    func popViewController(isAnimated: Bool = true) {
        self.navigationController?.popViewController(animated: isAnimated)
    }
    
    func popToRootViewController(isAnimated: Bool = true) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    func presentViewController(_ view: some View, presentationStyle: UIModalPresentationStyle = .automatic, isAnimated: Bool = true) {
        let viewController = EVChargerHostingController(rootView: view)
        viewController.modalPresentationStyle = presentationStyle
        self.navigationController?.present(viewController, animated: isAnimated)
    }
    
    func presentViewController(_ viewController: UIViewController, presentationStyle: UIModalPresentationStyle = .automatic, isAnimated: Bool = true) {
        viewController.modalPresentationStyle = presentationStyle
        self.navigationController?.present(viewController, animated: isAnimated)
    }
    
    func dissmiss(isAnimated: Bool = true) {
        self.navigationController?.dismiss(animated: isAnimated)
    }
}
