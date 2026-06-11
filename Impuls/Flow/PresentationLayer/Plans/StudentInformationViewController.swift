//
//  StudentInformationViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 09.06.21.
//

import UIKit
import CoreLocation

final class StudentInformationViewController: UIViewController, StoryboardInitializable, CLLocationManagerDelegate {
    
    @IBOutlet weak var phonePicker: MIPhonePicker!
    @IBOutlet weak var emailField: MITextFieldView!
    @IBOutlet weak var universityName: MITextFieldView!
    @IBOutlet weak var addmisionField: MITextFieldView!
    @IBOutlet weak var graduationDate: MITextFieldView!
    @IBOutlet weak var studentField: ImageField!
    @IBOutlet weak var selfStudField: ImageField!
    @IBOutlet weak var actionButton: ActionButton!

    var addmisionDatePicker: DatePickerManager!
    var graduationDatePicker: DatePickerManager!

    var selfiePhoto: UIImage?
    var studentPhoto: UIImage?
    
    let locationManager = CLLocationManager()
    let geoCoder = CLGeocoder()
    
    var tarrifStident: TariffModel!
    
    var model: MIPlanViewModel = MIPlanViewModel()
    
    var updateUI: (() -> ())?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MITextFieldView.animatable = false
        configUI()
        MITextFieldView.animatable = true
        
        locationManager.requestAlwaysAuthorization()
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.delegate = self
                self.locationManager.startMonitoringSignificantLocationChanges()
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.first else { return }
        
        geoCoder.reverseGeocodeLocation(currentLocation) { (placemarks, error) in
            guard let currentLocPlacemark = placemarks?.first else { return }
            print(currentLocPlacemark.country ?? "No country found")
            print(currentLocPlacemark.isoCountryCode ?? "No country code found")
            self.phonePicker.selectedCountryCode = currentLocPlacemark.isoCountryCode ?? "AM"
        }
    }
    
    private func configUI() {
        phonePicker.downArrouBtn.isHidden = true
        phonePicker.didUpdateStatus = {[weak self] bool in
            self?.updateActionButton()
        }
        
        emailField.didChangeFieldValue = {[weak self] text in
            self?.updateActionButton()

        }
        
        universityName.didChangeFieldValue = {[weak self] text in
            self?.updateActionButton()

        }
        
        studentField.delegate = self
        selfStudField.delegate = self
        self.configDatePickers()
        setUserInfo(from: UserManager.share.userResponse)
    }
    
    private func setUserInfo(from user: UserResponse?) {
        phonePicker.phoneNumber = StorageManager().fetch(key: .phoneNumber, type: String.self)
        emailField.fieldText = user?.email ?? ""
    }
    
    private func configDatePickers() {
        let graduationDatePicker = DatePickerManager(view: self.view, textField: graduationDate, dateFormat: "dd MMMM yyyy")
        let addmisionDatePicker = DatePickerManager(view: self.view, textField: addmisionField, dateFormat: "dd MMMM yyyy")
    
      
        graduationDate.didTappInView = {[weak self] in
            graduationDatePicker.showDatePicker(mode: .date)
            self?.graduationDate.startTyping()
            return false
        }
        graduationDate.prefetchUpdateCompletionWhenTextSetManually = true
        graduationDate.didChangeFieldValue = { _ in
        }
        addmisionField.prefetchUpdateCompletionWhenTextSetManually = true
        
      
        addmisionField.didChangeFieldValue = { _ in
        }
        addmisionField.didTappInView = {[weak self] in
            addmisionDatePicker.showDatePicker(mode: .date)
            self?.addmisionField.startTyping()
            return false
        }
        
        graduationDate.handleKeyboardActions = false
        addmisionField.handleKeyboardActions = false

        self.addmisionDatePicker = addmisionDatePicker
        self.graduationDatePicker = graduationDatePicker
    }
    
    private func updateActionButton() {
        actionButton.isActive = emailField.fieldText.isEmail && phonePicker.isValid && !universityName.fieldText.isEmpty && !graduationDate.fieldText.isEmpty && !graduationDate.fieldText.isEmpty && studentPhoto != nil && selfiePhoto != nil
    }
    
    @IBAction func activateTapped() {
        MILoader.show()
        model.activateTarrif(tarrifStident.id, phone: phonePicker.phoneNumber ?? "", email: emailField.fieldText, unversityName: universityName.fieldText, addmissionDate: self.addmisionDatePicker.datePickerView.date.toString(format: .custom("MM/dd/yyyy")), graduationDate: self.graduationDatePicker.datePickerView.date.toString(format: .custom("MM/dd/yyyy")), studentCardPhoto: studentPhoto!, selfiePhoto: selfiePhoto!) { [weak self] result in
            MILoader.hide()
            switch result {
            
            case .success(_):
                
                self?.updateUI?()
                UIAlertController.showAction(title: "MOBILE_global_success_title".localized(), message: "MOBILE_plans_alert_message".localized(), actions: ("OK",.default, {[weak self] controller in
                    controller.dismiss(animated: true, completion: nil)
                    self?.navigationController?.dismiss(animated: true, completion: nil)
                }))
            case .failure(let error):
            UIAlertController.showError(message: error.localizedDescription)
            }
        }
    }
}

extension StudentInformationViewController: ImageFieldDelegate {
    
    
    func didPickImage(imagePicker: ImageField, _ image: UIImage) {
        if imagePicker == studentField {
            studentPhoto = image
        } else {
            selfiePhoto = image
        }
        updateActionButton()
    }

    func didDeleteImage(imagePicker: ImageField) {
        if imagePicker == studentField {
            studentPhoto = nil
        } else {
            selfiePhoto = nil
        }
        updateActionButton()

    }


}

