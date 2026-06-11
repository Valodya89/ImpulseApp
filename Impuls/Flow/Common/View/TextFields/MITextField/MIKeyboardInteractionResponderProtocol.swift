//
//  MIKeyboardInteractionResponderProtocol.swift
//  Management App
//
//  Created by Vardan on 9/21/20.
//

import UIKit

/// The text field keyboard interaction handlers, also animatable property. 
protocol MIKeyboardInteractionResponderProtocol {
    
    static var animatable: Bool { get set }
    static var keyboardAppearInteraction: Bool { get set}

    var parentView: UIView { get }
    var isFieldFirstResponder: Bool { get }
}
