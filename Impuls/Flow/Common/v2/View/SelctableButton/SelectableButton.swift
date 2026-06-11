//
//  SelectableButton.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 02.06.23.
//

import Foundation
import UIKit

class SelectableButton: UIButton {
    
    @IBInspectable
    var selectedBackgroundColor: UIColor = .clear {
        didSet {
            setNeedsLayout()
        }
    }
    
    @IBInspectable
    var normalBackgroundColor: UIColor = .clear {
        didSet {
            setNeedsLayout()
        }
    }
    
    @IBInspectable
    var selectedBorderColor: UIColor = .clear {
        didSet {
            setNeedsLayout()
        }
    }
    
    var isChecked: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if isChecked {
            self.backgroundColor = selectedBackgroundColor
            self.borderColor = selectedBorderColor
            self.borderWidth = 2
        } else {
            self.backgroundColor = normalBackgroundColor
            self.borderColor = .clear
            self.borderWidth = 0
        }
        
        tintColor = .clear
    }
}
