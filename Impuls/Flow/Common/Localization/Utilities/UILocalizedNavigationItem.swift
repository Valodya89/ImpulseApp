//
//  UILocalizedNavigationItem.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 7/25/21.
//

import UIKit

extension UINavigationItem {
    
    @IBInspectable var localizedTitle: String? {
        get {
            self.title
        } set {
            self.title = newValue?.localized()
        }
    }
}
