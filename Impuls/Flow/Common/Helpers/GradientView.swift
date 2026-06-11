//
//  GradientView.swift
//  MimoBike
//
//  Created by Vardan on 14.05.21.
//

import UIKit

final class GradientView: UIView {
    
    var gradientLayer: CAGradientLayer = CAGradientLayer()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func fill(colorOne: UIColor, colorTwo: UIColor, cornerRadius: CGFloat) {
        let gradientLayer = self.gradientLayer
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = cornerRadius
        gradientLayer.colors = [colorOne.cgColor, colorTwo.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0)
    }
}
