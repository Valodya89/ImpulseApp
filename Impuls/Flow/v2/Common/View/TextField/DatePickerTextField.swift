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
        datePicker.preferredDatePickerStyle = .compact
        datePicker.addTarget(self, action: #selector(datePickerDidSelect(_:)), for: .valueChanged)

        // A compact picker only responds to taps on its own chip, so we place a
        // visible, tappable chip inside the field. Its calendar popover anchors
        // to the chip and therefore opens directly under the date-of-birth field.
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        addSubview(datePicker)
        NSLayoutConstraint.activate([
            datePicker.trailingAnchor.constraint(equalTo: trailingAnchor),
            datePicker.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        // The visible chip shows the selected date, so don't let the text field
        // draw its own (now redundant) text over it. Only the field's own text is
        // hidden — the picker keeps its default tint so the chip stays readable.
        textColor = .clear
    }

    // Let taps reach the compact picker's chip; the field itself stays inert.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        let pointInPicker = convert(point, to: datePicker)
        return datePicker.point(inside: pointInPicker, with: event)
    }

    override func caretRect(for position: UITextPosition) -> CGRect {
        .zero
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func datePickerDidSelect(_ sender: UIDatePicker) {
        date = sender.date
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
