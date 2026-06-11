//
//  UILocalizedButton.swift
//  Paylican
//
//  Created by Sedrak Igityan on 2/10/20.
//  Copyright © 2020 Paylican. All rights reserved.
//

import UIKit

/// Responsible to make abstraction of button type.
///
/// Parameters can be `attrbuted` and `plain`
public enum ButtonTextType {
    
    /// attributed with `NSMutableAttributedString` value
    case attributed(NSMutableAttributedString)
    /// plain type
    case plain(String)
}


/// Use this class to automatically localize button title
class UILocalizedButton: UIButton, LocalizableButton {
    
    @IBInspectable var localizedTitle: String?

    
    // MARK: - View lifecycle -
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupListener()
        self.localizeTitle() // Localize button title
    }
    
    
    // MARK: - Localize Functions -
    
    /// Localizing text function
    public func localizeTitle() {
        let localizedTitleString = self.getLocalizedTitle()
        
        self.setLocalizedTitle(textType: localizedTitleString)
    }
    
    /// Set localized string to button
    /// - parameter textType: localized title of button with type of text
    public func setLocalizedTitle(textType: ButtonTextType) {
        switch textType {
        case .attributed(let attributedString):
            /// Set attributed
            setAttributedTitle(attributedString, for: .normal)
            setAttributedTitle(attributedString, for: .selected)
            setAttributedTitle(attributedString, for: .disabled)
            setAttributedTitle(attributedString, for: .focused)
        case .plain(let title):
            /// Plain
            setTitle(title, for: .normal)
            setTitle(title, for: .selected)
            setTitle(title, for: .disabled)
            setTitle(title, for: .focused)
        }
    }
    
    /// Get text from button in localized way
    public func getLocalizedTitle() -> ButtonTextType {
        /// Get attributed title for button
        if let attributedText = self.attributedTitle(for: self.state) {
            /// Convert to mutable
            let mutable = NSMutableAttributedString(attributedString: attributedText)
            /// Change text with localized one
            mutable.mutableString.setString(localizedTitle?.localized() ?? "")
            
            return .attributed(mutable)
        }
        
        /// Otherwise
        /// Change plain text with localized one
        return .plain(localizedTitle?.localized() ?? "")
    }
}



// MARK: - LocalizableButton protocol -

/// Responsible for set localizable button
protocol LocalizableButton: UIButton {
    
    
    // MARK: - Localize Functions -
    
    var localizedTitle: String? { get set }
    
    /// Localizing text function
    func localizeTitle()
    func setupListener()
}


// MARK: - LocalizableButton extension -

extension LocalizableButton {
    
    
    // MARK: - Localize Functions -
    
    /// Localizing text function
    func localizeTitle() {
        self.setLocalizedTitle(title: localizedTitle?.localized())
    }
    
    /// Setup observe for listening language update
    func setupListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: Constant.Notifications.LanguageUpdate, object: nil)
    }
    
    /// Set localized string to button
    /// - parameter title: localized title of button
    func setLocalizedTitle(title: String?) {
        self.setTitle(title, for: .normal)
    }
}

private extension UIButton {
    
    /// Action when language did update in button
    @objc func didUpdateLanguage() {
        let button = self as? LocalizableButton
        layoutSubviews()
        superview?.layoutSubviews()
        button?.localizeTitle()
    }
}
