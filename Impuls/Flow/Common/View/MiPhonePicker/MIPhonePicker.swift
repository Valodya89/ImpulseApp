//
//  MIPhonePicker.swift
//  MimoBike
//
//  Created by Dose on 6/8/21.
//

import UIKit
import SwiftMaskTextfield
import PhoneNumberKit
import libPhoneNumber_iOS

final class MIPhonePicker: UIView {
    
    @IBOutlet weak var downArrouBtn: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var phoneTextField: SwiftMaskTextfield!
    @IBOutlet weak var countryCodeLabel: UILabel!
    @IBOutlet weak var countryFlagImageView: UIImageView!
    
    private let applicationSettings: ApplicationSettings = .shared
    private var selectedCountry: CountryCodeResponse?
    private var validFormPattern: Int = 11
    var format: NBAsYouTypeFormatter?
    
    var selectedCountryCode: String = "RU" {
        didSet {
            commonInit()
        }
    }
    var fixDefaultRegion: Bool = false
    var didUpdateStatus: ((Bool) -> ())?
    let phoneNumberKit = PhoneNumberKit()
    var phoneNumber: String? {
        get {
            return "\(selectedCountry?.dial_code ?? "NULL") \(phoneTextField.text ?? "NULL")".replacingOccurrences(of: "-", with: "").replacingOccurrences(of: " ", with: "")
        } set {
            guard let newValue = newValue else {
                return
            }
            guard !newValue.isEmpty else {
                phoneTextField.text = ""
                return
            }

            guard let phoneNumber = try? phoneNumberKit.parse(newValue, ignoreType: true) else { return }
            
            countryCodeLabel.text = "+" + String(phoneNumber.countryCode)
            phoneTextField.text = String(phoneNumber.nationalNumber)
        }
    }
    
    var isValid: Bool {
        guard let code = countryCodeLabel.text, let number = phoneTextField.text else { return false }
        return phoneNumberKit.isValidPhoneNumber(code + number)//  phoneTextField.text?.count == validFormPattern
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
        phoneTextField.keyboardType = .numberPad
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 8
        layer.borderWidth = 0.5
        layer.borderColor = UIColor.black.cgColor
        clipsToBounds = true
    }
    
    private func getISOCodes() {
        print(Locale.isoRegionCodes)
    }
    
    private func commonInit() {
        loadFromNib()
        selectedCountry = applicationSettings.countryCodes.first(where: { $0.code == selectedCountryCode })
        configUI()
        phoneTextField.delegate = self
    }
    
    private func configUI() {
        guard let selectedCountry = selectedCountry else { return }
        
        format = NBAsYouTypeFormatter(regionCode: selectedCountry.code)
        phoneTextField.placeholder = format?.inputString("990000000000000")
        countryCodeLabel.text = selectedCountry.dial_code
        countryFlagImageView.image = UIImage(named: selectedCountry.flag ?? "")
        
        let countryCode = selectedCountry.code ?? ""
        let dialCode = selectedCountry.dial_code ?? ""
        var exampleNumber = phoneNumberKit.getFormattedExampleNumber(forCountry: countryCode, ofType: .mobile, withFormat: .international)
        exampleNumber = exampleNumber?.replacingOccurrences(of: "\(dialCode)", with: "").trimmingCharacters(in: .whitespaces)
        let maskNumber = exampleNumber?.replacingOccurrences(of: "[0-9]", with: "#", options: .regularExpression)
        
        phoneTextField.formatPattern = maskNumber ?? ""
        phoneTextField.placeholder = exampleNumber
        phoneTextField.text = ""
        phoneTextField.prefix = ""
        validFormPattern = exampleNumber?.count ?? 15
        
        didUpdateStatus?(phoneTextField.text?.count == validFormPattern)
    }

 
    @IBAction func openPhonePicker() {
        guard !fixDefaultRegion else { return }
        let countryCodeVC = CountryCodeViewController.configure(selectedID: selectedCountry?.id, delegate: self)
        UIApplication.topController()?.present(countryCodeVC, animated: true, completion: nil)
    }
    
    @IBAction func didChangeField() {
        didUpdateStatus?(phoneTextField.text?.count == validFormPattern)
    }
    
    @IBAction func touchTextField() {
        phoneTextField.becomeFirstResponder()
    }
}

extension MIPhonePicker: CountryCodeViewControllerDelegate {
    func didSelectCountry(_ country: CountryCodeResponse) {
        VibrateManager.vibrate()
        selectedCountry = country
        configUI()
    }
}



extension MIPhonePicker: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "" {
            return true
        }
        let fullText = textField.text! + string
//        phoneTextField.text = format?.inputString(fullText)
        return fullText.count <= validFormPattern

    }
}


extension UIApplication {
    static func topController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first

        if var topController = keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }

        return nil
    }
}
