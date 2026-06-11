//
//  TransferToFriendViewController.swift
//  MimoBike
//
//  Created by Vardan on 29.05.21.
//

import UIKit

final class TransferToFriendViewController: BaseViewController, StoryboardInitializable {

    
    //MARK: - Outlets
    
    @IBOutlet weak var amountTextField: NumericTextField!
    @IBOutlet weak var balanceView: UIView!
    @IBOutlet weak var sendButton: ActionButton!
    @IBOutlet weak var userImageView: CircleImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var transferUserLabel: UILabel!
    @IBOutlet weak var transferUserImageView: CircleImageView!
    @IBOutlet weak var freeMinutesLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    let transferViewModel = TransferToFriendsViewModel()
    private var phoneNumber: String!
    private var accountBalance: Double!
    private var user: UserResult?
    private var userAvatarUrlStirng: String?
    private var transferUser: ContactsListModel?
    var debt: Double?
    
    // MARK: - Init -
    
    static func initiateFromStoryboard(_ phoneNumber: String, user: UserResult?, avatarUrl: String?, wallet: WalletModel?, transferUser: ContactsListModel?) -> TransferToFriendViewController {
        let trancferToFriendVC = TransferToFriendViewController.initFromStoryboard(name: Constant.Storyboards.transfer)
        trancferToFriendVC.user = user
        trancferToFriendVC.transferUser = transferUser
        trancferToFriendVC.userAvatarUrlStirng = avatarUrl
        trancferToFriendVC.phoneNumber = phoneNumber
        trancferToFriendVC.accountBalance = wallet?.balance ?? 0.0
        
        return trancferToFriendVC
    }
   
    
    //MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        configureUI()
        let tapGestureHideKeyboard =  UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        view.addGestureRecognizer(tapGestureHideKeyboard)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.post(name: NSNotification.Name("TransferToFriendViewController"), object: nil)
    }
    
    /// tap gesture recognizer selector function view end editing
    @objc private func hideKeyBoard () {
        view.endEditing(true)
    }
    
    
    //MARK: - Methods
    
    func setup() {
        userNameLabel.text = (user?.name ?? "") + " " + (user?.surname ?? "")
        transferUserLabel.text = (transferUser?.receiverName ?? "") + " " + (transferUser?.receiverSurname ?? "")
        freeMinutesLabel.text = user?.minutes.description ?? "0"
        amountLabel.text = accountBalance.description
        
        setNoneEmptyName(label: userNameLabel, noneEmptyText: transferViewModel.getUserPhoneNumber())
        setNoneEmptyName(label: transferUserLabel, noneEmptyText: phoneNumber)
        
        self.userImageView.setImage(user?.avatar?.getURL()?.absoluteString, defaultImage: #imageLiteral(resourceName: "ic_default_avatar"))
        self.transferUserImageView.setImage(transferUser?.receiverAvatar?.getURL()?.absoluteString, defaultImage: #imageLiteral(resourceName: "ic_default_avatar"))
    }
    
    func setNoneEmptyName(label: UILabel, noneEmptyText: String) {
        if label.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? false {
            label.text = noneEmptyText
        }
    }
    
    func configureUI() {
        sendButton.isActive = false
        amountTextField.numDelegate = self
        balanceView.layer.cornerRadius = Constant.CornerRadius.cornerRadius8
        if let debt = self.debt {
            amountTextField.numberText = debt
            sendButton.isActive = true
        }
    }
    
    
    //MARK: - Actions
    @IBAction func backButtonTapped(_ sender: UIButton) {
        if navigationController != nil {
            navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }

    @IBAction func sendMoneyToFriend(_ sender: SaveButton) {
        guard let amount = self.amountTextField.numberText else {
            UserManager.share.isOpenDebtScreen = true
            return self.showAlertMessage("Please fill valid amount".localized())
        }
        
//        if amount < 99.9 {
//            self.showAlertMessage("Error", meassage: "Min value to transfer is 99.9 AMD".localized())
//            
//            return
//        }
        if amount < 100 {
            UserManager.share.isOpenDebtScreen = true
            AlertController.show(title: "MOBILE_transfer_transfer_failed".localized(), message: "MOBILE_min_value_to_transfer".localized(), image: UIImage(named: "ic_cancel_trasnfer")!, in: self, dismissOnTouch: true)
            return
        }
        
        if amount > accountBalance {
            UserManager.share.isOpenDebtScreen = true
            AlertController.show(title: "MOBILE_transfer_transfer_failed".localized(), message: "MOBILE_transfer_not_enough_money".localized(), image: UIImage(named: "ic_cancel_trasnfer")!, in: self, dismissOnTouch: true)
            return
        }
        
        MILoader.show()
        self.transferViewModel.transferMoney(amount: amount, phoneNumber: phoneNumber) { [weak self]
            (result) in
            MILoader.hide()
            guard let self = self else { return }
            
            switch result {
            case .success:
                UserManager.share.isOpenDebtScreen = false
                NotificationCenter.default.post(name: Constant.Notifications.updateUserUI, object: nil)
                AlertController.show(title: nil, message: nil, image: #imageLiteral(resourceName: "ic_POP_UP_chekmark"), in: self, dismissOnTouch: true) { [weak self] in
                    self?.dismiss(animated: true, completion: nil)
                }
            case .failure(let err):
                UserManager.share.isOpenDebtScreen = true
                print(err.localizedDescription)
                AlertController.show(title: "MOBILE_transfer_transfer_failed".localized(), message: "MOBILE_transfer_not_enough_money".localized(), image: UIImage(named: "ic_cancel_trasnfer")!, in: self, dismissOnTouch: true)
            }
        }
    }
    
}


//MARK: - Extension UITextFieldDelegate

extension TransferToFriendViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        amountTextField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text,
              let textRange = Range(range, in: text) else {
            return true
        }
        
        let updatingString = text.replacingCharacters(in: textRange, with: string)
        
        self.sendButton.isActive = !updatingString.isEmpty
        
        return true
    }
}
