//
//  EditEmailAdressViewController.swift
//  MimoBike
//
//  Created by Dose on 6/4/21.
//

import UIKit

protocol EditEmailAdressViewControllerDelegate: AnyObject {
    func didChangeEmail(new email: String)
}

final class EditEmailAdressViewController: UIViewController, StoryboardInitializable {
    
    @IBOutlet weak var verifyButton: ActionButton!
    @IBOutlet weak var emailTextField: MITextFieldView!
    @IBOutlet weak var buttonBottomConstraint: NSLayoutConstraint!
    
    var viewModel = VerifyEmailViewModel()
    
    weak var delegate: EditEmailAdressViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear(_:)), name: UIApplication.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDissapear(_:)), name: UIApplication.keyboardWillHideNotification, object: nil)
        emailTextField.didChangeFieldValue = {[weak self] value in
            self?.verifyButton.isActive = value.isEmail 
        }
        
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillAppear(_ notification: Notification) {
        
        let userInfo = notification.userInfo!
        let keyboardFrame: CGRect = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        buttonBottomConstraint.constant = keyboardFrame.height
        UIView.animate(withDuration: 0.3) {[weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillDissapear(_ notification: Notification) {
        buttonBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {[weak self] in
            self?.view.layoutIfNeeded()
        }
    }
    
    @IBAction func verifyEmailTapped(_ sender: Any) {
        emailTextField.endTyping()
        MILoader.show()
        UserManager.share.updateEmail(new: emailTextField.fieldText) {[weak self] result in
            
            switch result {
            case .success(_):
                self?.viewModel.sendEmailCode {[weak self] _ in
                    guard let self = self else { return }
                    MILoader.hide()
                    self.delegate?.didChangeEmail(new: self.emailTextField.fieldText)
                    self.navigationController?.popViewController(animated: true)
                }
            case .failure(let error):
                MILoader.show(message: error.localizedDescription, animated: true, blocking: false, touchable: true)
            }
        }
    }
    
    @IBAction func tappInView() {
        view.endEditing(true)
    }
}
