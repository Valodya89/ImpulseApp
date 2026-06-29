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

    /// Shows a compact (inline chip) date picker overlaid on the text field.
    /// The calendar popover is presented by the system next to the chip; with the
    /// chip pinned near the field it opens above the field when there is no room
    /// below. The text field keeps its tap handling disabled so only the chip
    /// reacts to taps and no keyboard appears.
    func showCompactDatePicker(mode: UIDatePicker.Mode, initialDate: Date? = nil) {
        datePickerView.datePickerMode = mode
        datePickerView.preferredDatePickerStyle = .compact
        if let initialDate = initialDate {
            datePickerView.date = initialDate
        }

        // Compact style is shown inline, not via the keyboard input view.
        textField.inputView = nil
        textField.inputAccessoryView = nil

        datePickerView.removeFromSuperview()
        datePickerView.translatesAutoresizingMaskIntoConstraints = false
        // Add the chip to the text field's container rather than to the text
        // field itself: UITextField manages its own internal subviews and can
        // reposition an added subview, which prevents reliable vertical
        // centering. The inner text field sits in the lower part of the field
        // box (the title label is above it), so pin the chip to the container's
        // vertical center to place it in the middle of the visible field box.
        let container = textField.superview ?? textField
        container.addSubview(datePickerView)
        NSLayoutConstraint.activate([
            datePickerView.trailingAnchor.constraint(equalTo: textField.trailingAnchor),
            datePickerView.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])

        // The chip itself displays the selected date, so hide the field's own
        // (redundant) text. Give the picker an explicit, visible tint because the
        // text field's tint is cleared (which would otherwise hide the chip text).
        textField.textColor = .clear
        datePickerView.tintColor = .label

        // Reflect the initial selection in the bound text immediately.
        textField.text = dateFormatter.string(from: datePickerView.date)
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
