//
//  RatesRouter.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 26.11.23.
//

import Foundation

class RatesRouter {
    
    static let shared = RatesRouter()
    
    private let storyboard = UIStoryboard(name: "Rates", bundle: nil)
    
    private init() {}
    
    func showRatesViewController(_ viewController: UIViewController, supportedMimoTypes: [MimoType], mimoType: MimoType = .scooter) {
        if let ratesViewController: MimoRatesViewController = storyboard.instantiate() {
            ratesViewController.viewModel = MimoRatesViewModel(worker: Resolver.resolve(), supportedTypes: supportedMimoTypes, mimoType: mimoType)
            viewController.present(ratesViewController, animated: true)
        }
    }
}
