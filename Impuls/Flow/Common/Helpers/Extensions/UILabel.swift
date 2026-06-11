//
//  UILabel.swift
//  MimoBike
//
//  Created by Vardan on 22.04.21.
//

import UIKit

extension UILabel {
    
    
    func colorString(text: String?, coloredText: [String]?, color: UIColor? = .mimoBlack, font: UIFont =  UIFont(name: "Roboto-Medium", size: 15)!) {
        guard let selfText = text, let coloredText = coloredText else { return }

        let attributedString = NSMutableAttributedString(string: selfText)
        
        for  coloredText in coloredText {
            let range = (selfText as NSString).range(of: coloredText)
            attributedString.setAttributes([NSAttributedString.Key.foregroundColor: color!,
                                            NSAttributedString.Key.font: font],
                                           range: range)
        }
        
        self.attributedText = attributedString
    }
    
    func underLineText(texts: [String]) {
        guard let selfText = self.text else { return }
        let attributedString = NSMutableAttributedString(string: selfText)
        
        for text in texts {
            let range = (selfText as NSString).range(of: text)
            attributedString.setAttributes([
                NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue
            ], range: range)
        }
        
        self.attributedText = attributedString
    }
}
