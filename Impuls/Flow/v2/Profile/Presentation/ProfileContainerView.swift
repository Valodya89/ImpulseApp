//
//  ProfileContainerView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 15.04.24.
//

import UIKit
import SwiftUI

final class ProfileContainerView: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let profileViewModel = ProfileViewModel(
            worker: Resolver.resolve(),
            messageService: Resolver.resolve()
        )
        
        let profileView = ProfileView(
            viewModel: profileViewModel,
            navigationController: navigationController!
        )
        
        let profileVC = UIHostingController(rootView: profileView)
        profileVC.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(profileVC.view)
        addChild(profileVC)
        
        NSLayoutConstraint.activate([
            profileVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            profileVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            profileVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            profileVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let scanButton = UIButton()
        scanButton.setImage("tab_scan".image, for: .normal)
        scanButton.backgroundColor = .mimoYellow500
        scanButton.cornerRadius = 30
        scanButton.addAction(UIAction(handler: { _ in
            ScanRouter.shared.showQrScanViewController(self, delegate: self)
        }), for: .touchUpInside)
        
        view.addSubview(scanButton)
        scanButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scanButton.widthAnchor.constraint(equalToConstant: 60),
            scanButton.heightAnchor.constraint(equalToConstant: 60),
            scanButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 30)
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Resolver.optional(MessageServiceProtocol.self)?.publish(.refreshUser)
    }
}

extension ProfileContainerView: MimoScanQrViewControllerDelegate {
    
    func didFinishScan(with value: String, type: MimoType) {
        switch type {
        case .scooter:
            ScooterRouter.shared.showScooterViewController(navigationController, scannedQR: value)
        case .bike:
            BikeRouter.shared.showBikeViewController(navigationController, scannedQR: value)
        case .charger:
            ChargerRouter.shared.showChargerViewController(navigationController, scannedQR: value)
        case .evCharger:
            break
        }
    }
}
