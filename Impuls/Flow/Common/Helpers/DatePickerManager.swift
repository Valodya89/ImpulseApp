//
//  DatePickerManager.swift
//  MimoBike
//
//  Created by Vardan on 06.05.21.
//

import UIKit


class DatePickerManager {
    
    var view = UIView()
    var textField = UITextField()
    var datePickerView = UIDatePicker()
    var tapGesture = UITapGestureRecognizer()
    let dateFormatter = DateFormatter()

    init(view: UIView, textField: UITextField, hasDoneButton: Bool = true, dateFormat: String, maxDate: Date? = Date()) {
        self.view = view
        self.textField = textField
        
        if hasDoneButton {
            self.textField.inputAccessoryView = createToolbar(title: "".localized())
        }
        dateFormatter.dateFormat = dateFormat
        datePickerView.maximumDate = maxDate
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(hidePicker))
        datePickerView.preferredDatePickerStyle = .wheels
        datePickerView.sizeToFit()
        self.textField.tintColor = .clear
    }
    
    init(view: UIView, textField: MITextFieldView, hasDoneButton: Bool = true, dateFormat: String, maxDate: Date? = nil) {
        self.view = view
        self.textField = textField.textField
        if hasDoneButton {
            self.textField.inputAccessoryView = createToolbar(title: "".localized())
        }
        
        dateFormatter.dateFormat = dateFormat
        if let maxDate = maxDate {
            datePickerView.maximumDate = maxDate
        }
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(hidePicker))
        datePickerView.preferredDatePickerStyle = .wheels
        datePickerView.sizeToFit()
        self.textField.tintColor = .clear
    }
    
    func showDatePicker(mode: UIDatePicker.Mode) {
        
        view.addGestureRecognizer(tapGesture)
        datePickerView.datePickerMode = mode
        textField.inputView = datePickerView
        datePickerView.addTarget(self, action: #selector(handleDatePickerValue(sender:)), for: .valueChanged)
    }
    
    
    @objc private func handleDatePickerValue(sender: UIDatePicker) {

        textField.text = dateFormatter.string(from: sender.date)
    }
    
    @objc private func hidePicker() {
        view.endEditing(true)
        view.removeGestureRecognizer(tapGesture)
    }
    
    /// Create toolbar with title and done button
    private func createToolbar(title: String) -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
//        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        let doneButton = UIBarButtonItem(title: "MOBILE_global_done".localized(), style: .done, target: self, action: #selector(hidePicker))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let titleButton = UIBarButtonItem(title: title, style: .plain, target: nil, action: nil)
        titleButton.isEnabled = false
        titleButton.setTitleTextAttributes([.foregroundColor : UIColor.black], for: .disabled)
        toolbar.setItems([flexSpace, titleButton, flexSpace, doneButton], animated: true)
        return toolbar
    }
}
