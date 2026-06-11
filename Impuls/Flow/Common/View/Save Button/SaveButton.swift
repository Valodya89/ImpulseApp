//
//  SaveButton.swift
//  MimoBike
//
//  Created by Dose on 5/9/21.
//

import UIKit


final class SaveButton: CircleButton {

    @IBInspectable var isActive: Bool = false
    
    enum States {
        case active
        case inActive
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        change(to: isActive ? .active : .inActive, animatable: false)
    }
    
    func change(to state: States, animatable: Bool = true) {
        animationClosure(animatable: animatable, duration: 0.3) {
            if case .active = state {
                self.backgroundColor = UIColor.mimoYellow500
            } else {
                self.backgroundColor = UIColor.mimoBlackWith01alpha
            }
        }
    }
}
