//
//  DatePickerTextField.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.09.23.
//

import SwiftUI
import UIKit

final class DatePickerTextField: UITextField {
    
    @Binding var date: Date?
    
    private let datePicker = UIDatePicker()
    
    init(date: Binding<Date?>, frame: CGRect) {
        self._date = date
        super.init(frame: frame)
        datePicker.datePickerMode = .date
        datePicker.set18YearValidation()
        datePicker.preferredDatePickerStyle = .wheels
        inputView = datePicker
        datePicker.addTarget(self, action: #selector(datePickerDidSelect(_:)), for: .valueChanged)
        datePicker.datePickerMode = .date
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dismissTextField))
        toolBar.setItems([flexibleSpace, doneButton], animated: false)
        inputAccessoryView = toolBar
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func datePickerDidSelect(_ sender: UIDatePicker) {
        date = sender.date
    }
    
    @objc private func dismissTextField() {
        resignFirstResponder()
    }
    
}

struct DatePickerInputView: UIViewRepresentable {
    
    @Binding var date: Date?
    let placeholder: String
    
    init(date: Binding<Date?>, placeholder: String) {
        self._date = date
        self.placeholder = placeholder
    }
    
    func updateUIView(_ uiView: DatePickerTextField, context: Context) {
        if let date = date {
            uiView.text = date.toString(format: .custom("dd-MM-yyyy"))
        }
    }
    
    func makeUIView(context: Context) -> DatePickerTextField {
        let dptf = DatePickerTextField(date: $date, frame: .zero)
        dptf.placeholder = placeholder
        if let date = date {
            dptf.text = "\(date)"
        }
        
        return dptf
    }
    
}

private extension UIDatePicker {
    func set18YearValidation() {
        let currentDate: Date = Date()
        var calendar: Calendar = Calendar(identifier: Calendar.Identifier.gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        var components: DateComponents = DateComponents()
        components.calendar = calendar
        components.year = -18
        let maxDate: Date = calendar.date(byAdding: components, to: currentDate)!
        components.year = -150
        let minDate: Date = calendar.date(byAdding: components, to: currentDate)!
        self.minimumDate = minDate
        self.maximumDate = maxDate
    }
}
