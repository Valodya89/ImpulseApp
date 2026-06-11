//
//  ScanRouter.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 01.06.23.
//

import Foundation

class ScanRouter {
    
    static let shared = ScanRouter()
    
    private var storyboard: UIStoryboard = UIStoryboard(name: "Scan", bundle: nil)
    
    func showQrScanViewController(_ viewController: UIViewController, type: MimoType? = nil, delegate: MimoScanQrViewControllerDelegate?) {
        if let qrScanVC: MimoScanQrViewController = storyboard.instantiate() {
            qrScanVC.delegate = delegate
            qrScanVC.mimoType = type
            
            let navigationController = UINavigationController(rootViewController: qrScanVC)
            viewController.present(navigationController, animated: true)
        }
    }
}
