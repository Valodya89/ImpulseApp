//
//  UILocalizedTextField.swift
//  hay
//
//  Created by Vardan Gevorgyan on 2/10/20.
//  Copyright © 2020 Sedrak Igityan. All rights reserved.
//

import UIKit

/// Use this class to automatically localize textfield fill text
final class UILocalizedTextField: UITextField, LocalizableTextField {
    
    @IBInspectable var localizedPlaceholder: String?

    
    // MARK: - Life cycle -
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupListener()
        self.localizeText()
    }
}


// MARK: - LocalizableTextField protocol -

/// Responsible for set localizable textfield
protocol LocalizableTextField: UITextField {
    
    
    // MARK: - Localize Functions -
    
    var localizedPlaceholder: String? { get set }
    
    // Localizing text function
    func localizeText()
    func setupListener()
}


// MARK: - LocalizableTextField extension -

extension LocalizableTextField {
    
    
    // MARK: - Localize Functions -
    
    // Localizing text function
    func localizeText() {
//        print("textfield placeholder key is` ", placeholder?.getKey() ?? "")
//        print("textfield placeholder text is` ", placeholder?.getKey().localized() ?? "")
        placeholder = localizedPlaceholder?.localized()
    }
    
    /// Setup observe for listening language update
    func setupListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: Constant.Notifications.LanguageUpdate, object: nil)
    }
}

extension UITextField {
    
    /// Action when language did update in text field
    @objc func didUpdateLanguage() {
        let textField = self as? LocalizableTextField
        layoutSubviews()
        superview?.layoutSubviews()

        textField?.localizeText()
    }
}
