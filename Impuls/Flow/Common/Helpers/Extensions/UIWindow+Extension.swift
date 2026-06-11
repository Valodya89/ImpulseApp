//
//  UIWindow+Extension.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 01.10.22.
//

import UIKit

extension UIWindow {
    
    static let keyWindow = UIApplication.shared.keyWindow
    static var topViewControler: UIViewController? {
        var top = UIWindow.keyWindow?.rootViewController
        while (top?.presentationController) != nil {
            top = top?.presentedViewController
            
        }
        return top
    }
}

