//
//  MATextView.swift
//  Management App
//
//  Created by Dose on 9/20/20.
//  Copyright © 2020 Doseh. All rights reserved.
//

import UIKit


final class MITextViewElement: UITextView {
    
    override func caretRect(for position: UITextPosition) -> CGRect {
        var rect = super.caretRect(for: position)
        rect.size.height = 18
        rect.origin.y = rect.origin.y + 3
        return rect
    }
    
    func parentMATextFieldView() -> MITextView? {
        var view: UIView = self
        
        while let s = view.superview {
            if let findParent = s as? MITextView {
                return findParent
            }
            view = s
        }
        
        return nil
    }
}

final class MITextView: UIView, MIKeyboardInteractionResponderProtocol {
    
    // Protocol requirements.
    
    static var animatable: Bool = true
    static var keyboardAppearInteraction: Bool = true
    
    var didBecomeFirstResponder: (()->())? = nil
    
    var parentView: UIView { return self}
    
    var isFieldFirstResponder: Bool { return textView.isFirstResponder }

    /// Current attributes for textField. 
    fileprivate let textViewAttributes: [NSAttributedString.Key:Any] = [
        .font: UIFont.init(name: "Roboto-Regular", size: 17)!,
        .foregroundColor: UIColor.black,
        .paragraphStyle: {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 0
            return paragraph
        }()
    ]

    
    //MARK: @IBOutlets & @IBInspectables -
    
    @IBInspectable var handleKeyboardActions: Bool = true
    
    @IBInspectable var text: String? = "" {
        didSet {
            titleLabel.text = text?.localized()
        }
    }
    

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: MITextViewElement!
    @IBOutlet weak var titleBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var titleTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var errorLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var errorLabelTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var fieldView: UIView!
    @IBOutlet weak var fieldViewHeightConstant: NSLayoutConstraint!
    
    
    //MARK: Properties -
    
    // Delegate of textView
    weak var delegate: UITextViewDelegate?
    
    /// Did Change textView text value.
    var didChangeFieldValue: ((String)->())?
    
    /// Did Insert or remove new line from textView. (Need to update scrollView if exist.)
    var needsUpdateLayout: (()->())?
    
    var fieldText: String {
        get {
            return textView.attributedText.string
        }
        
        set {
            MITextView.keyboardAppearInteraction = false
            setFieldState(state: .editing)
            textView.attributedText = NSAttributedString(string: newValue, attributes: textViewAttributes)
            didChangeFieldValue?(newValue)
            setFieldState(state: .end)
            prefetchTextView()
            MITextView.keyboardAppearInteraction = true
        }
    }
    
    var titleText: String {
        get {
            return titleLabel.text ?? ""
        }
        
        set {
            titleLabel.text = newValue
        }
    }
    
    var keyboardType: UIKeyboardType {
        get {
            return .default
        }
        
        set {
            textView.keyboardType = newValue
        }
    }
    
    var textContentType: UITextContentType? {
        get {
            return .nickname
        }
        
        set {
            textView.textContentType = newValue
        }
    }
    
    
    //MARK: Initialization -
    
    override init(frame: CGRect) {
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
    
    /// Setup textfField base configurations.
    private func setupTextField() {
        textView.delegate = self
        // Set default configuration for textContainer.
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = .zero
        textView.contentInset = .zero
        // Layout manager Delegate.
        textView.layoutManager.delegate = self
        fieldView.layer.masksToBounds = true
        UIView.setAnimationsEnabled(false)
        setFieldState(state: .empty)
        UIView.setAnimationsEnabled(true)
        layer.borderWidth = 0.5
        layer.borderColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        layer.cornerRadius = 8
        clipsToBounds = true
        
    }
    
    /// Animatable set current editable field state
    /// - Parameter state: Current field state.
    private func setFieldState(state: MATextFieldStates) {
        switch state {
        
        case .empty:
            titleTopConstraint.constant = 10
            titleBottomConstraint.constant = 10
            textViewBottomConstraint.constant = 0
            textViewHeightConstraint.constant = 0
            fieldViewHeightConstant.constant = 38
            setNeedsLayout()            
            animationClosure(animatable: MITextView.animatable, duration: 0.3) {
                self.superview?.layoutIfNeeded()
                self.layoutIfNeeded()
            }

            
        case .editing:
            if MITextView.keyboardAppearInteraction {
                self.textView.becomeFirstResponder()
            }
            titleTopConstraint.constant = 10
            titleBottomConstraint.constant = 10
            if textView.text.isEmpty {
                fieldViewHeightConstant.constant = 63
                textViewBottomConstraint.constant = 7
                textViewHeightConstraint.constant = 24
            }
            setNeedsLayout()
            animationClosure(animatable: MITextView.animatable, duration: 0.3) {
                self.superview?.layoutIfNeeded()
                self.layoutIfNeeded()
            }

        case .end:
            textView.endEditing(true)
            if textView.text?.isEmpty ?? true {
                setFieldState(state: .empty)
            }
        }
    }
 
    /// Prefetch update text view height.
    private func prefetchTextView(isCollapseDelegation: Bool = true) {
        if isCollapseDelegation {
            guard !textView.text.isBlank else { return }
        }
        // Calculate constraint that should be changed.
        let needUpdateConstant = textView.contentSize.height - textViewHeightConstraint.constant
        guard abs(needUpdateConstant) > 0 else { return }
        
        // Change fieldView height constraint.
        fieldViewHeightConstant.constant += needUpdateConstant
        // Also textViews height constraint.
        textViewHeightConstraint.constant = textView.contentSize.height
        // Animate layouts for parent and current view.
        setNeedsLayout()
        superview?.setNeedsLayout()
        self.needsUpdateLayout?()
        UIView.animate(withDuration: 0.3, animations: {[weak self] in
            self?.layoutIfNeeded()
            self?.superview?.layoutIfNeeded()
        }) {[weak self] _ in
            self?.needsUpdateLayout?()

        }
    }

    
    //MARK: Public functions
    
    func startTyping() {
        setFieldState(state: .editing)
    }
  
    /// Clear Contextual representation of field. Clear Text.
    /// - Parameter animatable: Animatable or not. 
    func clear(animatable: Bool = true) {
        MITextView.animatable = animatable
        MITextView.keyboardAppearInteraction = false
        textView.text = ""
        setFieldState(state: .empty)
        MITextView.keyboardAppearInteraction = true
        MITextView.animatable = true
    }
 
    /// Hide recently showed error message.
    func hideCurrentErrorMessage() {
        // Change error view constraints to default 0.
        errorLabelTopConstraint.constant = 0
        errorLabelHeightConstraint.constant = 0
        // Animate parent view, to layout its subviews.
        setNeedsLayout()
        self.superview?.setNeedsLayout()
        animationClosure(animatable: true, duration: 0.3) {
            self.superview?.layoutIfNeeded()
            self.layoutIfNeeded()
            self.errorMessageLabel.alpha = 0
            self.fieldView.layer.borderWidth = 0
            self.fieldView.layer.borderColor = UIColor.clear.cgColor
        }
    }
 
    /// Show error message.
    /// - Parameter message: Error label text.
    func showErrorMessage(with message: String) {
        // Update text.
        errorMessageLabel.text = message
        // Update error view constraints.
        errorLabelTopConstraint.constant = 3
        errorLabelHeightConstraint.constant = 15
        // Animate parent view, to layout its subviews.
        setNeedsLayout()
        self.superview?.setNeedsLayout()
        animationClosure(animatable: true, duration: 0.3) {
            self.superview?.layoutIfNeeded()
            self.layoutIfNeeded()
            self.errorMessageLabel.alpha = 1
            self.fieldView.layer.borderWidth = 1
            self.fieldView.layer.borderColor = UIColor.red.cgColor

        }
    }
    
    
    //MARK: - IBActions
    
    @IBAction func didTappInView(_ sender: Any) {
        setFieldState(state: .editing)
        prefetchTextView()
    }
}



//MARK: - UITextFieldDelegate

extension MITextView: UITextViewDelegate, NSLayoutManagerDelegate {
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        setFieldState(state: .end)        
        return delegate?.textViewShouldEndEditing?(textView) ?? true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        delegate?.textViewDidChange?(textView)
        didChangeFieldValue?(textView.text)
        prefetchTextView(isCollapseDelegation: false)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        if text == "\n" {
            setFieldState(state: .end)
            return false
        }
        
        return delegate?.textView?(textView, shouldChangeTextIn: range, replacementText: text) ?? true
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.typingAttributes = textViewAttributes
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        setFieldState(state: .end)
        delegate?.textViewDidEndEditing?(textView)
    }
    
    func textViewDidChangeSelection(_ textView: UITextView) {
        delegate?.textViewDidChangeSelection?(textView)
    }
    
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
      return  delegate?.textViewShouldBeginEditing?(textView) ?? true
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return delegate?.textView?(textView, shouldInteractWith: URL, in: characterRange, interaction: interaction) ?? true
    }
    
    func textView(_ textView: UITextView, shouldInteractWith textAttachment: NSTextAttachment, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        return delegate?.textView?(textView, shouldInteractWith: textAttachment, in: characterRange, interaction: interaction) ?? true
    }
}
