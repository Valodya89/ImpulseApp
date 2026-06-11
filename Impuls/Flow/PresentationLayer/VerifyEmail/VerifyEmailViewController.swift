//
//  VerifyEmailViewController.swift
//  MimoBike
//
//  Created by Dose on 6/3/21.
//

import UIKit

protocol VerifyEmailViewControllerDelegate: AnyObject {
    func didVerify()
}

final class VerifyEmailViewController: UIViewController, StoryboardInitializable {
    
    @IBOutlet weak var emailLabel: UILabel!
    
    @IBOutlet weak var almostThereLabel: UILocalizedLabel!
    weak var delegate: VerifyEmailViewControllerDelegate?
    
    var currentEmail: String!
    var viewModel = VerifyEmailViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configUI()
    }
    
    private func configUI() {
        NotificationCenter.default.addObserver(self, selector: #selector(verified), name: Constant.Notifications.accountVerified, object: nil)
        config()
        
        
        almostThereLabel.text = "MOBILE_verify_sent_email".localized().replacingOccurrences(of: "[email]", with: "")
        
        emailLabel.text = currentEmail
        
        viewModel.sendEmailCode { _ in
            
        }
    }
    
    private func config() {
        
    }
    
    @objc func verified() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func verifyTapped(_ sender: UIButton) {
        
        viewModel.sendEmailCode { _ in
            
        }
    }
    
    @IBAction func editEmailTapped(_ sender: UIButton) {
        let viewController = EditEmailAdressViewController.initFromStoryboard(name: "VerifyEmail")
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }
}

extension VerifyEmailViewController: EditEmailAdressViewControllerDelegate {
    func didChangeEmail(new email: String) {
        emailLabel.text = email
    }
}
