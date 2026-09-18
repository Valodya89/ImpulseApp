//
//  MimoHomeTabBarController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 11.08.23.
//

import UIKit
import SwiftUI

class MimoHomeTabBarController: UITabBarController {
    
    var viewModel: MimoHomeViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appearance = UITabBarAppearance()
        appearance.backgroundColor = .appBackground
        
        setTabBarItemColors(appearance.stackedLayoutAppearance)
        setTabBarItemColors(appearance.inlineLayoutAppearance)
        setTabBarItemColors(appearance.compactInlineLayoutAppearance)
        
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        
        guard let homeViewController = storyboard?.instantiateViewController(withIdentifier: "MimoHomeNav") as? UINavigationController,
              let profileViewController: AccountViewController = UIStoryboard(name: Constant.Storyboards.account, bundle: nil).instantiate() else { return }
        (homeViewController.viewControllers.first as? MimoHomeViewController)?.viewModel = viewModel
        
        let profileVC = ProfileContainerView()
        let profileNavigationController = UINavigationController(rootViewController: profileVC)
        profileNavigationController.setNavigationBarHidden(true, animated: false)
        
        profileNavigationController.tabBarItem.image = UIImage(named: "tab_profile")
        profileNavigationController.tabBarItem.selectedImage = UIImage(named: "tab_profile_selected")
        profileNavigationController.tabBarItem.title = "MOBILE_global_profile".localized()
        
        profileViewController.view.backgroundColor = .appSecondaryBackground
        
        viewControllers = [homeViewController, profileNavigationController]
        
        homeViewController.tabBarItem.image = UIImage(named: "tab_home")
        homeViewController.tabBarItem.selectedImage = UIImage(named: "tab_home_selected")
        homeViewController.tabBarItem.title = "MOBILE_global_home".localized()
    }
    
    private func setTabBarItemColors(_ itemAppearance: UITabBarItemAppearance) {
        itemAppearance.normal.iconColor = UIColor.appLabel.withAlphaComponent(0.8)
        itemAppearance.normal.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.appLabel.withAlphaComponent(0.8)]
         
        itemAppearance.selected.iconColor = .mimoDarkGray
        itemAppearance.selected.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.mimoDarkGray]
    }

}
