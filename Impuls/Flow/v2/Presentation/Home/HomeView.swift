//
//  HomeView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.09.23.
//

import SwiftUI

struct HomeView: UIViewControllerRepresentable {
    typealias UIViewControllerType = UITabBarController
    
    let homeViewModel: MimoHomeViewModel?
    
    func makeUIViewController(context: Context) -> UITabBarController {
        let tabBarController = HomeRouter.shared.homeViewController()!
        tabBarController.viewModel = homeViewModel
//        let homeViewController = ((tabBarController.viewControllers?.first as? UINavigationController)?.viewControllers.first as? MimoHomeViewController)
//        homeViewController?.viewModel = homeViewModel
        
        return tabBarController
    }
    
    func updateUIViewController(_ uiViewController: UITabBarController, context: Context) {
        
    }
}
