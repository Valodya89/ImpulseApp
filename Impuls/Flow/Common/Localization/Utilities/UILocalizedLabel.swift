//
//  UILocalizedLabel.swift
//  hay
//
//  Created by Vardan Gevorgyan on 2/10/20.
//  Copyright © 2020 Sedrak Igityan. All rights reserved.
//

import UIKit

/// Use this class to automatically localize label text
final class UILocalizedLabel: UILabel, LocalizableLabel {
    
    @IBInspectable var localizedText: String?
    
    
    // MARK: - Life cycle -
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setupListener()
        self.localizeText() // Localize text
    }
}


// MARK: - LocalizableLabel protocol -

/// Responsible for set localizable label
protocol LocalizableLabel: UILabel {
    
    
    // MARK: - Localize Functions -
    
    var localizedText: String? { get set }
    
    // Localizing text function
    func localizeText()
    func setupListener()
}


// MARK: - LocalizableLabel extension -

extension LocalizableLabel {
    
    
    // MARK: - Localize Functions -
    
    // Localizing text function
    func localizeText() {
        text = localizedText?.localized()
    }
    
    /// Setup observe for listening language update
    func setupListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateLanguage), name: Constant.Notifications.LanguageUpdate, object: nil)
    }
}

private extension UILabel {
    
    /// Action when language did update in label
    @objc func didUpdateLanguage() {
        let label = self as? LocalizableLabel
        layoutSubviews()
        superview?.layoutSubviews()

        label?.localizeText()
    }
}
