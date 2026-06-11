//
//  MimoToggleButton.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 26.11.23.
//

import Foundation
import UIKit

class MimoToggleButton: UILocalizedButton {
    
    @IBInspectable
    var normalBackgroundColor: UIColor = .clear {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    @IBInspectable
    var selectedBackgroundColor: UIColor = .black {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundColor = isSelected ? selectedBackgroundColor : normalBackgroundColor
    }
}
