//
//  AnimateOutContent.swift
//  MimoBike
//
//  Created by Dose on 6/9/21.
//

import UIKit

extension UIView {
    
    func animateOut(animatable: Bool, duration: Double = 0.3, completion: ((Bool)->())? = nil) {
        animationClosure(animatable: animatable, duration: duration, delay: 0.0, animationOption: .curveEaseInOut, {
            self.alpha = 0
        }, completion: completion)
        
    }
    
    func animateIn(animatable: Bool, duration: Double = 0.3, completion: ((Bool)->())? = nil) {
        animationClosure(animatable: animatable, duration: duration, delay: 0.0, animationOption: .curveEaseInOut, {
            self.alpha = 1
        }, completion: completion)
        
    }
}
