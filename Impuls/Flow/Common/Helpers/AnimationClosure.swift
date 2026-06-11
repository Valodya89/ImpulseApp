//
//  AnimationClosure.swift
//  Management App
//
//  Created by Vardan on 10/31/20.
//

import UIKit

func animationClosure(animatable: Bool, duration: TimeInterval, delay: TimeInterval = 0.0, animationOption: UIView.AnimationOptions = .curveEaseInOut, _ animation: @escaping ()->(), completion: ((Bool) -> ())? = nil) {
    if animatable {
        UIView.animate(withDuration: duration, delay: delay, options: animationOption, animations: animation, completion: completion)
    } else {
        animation() 
    }
}
