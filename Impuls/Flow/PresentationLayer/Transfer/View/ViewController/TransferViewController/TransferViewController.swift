//
//  TransferViewController.swift
//  MimoBike
//
//  Created by Vardan on 28.05.21.
//

import UIKit
import ContactsUI
import Foundation
import CoreLocation

final class TransferViewController: BaseViewController, StoryboardInitializable, CLLocationManagerDelegate {

    
    // MARK: - Outlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var phoneNumberTextView: MIPhonePicker! {
        didSet {
            phoneNumberTextView.phoneTextField.keyboardType = .phonePad
        }
    }
    @IBOutlet weak var findButton: ActionButton!
    @IBOutlet weak var bottomInsetViewBottomConstraint: NSLayoutConstraint!
    
    
    // MARK: - Life cycles

    var contactsList = [ContactsListModel]()
    
    var viewModel = TransferViewModel()
    let locationManager = CLLocationManager()
    let geoCoder = CLGeocoder()
    
    var user: UserResult?
    var avatarUrl: String?
    var wallet: WalletModel?
    
    
    // MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            self.locationManager.requestAlwaysAuthorization()
            DispatchQueue.global().async {
                if CLLocationManager.locationServicesEnabled() {
                    self.locationManager.delegate = self
                    self.locationManager.startMonitoringSignificantLocationChanges()
                }
            }
        }
        
        setup()
        registerKeyboardNotifications()
        registerCells()
        configureDelegates()
        fetchList()
//        let tapGestureHideKeyboard =  UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
//        view.addGestureRecognizer(tapGestureHideKeyboard)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.first else { return }
        
        geoCoder.reverseGeocodeLocation(currentLocation) { (placemarks, error) in
            guard let currentLocPlacemark = placemarks?.first else { return }
            print(currentLocPlacemark.country ?? "No country found")
            print(currentLocPlacemark.isoCountryCode ?? "No country code found")
            self.phoneNumberTextView.selectedCountryCode = currentLocPlacemark.isoCountryCode ?? "AM"
        }
    }
    
    /// tap gesture recognizer selector function view end editing
    @objc private func hideKeyBoard () {
        view.endEditing(true)
    }
    
    // MARK: - Methods
    
    func setup() {
        phoneNumberTextView.didUpdateStatus = { [weak self] _ in
            guard let unwrapSelf = self else {
                return
            }         
            if unwrapSelf.phoneNumberTextView.phoneTextField.text?.isEmpty ?? true {
                self?.findButton.isActive = false
            } else {
                self?.findButton.isActive = true
            }
        }
    }
    
    func fetchList() {
        viewModel.fetchContacts { [weak self] (result) in
            switch result {
            case .success(let contacts):
                self?.contactsList = contacts
//                
//                if contacts.isEmpty {
//                    self?.showAlertMessage("Info", meassage: "You do not have any contacts, you can add contacts here")
//                }
                
                self?.tableView.reloadData()
            case .failure:
                self?.showAlertMessage("MOBILE__global_attention".localized(), meassage: "Failed to fetch list")
            }
        }
    }
    
    func configureUI() {
        tableView.contentInset.top = 59
    }
    
    func configureDelegates() {
        tableView.delegate = self
        tableView.dataSource = self
    }

    func registerCells() {
        tableView.register(UINib(nibName: ContactsTableViewCell.reuseIdentifier(), bundle: nil), forCellReuseIdentifier: ContactsTableViewCell.reuseIdentifier())
    }
    
    
    func goToTransferToFriendVC(_ phoneNumber: String, _ transferUser: ContactsListModel?) {
        let trancferToFriendVC = TransferToFriendViewController.initiateFromStoryboard(phoneNumber, user: user, avatarUrl: avatarUrl, wallet: wallet, transferUser: transferUser)
        navigationController?.pushViewController(trancferToFriendVC, animated: true)
    }
    
    
    // MARK: - Actions
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func findFromContactsTapped(_ sender: UIButton) {
        // 1
        let contactPicker = CNContactPickerViewController()
        contactPicker.delegate = self
        // 2
        contactPicker.predicateForEnablingContact = NSPredicate(format: "phoneNumber.@count > 1")

        present(contactPicker, animated: true)
    }
    
    @IBAction func findButtonTapped(_ sender: SaveButton) {
        if !self.phoneNumberTextView.isValid {
            self.showAlertMessage("MOBILE__global_attention".localized(), meassage: "Please enter valid phone number")
            
            return
        }
        
        guard let phoneNumber = self.phoneNumberTextView.phoneNumber else {
            self.showAlertMessage("MOBILE__global_attention".localized(), meassage: "Phone number is empty")
            
            return
        }
        
        if phoneNumber.isEmpty {
            self.showAlertMessage("MOBILE__global_attention".localized(), meassage: "Phone number is empty")
            
            return
        }
        
        phoneNumberTextView.phoneTextField.resignFirstResponder()

        
        MILoader.show()
        self.viewModel.isMimoUser(phoneNumber: phoneNumber, completed: { [weak self] (mimoCheckStatus) in
            MILoader.hide()
            
            switch mimoCheckStatus {
            case .isMimoUser(let user):
                self?.goToTransferToFriendVC(phoneNumber, user)
            case .noSuchUser:
                self?.inviteUser(phoneNumber)
            case .error:
                self?.showErrorAlertMessage("Failed to check contact user")
            }
        })
    }
    
    
    private func inviteUser(_ phoneNumber: String) {
        let inviteLocalized = "MOBILE_transfer_invite".localized()
        
        self.showAlertMessage("\(inviteLocalized) \(phoneNumber)", meassage: "MOBILE_transfer_invite_or_not".localized(), actionText: ["MOBILE_global_cancel".localized(), inviteLocalized]) { [weak self] (action) in
            if action == inviteLocalized {
                self?.viewModel.inviteUser(phoneNumber: phoneNumber) { result in
                    switch result {
                    case .success:
                        MiAlertView().showSuccess("MOBILE_verify_successful_alert".localized())
                    case .failure(let error):
                        UIAlertController.showError(message: MimoError.init(error: error).message)
                    }
                }
            }
        }
    }
}

// MARK: - Extension: UI

extension TransferViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactsList.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = contactsList[indexPath.row]
        VibrateManager.vibrate()
        guard let phoneNumber = contact.receiverId else {
            return self.showAlertMessage("MOBILE__global_attention".localized(), meassage: "User does not have phone number")
        }
        
        goToTransferToFriendVC(phoneNumber, contact)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let contact = contactsList[indexPath.row]
        
        let cell = ContactsTableViewCell.reuseIdentifire(from: tableView, indexPath: indexPath)
        cell.profileImageView.setImage(contact.receiverAvatar?.getURL()?.absoluteString, defaultImage: #imageLiteral(resourceName: "ic_user_profile"))
        cell.profileName.text = contact.getName()
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 58
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
}


//MARK: - CNContactPickerDelegate

extension TransferViewController: CNContactPickerDelegate {
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        let phoneNumbers = self.fetchFirstContactNumbers(contact: contact)
        VibrateManager.vibrate()
        self.getNeededPhoneNumber(phoneNumbers: phoneNumbers) { [weak self] (phoneNumber) in
            MILoader.show()
            
            var phoneNumberMutated = self?.formatPhoneNumber(phoneNumber) ?? phoneNumber
            phoneNumberMutated.removeAll(where: { $0.isWhitespace })
            
            
            self?.viewModel.isMimoUser(phoneNumber: phoneNumberMutated, completed: { (mimoCheckStatus) in
                MILoader.hide()
                
                switch mimoCheckStatus {
                case .isMimoUser(let user):
                    self?.goToTransferToFriendVC(phoneNumberMutated, user)
                case .noSuchUser:
                    self?.inviteUser(phoneNumber)
                case .error:
                    self?.showErrorAlertMessage("Failed to check contact user")
                }
            })

        }
        
        print("contactList.count === \(contactsList.count)")
    }
    
    func getNeededPhoneNumber(phoneNumbers: [String], phoneNumber: @escaping (String) -> ()) {
        if phoneNumbers.count == 1 { return phoneNumber(phoneNumbers[0]) }
        
        self.showActionSheet(texts: phoneNumbers, completion: phoneNumber)
    }
    
    func formatPhoneNumber(_ number: String) -> String {
        var _number = number
        if _number.starts(with: "0") {
            _number.removeFirst()
            _number = "+374\(_number)"
        }
        
        if _number.hasPrefix("374") {
            _number = "+\(_number)"
        }
        
        return _number
    }
    
    func showActionSheet(texts: [String], completion: @escaping (String) -> ()) {
        
        var alertStyle = UIAlertController.Style.actionSheet
        if (UIDevice.current.userInterfaceIdiom == .pad) {
          alertStyle = UIAlertController.Style.alert
        }

        let alertController = UIAlertController(title: "Select", message: "Select phone number", preferredStyle: alertStyle)

        texts.forEach { (text) in
            let alertAction = UIAlertAction(title: text, style: .default) { _ in
                completion(text)
            }
            
            alertController.addAction(alertAction)
        }
        
        alertController.view.tintColor = .mimoBlackWith075alpha
        alertController.addAction(UIAlertAction(title: "MOBILE_global_cancel".localized(), style: .cancel, handler: nil))

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.present(alertController, animated: true)
        }
    }
    
    func fetchFirstContactNumbers(contact: CNContact) -> [String] {
        return contact.phoneNumbers.map { $0.value.stringValue }
    }
}
