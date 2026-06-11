//
//  OrderCardViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/5/21.
//

import UIKit
import PhoneNumberKit
import CoreLocation

final class OrderCardViewController: UIViewController, StoryboardInitializable, CLLocationManagerDelegate {

    let viewModel = OrderCardViewModel()
    
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var emailPhoneNumberField: MITextFieldView!
    @IBOutlet weak var phoneNumberTextField: MIPhonePicker!
    @IBOutlet weak var dateOfBirthTextField: MITextFieldView!
    @IBOutlet weak var addressTextField: MITextFieldView!
    @IBOutlet weak var scnTextFieldView: MITextFieldView!
    @IBOutlet weak var imageTextField: ImageField!
    @IBOutlet weak var orderButton: ActionButton!
    
    var passportImage: UIImage?
    let locationManager = CLLocationManager()
    let geoCoder = CLGeocoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.requestAlwaysAuthorization()
        
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.delegate = self
                self.locationManager.startMonitoringSignificantLocationChanges()
            }
        }
        
        self.setup()
        
        navBar.topItem?.title = "MOBILE_wallet_order_card".localized()
    }

    func setup() {
        self.emailPhoneNumberField.keyboardType = .emailAddress
        self.imageTextField.delegate = self
        
        self.emailPhoneNumberField.didChangeFieldValue = { [weak self] _ in
            self?.checkButtonVisibility()
        }
        
        self.phoneNumberTextField.didUpdateStatus = { [weak self] _ in
            self?.checkButtonVisibility()
        }
        
        self.dateOfBirthTextField.didChangeFieldValue = { [weak self] _ in
            self?.checkButtonVisibility()
        }
        
        self.addressTextField.didChangeFieldValue = { [weak self] _ in
            self?.checkButtonVisibility()
        }
        
        self.scnTextFieldView.didChangeFieldValue = { [weak self] _ in
            self?.checkButtonVisibility()
        }
        setupDatePickers()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.first else { return }
        
        geoCoder.reverseGeocodeLocation(currentLocation) { (placemarks, error) in
            guard let currentLocPlacemark = placemarks?.first else { return }
            print(currentLocPlacemark.country ?? "No country found")
            print(currentLocPlacemark.isoCountryCode ?? "No country code found")
            self.phoneNumberTextField.selectedCountryCode = currentLocPlacemark.isoCountryCode ?? "AM"
        }
    }
    
    private func setupDatePickers() {
        let datePicker = DatePickerManager(view: self.view, textField: dateOfBirthTextField, dateFormat: "dd MMMM yyyy")
        dateOfBirthTextField.handleKeyboardActions = false

        dateOfBirthTextField.didTappInView = {[weak self] in
            datePicker.showDatePicker(mode: .date)
            self?.dateOfBirthTextField.startTyping()
            return false
        }
    }
    
    func checkButtonVisibility() {
        var visible = true
        
        if self.emailPhoneNumberField.fieldText.isEmpty {
            visible = false
        }
        
        if self.phoneNumberTextField.phoneTextField.text?.isEmpty ?? true {
            visible = false
        }
        
        if self.dateOfBirthTextField.fieldText.isEmpty {
            visible = false
        }
        
        if self.addressTextField.fieldText.isEmpty {
            visible = false
        }
        
        if self.scnTextFieldView.fieldText.isEmpty {
            visible = false
        }
        
        if passportImage == nil {
            visible = false
        }
       
        self.orderButton.isActive = visible
    }
    
    
    // MARK: - IBActions -
    
    @IBAction func orderTapped(_ sender: UIButton) {
        guard phoneNumberTextField.isValid else {
            self.showAlertMessage("MOBILE__global_attention".localized(), meassage: "Phone number is not valid")
            
            return
        }
        MILoader.show()
        viewModel.orderCard(address: addressTextField.fieldText, birthday: dateOfBirthTextField.fieldText, email: emailPhoneNumberField.fieldText, passportImage: passportImage ?? #imageLiteral(resourceName: "ic_support"), scn: scnTextFieldView.fieldText, phone: phoneNumberTextField.phoneNumber ?? "") { [weak self] (result) in
            MILoader.hide()
            switch result {
            case .success:
                UIAlertController.showAction(title: "MOBILE_global_success".localized(), message: "Successfully ordered card".localized(), actions: ("OK", .default, { controller in
                    self?.navigationController?.popViewController(animated: true)
                }))
            
            case .failure(let error):
                UIAlertController.showError(message: error.errorDescription)
            }
        }
    }
    
    @IBAction private func closeAction() {
        dismiss(animated: true)
    }
}


// MARK: - ImageFieldDelegate -

extension OrderCardViewController: ImageFieldDelegate {
    func didPickImage(imagePicker: ImageField, _ image: UIImage) {
        passportImage = image
        
        checkButtonVisibility()

    }
    
    func didDeleteImage(imagePicker: ImageField) {
        passportImage = nil
        
        checkButtonVisibility()

    }

}
