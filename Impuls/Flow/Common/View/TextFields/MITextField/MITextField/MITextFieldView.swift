//
//  MITextField.swift
//  Management App
//
//  Created by Vardan on 9/3/20.
//

import UIKit

/// Class that exdends from UITextField and changes its native pointer position.
final class MITextFieldPointer: UITextField {
    
    @IBInspectable var pointerY: CGFloat = 3
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        var rect = super.caretRect(for: position)
        rect.size.height = 18
        rect.origin.y = pointerY
        return rect
    }
    
    func parentMATextFieldView() -> MITextFieldView? {
        var view: UIView = self
        
        while let s = view.superview {
            if let findParent = s as? MITextFieldView {
                return findParent
            }
            view = s
        }
        return nil
    }
}

/// MITextFieldView animatable textField.
///
final class MITextFieldView: UIView, MIKeyboardInteractionResponderProtocol {
    
    // Protocol requirements.
    
    /// Is `MITextFieldView` animatable, defaults to true
    /// if `false` textField will not play any of its animations.
    static var animatable: Bool = true
    /// When keyboard appers and its become over this field, its automaticly moves to top.
    /// defualts to true.
    static var keyboardAppearInteraction: Bool = true
    
    /// TextField did becomes first responde, when in responder chain become firt placer.
    var didBecomeFirstResponder: (()->())? = nil 
    
    /// The parent view of this textField
    var parentView: UIView { return self}
    
    /// Does the textField still on the first responder ?
    var isFieldFirstResponder: Bool { return textField.isFirstResponder }
    
    
    //MARK: @IBOutlets & @IBInspectables -
    
    /// Handle keyboard interactions.
    @IBInspectable var handleKeyboardActions: Bool = true
    
    /// Text of placeholder for textField.
    @IBInspectable var text: String? = "" {
        didSet {
            titleLabel.text = text?.localized()
        }
    }
    
    /// The placeholder of textField bottom side.
    @IBInspectable var placeholder: String = "" {
        didSet {
            textField.placeholder = placeholder.localized()
        }
    }
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textField: MITextFieldPointer!
    @IBOutlet weak var titleBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var textFieldHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textFieldBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var errorLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var errorLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var fieldView: UIView!
    @IBOutlet weak var textFieldHeight: NSLayoutConstraint!
    @IBOutlet weak var leftConstaintTextLabel: NSLayoutConstraint!
    @IBOutlet weak var leftConstraintTextField: NSLayoutConstraint!
    
    
    //MARK: Properties -
    
    /// Delegate pattern see `UITextFieldDelegate` for details .
    weak var delegate: UITextFieldDelegate?
    
    /// Did change field value means user did insert or delete text.
    var didChangeFieldValue: ((String)->())?
    
    /// User did tapp in view.
    var didTappInView: (()->(Bool))?
    
    /// Property that detects text changes from user interface or code-side.
    var prefetchUpdateCompletionWhenTextSetManually: Bool = true
    /// Is Error message sown ?
    var isErrorShown: Bool = false
    /// Set text for field, turns off keyboard interactions.
    var fieldText: String {
        get {
            return textField.text ?? ""
        }
        set {
            MITextFieldView.keyboardAppearInteraction = false
            setFieldState(state: .editing)
            textField.text = newValue
            if prefetchUpdateCompletionWhenTextSetManually {
                didChangeFieldValue?(newValue)
            }
            setFieldState(state: .end)
            MITextFieldView.keyboardAppearInteraction = true
        }
    }
    
    /// The attributed text for textField.
    var fieldTextAttributed: NSAttributedString? {
        get {
            return textField.attributedText
        }
        
        set {
            setFieldState(state: .editing)
            textField.attributedText = newValue
            if let unwrapped = newValue {
                didChangeFieldValue?(unwrapped.string)
            }
            setFieldState(state: .end)
        }
    }
    
    
    
    /// Keyboard type see `UIKeyboardType` for details
    var keyboardType: UIKeyboardType {
        get {
            return .default
        }
        
        set {
            textField.keyboardType = newValue
        }
    }
    
    /// Text contentType see `UITextContentType` for details
    var textContentType: UITextContentType? {
        get {
            // Defaults to nickname.
            return .nickname
        }
        
        set {
            textField.textContentType = newValue
        }
    }
    
    
    //MARK: Initialization -
    
    override init(frame: CGRect = .init(x: 0, y: 0, width: 328, height: 56)) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    
    //MARK: - Private functions
    
    private func commonInit() {
        loadFromNib()
        setupTextField()
    }
    
    /// First setup of textField.
    private func setupTextField() {
        // Set up delegate patterns, set state to empty for default.
        textField.delegate = self
        fieldView.layer.masksToBounds = true
        UIView.setAnimationsEnabled(false)
        setFieldState(state: .empty)
        UIView.setAnimationsEnabled(true)
        // setup layers boarder and corners.
        layer.borderWidth = 0.5
        layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        layer.cornerRadius = 8
    }
    
    /// Change TextField state ( see `MATextFieldStates` for details)
    /// - Parameter state: The new state for textField.
    private func setFieldState(state: MATextFieldStates) {
        switch state {
        // Change constraints and font animation for empty state.
        case .empty:
            titleTopConstraint.constant = 10
            titleBottomConstraint.constant = 10
//            leftConstaintTextLabel.constant = 20
//            leftConstraintTextField.constant = 20
            textFieldBottomConstraint.constant = 0
            textFieldHeightConstraint.constant = 0
            textFieldHeight.constant = 38
            setNeedsLayout()
            animationClosure(animatable: MITextFieldView.animatable, duration: 0.3) {
                self.superview?.layoutIfNeeded()
                self.layoutIfNeeded()
            }
        // Change constraints height, frame animations for edititing state.
        case .editing:
            if MITextFieldView.keyboardAppearInteraction || !handleKeyboardActions {
                
                self.textField.becomeFirstResponder()
                didBecomeFirstResponder?() 
            }
//            leftConstaintTextLabel.constant = 15
//            leftConstraintTextField.constant = 15

            titleTopConstraint.constant = 10
            titleBottomConstraint.constant = 5
            textFieldBottomConstraint.constant = 10
            textFieldHeightConstraint.constant = 20
            textFieldHeight.constant = 63
            setNeedsLayout()
            self.superview?.setNeedsLayout()
            animationClosure(animatable: MITextFieldView.animatable, duration: 0.3) {
                self.superview?.layoutIfNeeded()
                self.layoutIfNeeded()
            }
        // Reset to defaults, if text is empty switch text field to empty state.
        case .end:
            textField.endEditing(true)
            if textField.text?.isEmpty ?? true {
                setFieldState(state: .empty)
            }
        }
    }

    
    //MARK: - Public functions
    
    /// Shows error message for this textField.
    /// - Parameter message: Message of error label.
    func showErrorMessage(with message: String) {
        // Change property state.
        isErrorShown = true
        // Set texts and constraints.
        errorMessageLabel.text = message
        errorLabelTopConstraint.constant = 3
        errorLabelHeightConstraint.constant = 15
        setNeedsLayout()
        self.superview?.setNeedsLayout()
        // Animation block.
        animationClosure(animatable: true, duration: 0.3) {
            self.superview?.layoutIfNeeded()
            self.layoutIfNeeded()
            self.errorMessageLabel.alpha = 1
            self.fieldView.layer.borderWidth = 1
            self.fieldView.layer.borderColor = UIColor.red.cgColor

        }
    }
    
    /// Hides error message for this textField.
    func hideCurrentErrorMessage() {
        // Change property state.
        isErrorShown = false
        // Set constraints.
        errorLabelTopConstraint.constant = 0
        errorLabelHeightConstraint.constant = 0
        setNeedsLayout()
        self.superview?.setNeedsLayout()
        // Animation block.
        animationClosure(animatable: true, duration: 0.3) {
            self.superview?.layoutIfNeeded()
            self.layoutIfNeeded()
            self.errorMessageLabel.alpha = 0
            self.fieldView.layer.borderWidth = 0
            self.fieldView.layer.borderColor = UIColor.clear.cgColor
        }
      
    }
    
    /// Manually start typeing for this text field.
    func startTyping() {
        setFieldState(state: .editing)
    }
    
    /// Manually resign from first responder.
    func endTyping() {
        setFieldState(state: .end)
    }
    
    /// Clear text and resets to defaults.
    func clear() {
        textField.attributedText = nil
        textField.text = ""
        setFieldState(state: .end)
    }
    
    
    //MARK: - IBActions
    
    /// TextField did change text value.
    /// - Parameter sender: Any object.
    @IBAction func didChangeFieldValue(_ sender: Any) {
        didChangeFieldValue?(fieldText)
    }
    
    /// Did start interaction with textField.
    /// - Parameter sender: Any object.
    @IBAction func didTappInView(_ sender: Any) {
        if let closure = didTappInView {
            if closure() {
                setFieldState(state: .editing)
            } 
        } else {
            setFieldState(state: .editing)
        }
    }
}



//MARK: - UITextFieldDelegate

extension MITextFieldView: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        setFieldState(state: .end)
        return  delegate?.textFieldShouldReturn?(textField) ?? true
        
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        setFieldState(state: .end)
        delegate?.textFieldDidEndEditing?(textField, reason: reason)
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return delegate?.textFieldShouldBeginEditing?(textField) ?? true
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        setFieldState(state: .end)
        return delegate?.textFieldShouldEndEditing?(textField) ?? true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.textFieldDidEndEditing?(textField)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.textFieldDidBeginEditing?(textField)
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        delegate?.textFieldDidChangeSelection?(textField)
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return delegate?.textFieldShouldClear?(textField) ?? true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return delegate?.textField?(textField, shouldChangeCharactersIn: range, replacementString: string) ?? true
    }
    
}
