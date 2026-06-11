//
//  ActionButton.swift
//  MimoBike
//
//  Created by Dose on 6/4/21.
//

import UIKit


final class ActionButton: CircleButton {
    
    @IBInspectable var isActive: Bool = false {
        didSet { needsUpdate() }
    }
    
    var backgroundLayer: CALayer!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        backgroundLayer.cornerRadius = layer.cornerRadius
        backgroundLayer.frame = bounds
    }
    
    override func awakeFromNib() {
        backgroundLayer = CALayer()
        backgroundLayer?.backgroundColor = isActive ? UIColor.mimoYellow500.cgColor : UIColor.mimoBlackWith025alpha.cgColor
        layer.backgroundColor = UIColor.mimoGray100.cgColor
        layer.insertSublayer(backgroundLayer, at: 0)
        titleLabel?.font = UIFont(name: "Roboto-bold", size: 15)
        setTitleColor(.black, for: .normal)
        setTitle(localizedTitle?.localized(), for: .normal)
        setTitle(localizedTitle?.localized(), for: .disabled)

        contentEdgeInsets = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)
        super.awakeFromNib()

        self.alpha = 1 
    }
    
    private func needsUpdate() {
        backgroundLayer?.backgroundColor = isActive ? UIColor.mimoYellow500.cgColor : UIColor.mimoBlackWith025alpha.cgColor
        isEnabled = isActive
    }
    
}
