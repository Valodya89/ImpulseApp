//
//  KeyboardScrollView.swift
//  Management App
//
//  Created by Dose on 9/4/20.
//  Copyright © 2020 Doseh. All rights reserved.
//

import UIKit


// MARK: - KeyboardNotifying -
/// Responsible for setting keyboard notifiers.
protocol KeyboardNotifying {
    func start()
}


// MARK: - KeyboardScrollView -
/// Responsible to scroll for textfields to handle keyboard events
/// `Extend` your scroll view to KeyboardScrollView
final class KeyboardScrollView: UIScrollView {
    
    
    // MARK: - Properties -
    
    @IBOutlet var maTextFields: [MITextFieldView] = []
    @IBOutlet var maTextViews: [MITextView] = []
    @IBOutlet var baseTextFields: [UITextField] = []

    /// Textfields, which will be scored
    lazy var textFields: [MIKeyboardInteractionResponderProtocol] = {return maTextViews + maTextFields + baseTextFields}()
    lazy var lastInsets: UIEdgeInsets = contentInset
    
    var lastAppearKeyboardHeight: CGFloat = -1
    var lastResponder: MIKeyboardInteractionResponderProtocol?
    
    // MARK: - Private Functions -
    
    override func awakeFromNib() {
        contentInset = lastInsets
        start()
    }
    
    deinit {
        maTextFields.removeAll()
        maTextViews.removeAll()
        textFields.removeAll()
    }
    
    // MARK: - Keyboard Selectors -
    
    /// Action when keyboard hides
    @objc private func keyboardWillHide(notification: Notification) {
        self.contentInset = lastInsets
        self.scrollIndicatorInsets = self.contentInset
    }
    
    /// Action when keyboard shows
    @objc private func keyboardWasShown(notification: Notification) {
        for textField in self.textFields {
            /// Check which textfield is currently active
            guard textField.isFieldFirstResponder else {
                /// Is not active
                continue
            }
            
            /// Than
            let userInfo = notification.userInfo
            
            /// Get keyboard size
            guard let keyboardSize = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                /// Failed
                debugPrint("Can not get keyboard size")
                
                return
            }
            lastResponder = textField
            /// Get keyboard size relate to screen
            
            /// Set inset to scroll view
            let isAnimatable = self.contentInset.bottom == lastAppearKeyboardHeight
            self.lastAppearKeyboardHeight = keyboardSize.height
            self.contentInset.bottom = keyboardSize.height
            self.scrollIndicatorInsets = self.contentInset
            
            
            /// Scroll to be visible
            
            let frame = textField.parentView.convert(textField.parentView.bounds, to: self)
            
           scrollRectToVisible(frame, animated: isAnimatable)
        }
    }
    
    func updateScrollDirectionBasedLastResponder() {
        if let lastResponder = lastResponder {
            let frame = lastResponder.parentView.convert(lastResponder.parentView.bounds, to: self)
            self.scrollRectToVisible(frame, animated: true)
        }
    }
}


// MARK: - KeyboardNotifying IMPL -
extension KeyboardScrollView: KeyboardNotifying {
    
    
    /// Responsible for set observer to keyboard actions
    func start() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWasShown(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

extension UIScrollView {
    func scrollToBottom(animated: Bool) {
        if self.contentSize.height < self.bounds.size.height { return }
        let bottomOffset = CGPoint(x: 0, y: self.contentSize.height - self.bounds.size.height)
        self.setContentOffset(bottomOffset, animated: animated)
    }
}

extension UITextField: MIKeyboardInteractionResponderProtocol {
    static var animatable: Bool = false
    
    static var keyboardAppearInteraction: Bool = false
    
    var parentView: UIView {
        return self
    }
    
    var isFieldFirstResponder: Bool {
        return self.isFirstResponder
    }
    
    
}
