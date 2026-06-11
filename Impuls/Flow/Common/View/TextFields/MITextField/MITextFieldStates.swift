//
//  MATextFieldStates.swift
//  Management App
//
//  Created by Vardan on 9/3/20.
//

import UIKit

/// MITextField states.
///
/// Depend on this states textField will play animations.
///
enum MATextFieldStates {
    /// When text field is empty.
    ///
    /// It will automaticly switch to this state if text become empty.
    ///
    case empty
    /// When text field become fitst responder or its edinting is started,
    ///
    case editing
    /// When text field did finish editing.
    ///
    case end
}
