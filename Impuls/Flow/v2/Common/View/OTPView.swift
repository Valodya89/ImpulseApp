//
//  OTPView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 26.09.23.
//

import UIKit
import SwiftUI

struct OTPView: UIViewRepresentable {
    
    @Binding var otpCode: String?
    var isValidCode: Bool?
    private let otpStackView = OTPStackView()
    
    func makeUIView(context: Context) -> OTPStackView {
        
        otpStackView.delegate = context.coordinator
        
        return otpStackView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        if let isValidCode, !isValidCode {
            uiView.setAllFieldColor(isWarningColor: true, color: uiView.errorColor)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    class Coordinator: OTPDelegate {
        
        var parent: OTPView
        
        init(_ parent: OTPView) {
            self.parent = parent
        }
        
        func didChangeValidity(isValid: Bool) {
            if isValid {
                parent.otpCode = parent.otpStackView.getOTP()
            } else {
                parent.otpCode = nil
            }
        }
    }
}

class OTPTextField: UITextField {
    
    weak var previousTextField: OTPTextField?
    weak var nextTextField: OTPTextField?
    
    override public func deleteBackward(){
        text = ""
        previousTextField?.becomeFirstResponder()
    }
    
}

protocol OTPDelegate: AnyObject {
    //always triggers when the OTP field is valid
    func didChangeValidity(isValid: Bool)
}

class OTPStackView: UIStackView {
    
    //Customise the OTPField here
    let numberOfFields = 4
    var textFieldsCollection: [OTPTextField] = []
    weak var delegate: OTPDelegate?
    var showsWarningColor = true
    
    //Colors
    let inactiveFieldBorderColor = UIColor.black.withAlphaComponent(0.25)
    let textBackgroundColor = UIColor.white
    let activeFieldBorderColor = UIColor.mimoYellow500
    let errorColor: UIColor = UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1)
    var remainingStrStack: [String] = []
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupStackView()
        addOTPFields()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupStackView()
        addOTPFields()
    }
    
    var isLayouted: Bool = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !isLayouted {
            textFieldsCollection.forEach { textField in
                textField.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
                textField.heightAnchor.constraint(equalToConstant: bounds.height).isActive = true
                textField.widthAnchor.constraint(equalToConstant: bounds.width/CGFloat(numberOfFields) - (CGFloat(numberOfFields - 1) * 10)/CGFloat(numberOfFields)).isActive = true
            }

            isLayouted = true
        }
    }
    
    //Customisation and setting stackView
    private final func setupStackView() {
        self.backgroundColor = .clear
        self.isUserInteractionEnabled = true
        self.translatesAutoresizingMaskIntoConstraints = false
        self.contentMode = .center
        self.distribution = .fillEqually
        self.alignment = .fill
        self.spacing = 10
    }
    
    //Adding each OTPfield to stack view
    private final func addOTPFields() {
        for index in 0..<numberOfFields{
            let field = OTPTextField()
            setupTextField(field)
            textFieldsCollection.append(field)
            //Adding a marker to previous field
            index != 0 ? (field.previousTextField = textFieldsCollection[index-1]) : (field.previousTextField = nil)
            //Adding a marker to next field for the field at index-1
            index != 0 ? (textFieldsCollection[index-1].nextTextField = field) : ()
        }
        textFieldsCollection[0].becomeFirstResponder()
    }
    
    //Customisation and setting OTPTextFields
    private final func setupTextField(_ textField: OTPTextField){
        textField.delegate = self
        textField.translatesAutoresizingMaskIntoConstraints = false
        self.addArrangedSubview(textField)
//        textField.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
//        textField.heightAnchor.constraint(equalToConstant: 64).isActive = true
//        textField.widthAnchor.constraint(equalToConstant: 48).isActive = true
//        textField.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 1/6).isActive = true
        textField.backgroundColor = textBackgroundColor
        textField.textAlignment = .center
        textField.adjustsFontSizeToFitWidth = false
        textField.font = UIFont(name: "Roboto-Regular", size: 24)
        textField.textColor = .black
        textField.layer.cornerRadius = 8
        textField.layer.borderWidth = 1
        textField.layer.borderColor = inactiveFieldBorderColor.cgColor
        textField.keyboardType = .numberPad
        textField.autocorrectionType = .yes
        textField.textContentType = .oneTimeCode
    }
    
    //checks if all the OTPfields are filled
    private final func checkForValidity() {
        for fields in textFieldsCollection{
            if (fields.text?.trimmingCharacters(in: CharacterSet.whitespaces) == ""){
                delegate?.didChangeValidity(isValid: false)
                return
            }
        }
        delegate?.didChangeValidity(isValid: true)
    }
    
    //gives the OTP text
    final func getOTP() -> String {
        var OTP = ""
        for textField in textFieldsCollection {
            OTP += textField.text ?? ""
        }
        return OTP
    }

    //set isWarningColor true for using it as a warning color
    final func setAllFieldColor(isWarningColor: Bool = false, color: UIColor) {
        for textField in textFieldsCollection{
            textField.layer.borderColor = color.cgColor
        }
        showsWarningColor = isWarningColor
    }
    
    //autofill textfield starting from first
    private final func autoFillTextField(with string: String) {
        remainingStrStack = string.reversed().compactMap{String($0)}
        for textField in textFieldsCollection {
            if let charToAdd = remainingStrStack.popLast() {
                textField.text = String(charToAdd)
            } else {
                break
            }
        }
        checkForValidity()
        remainingStrStack = []
    }
    
}

//MARK: - TextField Handling
extension OTPStackView: UITextFieldDelegate {
        
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if showsWarningColor {
            setAllFieldColor(color: inactiveFieldBorderColor)
            showsWarningColor = false
        }
        textField.layer.borderColor = activeFieldBorderColor.cgColor
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        checkForValidity()
        textField.layer.borderColor = inactiveFieldBorderColor.cgColor
    }
    
    //switches between OTPTextfields
    func textField(_ textField: UITextField, shouldChangeCharactersIn range:NSRange,
                   replacementString string: String) -> Bool {
        guard let textField = textField as? OTPTextField else { return true }
        if string.count > 1 {
            textField.resignFirstResponder()
            autoFillTextField(with: string)
            return false
        } else {
            if (range.length == 0 && string == "") {
                checkForValidity()
                return false
            } else if (range.length == 0){
                if textField.nextTextField == nil {
                    textField.text? = string
                    textField.resignFirstResponder()
                }else{
                    textField.text? = string
                    textField.nextTextField?.becomeFirstResponder()
                }
                return false
            }
            return true
        }
    }
    
}
