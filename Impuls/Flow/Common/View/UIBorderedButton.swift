//
//  UIBorderedButton.swift
//  LazerApplication
//
//  Created by Dose on 5/23/20.
//  Copyright © 2020 Dose. All rights reserved.
//

import UIKit

final class UIBorderedButton: UIButton {
    
    @IBInspectable var cornerCircled: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    private func commonInit() {
        borderWidth = 1.5
        borderColor = #colorLiteral(red: 0.2078431373, green: 0.2078431373, blue: 0.2078431373, alpha: 1)
        cornerRadius = 5
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        addBorder()
    }
    
    private func addBorder() {
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
    }
}

final class UIBorderedView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    private func commonInit() {
        borderWidth = 1.5
        borderColor = #colorLiteral(red: 0.2078431373, green: 0.2078431373, blue: 0.2078431373, alpha: 1)
        cornerRadius = 5
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        addBorder()
    }
    
    private func addBorder() {
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
    }
}

