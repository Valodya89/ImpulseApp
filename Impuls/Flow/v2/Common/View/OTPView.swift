//
//  OTPView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 26.09.23.
//

import UIKit
import SwiftUI

/// SwiftUI wrapper around `OTPCodeView`.
///
/// `otpCode` is set to the full code once every box is filled and back to `nil`
/// while the code is incomplete, so callers can gate the "continue" button on it.
struct OTPView: UIViewRepresentable {

    @Binding var otpCode: String?
    var isValidCode: Bool?

    func makeUIView(context: Context) -> OTPCodeView {
        let view = OTPCodeView()
        view.delegate = context.coordinator
        return view
    }

    func updateUIView(_ uiView: OTPCodeView, context: Context) {
        context.coordinator.parent = self
        if let isValidCode, !isValidCode {
            uiView.setAllFieldColor(isWarningColor: true, color: uiView.errorColor)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: OTPDelegate {

        var parent: OTPView

        init(_ parent: OTPView) {
            self.parent = parent
        }

        func otpCodeDidChange(_ code: String, isComplete: Bool) {
            parent.otpCode = isComplete ? code : nil
        }
    }
}

protocol OTPDelegate: AnyObject {
    /// Called on every edit. `isComplete` is true when every box holds a digit.
    func otpCodeDidChange(_ code: String, isComplete: Bool)
}

/// Four digit boxes driven by one invisible `UITextField` that covers the whole
/// view. A single text field is what iOS expects for SMS one-time-code autofill
/// (`textContentType = .oneTimeCode`): the "From Messages" suggestion above the
/// keyboard inserts the whole code at once, and paste works the same way. The
/// digits are rendered into the boxes, so no text is ever visible in the field
/// itself.
final class OTPCodeView: UIView {

    let numberOfFields = 4
    weak var delegate: OTPDelegate?
    private(set) var showsWarningColor = false

    // Colors
    let inactiveFieldBorderColor = UIColor.black.withAlphaComponent(0.25)
    let textBackgroundColor = UIColor.white
    let activeFieldBorderColor = UIColor.mimoYellow500
    let errorColor = UIColor(red: 0.96, green: 0.26, blue: 0.21, alpha: 1)

    private let boxesStackView = UIStackView()
    private var digitLabels: [UILabel] = []
    private let textField = UITextField()
    private var hasRequestedFocus = false

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        // Focus once the view is actually on screen: `becomeFirstResponder()` is a
        // no-op before that, and the SMS code suggestion only shows while the
        // field is first responder.
        guard window != nil, !hasRequestedFocus else { return }
        hasRequestedFocus = true
        DispatchQueue.main.async { [weak self] in
            self?.textField.becomeFirstResponder()
        }
    }

    // MARK: - Public API

    /// The digits entered so far (may be shorter than `numberOfFields`).
    func getOTP() -> String {
        textField.text ?? ""
    }

    /// Set `isWarningColor` to keep the color until the user edits again.
    func setAllFieldColor(isWarningColor: Bool = false, color: UIColor) {
        digitLabels.forEach { $0.layer.borderColor = color.cgColor }
        showsWarningColor = isWarningColor
    }

    func clear() {
        textField.text = ""
        textDidChange()
    }

    // MARK: - Setup

    private func setup() {
        backgroundColor = .clear

        boxesStackView.axis = .horizontal
        boxesStackView.distribution = .fillEqually
        boxesStackView.alignment = .fill
        boxesStackView.spacing = 10
        boxesStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(boxesStackView)

        for _ in 0..<numberOfFields {
            let label = UILabel()
            label.backgroundColor = textBackgroundColor
            label.textAlignment = .center
            label.font = UIFont(name: "Roboto-Regular", size: 24)
            label.textColor = .black
            label.layer.cornerRadius = 8
            label.layer.masksToBounds = true
            label.layer.borderWidth = 1
            label.layer.borderColor = inactiveFieldBorderColor.cgColor
            label.isAccessibilityElement = false
            digitLabels.append(label)
            boxesStackView.addArrangedSubview(label)
        }

        // Invisible field on top of the boxes: it owns the keyboard, receives the
        // autofill / paste, and any tap on a box lands on it.
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = .clear
        textField.textColor = .clear
        textField.tintColor = .clear
        textField.keyboardType = .numberPad
        textField.textContentType = .oneTimeCode
        textField.autocorrectionType = .no
        textField.spellCheckingType = .no
        textField.delegate = self
        textField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        textField.accessibilityLabel = "MOBILE_sign_in_verify_phone_number".localized()
        addSubview(textField)

        NSLayoutConstraint.activate([
            boxesStackView.topAnchor.constraint(equalTo: topAnchor),
            boxesStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            boxesStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            boxesStackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            textField.topAnchor.constraint(equalTo: topAnchor),
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    // MARK: - Editing

    @objc private func textDidChange() {
        let digits = String((textField.text ?? "").filter(\.isNumber).prefix(numberOfFields))
        if textField.text != digits {
            textField.text = digits
        }
        render(digits)

        let isComplete = digits.count == numberOfFields
        delegate?.otpCodeDidChange(digits, isComplete: isComplete)
        if isComplete {
            textField.resignFirstResponder()
        }
    }

    private func render(_ digits: String) {
        let characters = Array(digits)
        let activeIndex = textField.isFirstResponder ? characters.count : -1
        for (index, label) in digitLabels.enumerated() {
            label.text = index < characters.count ? String(characters[index]) : ""
            guard !showsWarningColor else { continue }
            label.layer.borderColor = (index == activeIndex ? activeFieldBorderColor : inactiveFieldBorderColor).cgColor
        }
    }
}

// MARK: - UITextFieldDelegate

extension OTPCodeView: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        if showsWarningColor {
            showsWarningColor = false
        }
        render(getOTP())
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        render(getOTP())
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        let current = textField.text ?? ""

        // SMS autofill and paste deliver the whole code in one call: take its
        // digits as the new code regardless of where the caret was.
        if string.count > 1 {
            textField.text = String(string.filter(\.isNumber).prefix(numberOfFields))
            textDidChange()
            return false
        }

        // Typing a digit into an already complete (e.g. rejected) code starts over.
        if range.length == 0, !string.isEmpty, current.count >= numberOfFields {
            textField.text = string
            textDidChange()
            return false
        }

        return true
    }
}
