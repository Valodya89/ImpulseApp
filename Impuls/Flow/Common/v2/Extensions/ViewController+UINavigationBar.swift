//
//  ViewController+UINavigationBar.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 02.07.23.
//

import UIKit
import SwiftUI

extension UIViewController {
    
    func makeNavigationBarWithBackButton(rightButtons: [NavigationRightButton] = [.notification], productType: MimoProductType) {
        makeDefaultNavigationBar(productType: productType)
        add(rightButtons: rightButtons)
        
        let configuration = UIImage.SymbolConfiguration(weight: .medium)
        let backImage = UIImage(systemName: "chevron.left", withConfiguration: configuration)?.withTintColor(.black)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(backAction))
    }
    
    func makeNavigationBarWithProfileView(rightButtons: [NavigationRightButton] = [.notification]) {
        makeDefaultNavigationBar()
        add(rightButtons: rightButtons)
        
        let profileView = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 36))
//        profileView.backgroundColor = #colorLiteral(red: 0.8894182444, green: 0.8894182444, blue: 0.8894182444, alpha: 1)
//        profileView.cornerRadius = 18
//        let userImage = UIImage(systemName: "person")
//        let userImageView = UIImageView(image: userImage)
//        userImageView.tintColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
//        userImageView.frame = CGRect(x: 7, y: 8, width: 22, height: 20)
//        let profileButton = UIButton(type: .custom)
//        profileButton.frame = profileView.bounds
//        profileView.addSubview(profileButton)
//        profileView.addSubview(userImageView)
//        profileButton.addTarget(self, action: #selector(profileAction), for: .touchUpInside)
//
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: profileView)
    }
    
    private func makeDefaultNavigationBar(productType: MimoProductType? = nil) {
        let backgroundView = UIView()
        backgroundView.backgroundColor = .white.withAlphaComponent(0.85)
        backgroundView.frame = (navigationController?.navigationBar.bounds.insetBy(dx: 0, dy: -30).offsetBy(dx: 0, dy: -30))!
        navigationController?.navigationBar.isTranslucent = true
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.addSubview(backgroundView)
        backgroundView.isUserInteractionEnabled = false
        backgroundView.layer.zPosition = -1
        
        let containerSize = navigationController?.navigationBar.frame.size ?? .zero
        let logoSize = CGSize(width: 150, height: 50)
        let containerView = UIView(frame: CGRect(origin: .zero, size: containerSize))
        let balanceView = BalanceTitleView(frame: CGRect(x: 0, y: 0, width: logoSize.width, height: logoSize.height))
        balanceView.action = { [weak self] in
            guard let self else { return }
            
            self.openWallet(productType: productType)
        }
        balanceView.tag = 999
        balanceView.center = CGPoint(x: containerSize.width/2, y: containerSize.height/2)
        balanceView.translatesAutoresizingMaskIntoConstraints = true
        balanceView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        containerView.addSubview(balanceView)
        
        navigationItem.titleView = containerView
    }
    
    private func add(rightButtons: [NavigationRightButton] = [.notification]) {
        var rightBarButtonItems: [UIBarButtonItem] = []
        rightButtons.forEach { navButton in
            switch navButton {
            case .notification:
                rightBarButtonItems.append(UIBarButtonItem(image: navButton.icon, style: .plain, target: self, action: #selector(notificationAction)))
            }
        }
        navigationItem.rightBarButtonItems = rightBarButtonItems
    }
    
    func openWallet(productType: MimoProductType? = nil) {
//        if let walletVC: WalletNavigationController = UIStoryboard(name: Constant.Storyboards.wallet, bundle: nil).instantiate() {
//            self.present(walletVC, animated: true, completion: nil)
//        }
        
        let walletView = WalletView(viewModel: MimoWalletViewModel(worker: Resolver.resolve(), productType: productType))
        let hostingController = UIHostingController(rootView: walletView)
        self.present(hostingController, animated: true)
    }
    
    @objc private func dissmisWallet() {
        dismiss(animated: true)
    }
}

extension UIViewController {
    enum NavigationRightButton {
        case notification
        
        var icon: UIImage? {
            switch self {
            case .notification:
                return UIImage(named: "ic_notification")
            }
        }
    }
}

extension UIViewController {
    
    @objc func notificationAction() {
        let notListVC = NotificationListViewController.initFromStoryboard(name: Constant.Storyboards.home)
        let navVC = UINavigationController(rootViewController: notListVC)
        navVC.modalPresentationStyle = .pageSheet
        present(navVC, animated: true)
    }
    
    @objc func backAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func profileAction() {
        let accountVC = AccountViewController.initFromStoryboard(name: Constant.Storyboards.account)
        let nc = UINavigationController(rootViewController: accountVC)
        present(nc, animated: true, completion: nil)
    }
}
