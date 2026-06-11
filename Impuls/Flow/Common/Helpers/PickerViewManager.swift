//
//  PickerViewManager.swift
//  MimoBike
//
//  Created by Vardan on 07.05.21.
//

import UIKit

protocol PickerViewManagerDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int)
}

protocol PickerViewManagerDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
}

class PickerViewManager: NSObject {
    
    var view = UIView()
    var pickerView = UIPickerView()
    var textField = UITextField()
    var tapGesture = UITapGestureRecognizer()

    var delegate: PickerViewManagerDelegate?
    var dataSource: PickerViewManagerDataSource?
    
    init(view: UIView,textField: UITextField, hasDoneButton: Bool = false) {
        self.textField = textField
        self.view = view
        super.init()
        if hasDoneButton {
            self.textField.inputAccessoryView = createToolbar(title: "".localized())
        }
        self.textField.tintColor = .clear
        tapGesture.addTarget(self, action: #selector(hidePicker))
        configureDelegates()
    }
    
    func configureDelegates() {
        pickerView.delegate = self
        pickerView.dataSource = self
    }
    
    func showPickerView() {
        view.addGestureRecognizer(tapGesture)
        textField.inputView = pickerView
    }
    
    @objc func hidePicker() {
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

extension PickerViewManager: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        guard let dataSource = dataSource else { return 0 }

        return dataSource.numberOfComponents(in: pickerView)
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        
        guard let dataSource = dataSource else { return 0 }
        
        return dataSource.pickerView(pickerView, numberOfRowsInComponent: component)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return delegate?.pickerView(pickerView, titleForRow: row, forComponent: component)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        VibrateManager.vibrate()
        delegate?.pickerView(pickerView, didSelectRow: row, inComponent: component)
    }
}
