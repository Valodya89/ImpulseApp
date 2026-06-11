//
//  CompletePurchaseViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/8/21.
//

import UIKit

enum PurchaseStatus {
    case normal
    case influenceBallance
}

final class CompletePurchaseViewController: UIViewController, StoryboardInitializable {
    
    @IBOutlet weak var activateButton: ActionButton!
    @IBOutlet weak var rideDescriptionLabel: UILabel!
    @IBOutlet weak var contentIcon: UIImageView!
    @IBOutlet weak var popularView: CircleView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var feeLabel: UILabel!
    
    var purchaseStatus: PurchaseStatus = .normal
    
    let viewModel = CompletePurchaseViewModel()
    var package: PackageModel?
    
    var updateUI: (() -> ())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.setupUI()
    }
    
    private func setupUI() {
        if let package = package {
            self.titleLabel.text = package.localizedName
            self.popularView.isHidden = !package.popular
            self.descriptionLabel.text = package.description
            self.feeLabel.text = package.price.description + " " + "MOBILE_global_total_currency".localized()
            self.timeLabel.text = "MOBILE__label_fee".localized().replacingOccurrences(of: "[name]", with: package.localizedName)
            
            self.contentIcon.setImage(package.logo.imageURL?.absoluteString, defaultImage: UIImage(named: "ic_calendar_package")!)
            self.activateButton.isActive = true
        }
        
        self.viewModel.getWallet { [weak self] (result) in
            switch result {
            case .success(let wallet):
                guard let packagePrice = self?.package?.price else {
                    return
                }
                if wallet.balance >= packagePrice {
                    self?.activateButton.setTitle("MOBILE_plans_rates_packages_yearly_activate_button".localized(), for: .normal)
                    self?.purchaseStatus = .normal
                } else {
                    self?.activateButton.setTitle("MOBILE_plans_fill_the_balance".localized(), for: .normal)
                    self?.purchaseStatus = .influenceBallance
                    
                }
            case .failure(let error):
                UIAlertController.showError(message: error.localizedDescription)
            }
        }
    }
    
    @IBAction func activate(_ sender: UIButton) {
        switch self.purchaseStatus {
        case .influenceBallance:
            self.fillBalance()
        case .normal:
            guard let packageID = package?.id else {
                return
            }
            self.activatePackage(packageID: packageID)
        }
    }
    
    private func fillBalance() {
        let walletController = WalletViewController.initFromStoryboard(name: "Wallet")
        
        present(UINavigationController(rootViewController: walletController), animated: true, completion: nil)
    }
    
    private func activatePackage(packageID: String) {
        MILoader.show()
        viewModel.activatePackage(packageID: packageID) { [weak self] (result) in
            MILoader.hide()

            switch result {
            case .success:
                self?.showAlertMessage("MOBILE_global_success".localized(), meassage: "Package activated successfully", actionText: "Ok", action: { [weak self] in
                    self?.updateUI?()
                    self?.viewModel.getUser(completion: { _ in
                        self?.navigationController?.dismiss(animated: true, completion: nil)
                    })
                })
            case .failure(let error):
                self?.showAlertMessage("MOBILE__global_attention".localized(), meassage: error.localizedDescription)
            }
        }
    }
}
