//
//  GradientView.swift
//  LazerApplication
//
//  Created by Dose on 13/12/2019.
//  Copyright © 2019 Dose. All rights reserved.
//

import UIKit

class GradientFillView: UIView {
    private weak var gradientLayer: CAGradientLayer!

    @IBInspectable var isCyrcle: Bool = false {
        didSet {
            layoutSubviews()
        }
    }

    @IBInspectable var topColor: UIColor = .red {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable var bottomColor: UIColor = .yellow {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable override var shadowColor: UIColor {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable var shadowX: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable var shadowY: CGFloat = -3 {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable var shadowBlur: CGFloat = 3 {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable var startPointX: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable var startPointY: CGFloat = 0.5 {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable var endPointX: CGFloat = 1 {
        didSet {
            setNeedsLayout()
        }
    }

    @IBInspectable var endPointY: CGFloat = 0.5 {
        didSet {
            setNeedsLayout()
        }
    }
    
  
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        gradientLayer = layer as? CAGradientLayer
        gradientLayer.colors = [topColor.cgColor, bottomColor.cgColor]
        gradientLayer.startPoint = CGPoint(x: startPointX, y: startPointY)
        gradientLayer.endPoint = CGPoint(x: endPointX, y: endPointY)
        shadowColor = .clear
        
        layer.shadowColor = shadowColor.cgColor
        layer.shadowOffset = CGSize(width: shadowX, height: shadowY)
        layer.shadowRadius = shadowBlur
        layer.shadowOpacity = 1
        layer.shadowPath = CGPath(roundedRect: bounds, cornerWidth: layer.cornerRadius, cornerHeight: layer.cornerRadius, transform: nil)
        if isCyrcle {
            layer.cornerRadius = min(bounds.width, bounds.height) / 2
        }
    }

    public func setColors(topColor: UIColor = .white, bottomColor: UIColor = .white, shadowColor: UIColor = #colorLiteral(red: 0.7294117647, green: 0.7215686275, blue: 0.7764705882, alpha: 0.34), shadowBlur: CGFloat = 20.0, shadowOffset: CGPoint) {
        self.topColor = topColor
        self.bottomColor = bottomColor
        self.shadowColor = shadowColor
        self.shadowBlur = shadowBlur
        shadowY = shadowOffset.y
        shadowX = shadowOffset.x
    }

    func animate(duration: TimeInterval, newTopColor: UIColor, newBottomColor: UIColor) {
        let fromColors = gradientLayer?.colors
        let toColors: [AnyObject] = [newTopColor.cgColor, newBottomColor.cgColor]
        gradientLayer?.colors = toColors
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = fromColors
        animation.toValue = toColors
        animation.duration = duration
        animation.isRemovedOnCompletion = true
        animation.fillMode = .forwards
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        gradientLayer?.add(animation, forKey: "animateGradient")
    }
}
extension UIView {
    class func fromNib<T: UIView>() -> T {
        return Bundle(for: T.self).loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}

extension UIView {
    func makeClearViewWithShadow(
        cornderRadius: CGFloat,
        shadowColor: CGColor,
        shadowOpacity: Float,
        shadowRadius: CGFloat
    ) {
        frame = frame.insetBy(dx: -shadowRadius * 2,
                              dy: -shadowRadius * 2)
        backgroundColor = .clear
        let shadowView = UIView(frame: CGRect(
            x: shadowRadius * 2,
            y: shadowRadius * 2,
            width: frame.width - shadowRadius * 4,
            height: frame.height - shadowRadius * 4
        ))
        shadowView.backgroundColor = .black
        shadowView.layer.cornerRadius = cornderRadius
        shadowView.layer.borderWidth = 1.0
        shadowView.layer.borderColor = UIColor.clear.cgColor

        shadowView.layer.shadowColor = shadowColor
        shadowView.layer.shadowOpacity = shadowOpacity
        shadowView.layer.shadowRadius = shadowRadius
        shadowView.layer.masksToBounds = false
        addSubview(shadowView)

        let p: CGMutablePath = CGMutablePath()
        p.addRect(bounds)
        p.addPath(UIBezierPath(roundedRect: shadowView.frame, cornerRadius: shadowView.layer.cornerRadius).cgPath)

        let s = CAShapeLayer()
        s.path = p
        s.fillRule = CAShapeLayerFillRule.evenOdd

        layer.mask = s
    }
}

extension UIViewController {
    
    func addGradientAnimation(_ view: UIView) {
        
       let gradient = CAGradientLayer()
        var gradientSet = [[CGColor]]()
        var currentGradient: Int = 0
        
        
        let gradientOne: CGColor?
        let gradientTwo: CGColor?
        let gradientThree: CGColor?
        let gradientFour: CGColor?
        
        gradientOne = UIColor(red: 255/255, green: 235/255, blue: 59/255, alpha: 1).cgColor // yel
        gradientTwo = UIColor(red: 0, green: 11/255, blue: 117/255, alpha: 1).cgColor // blue
        gradientThree = UIColor(red: 34/255, green: 77/255, blue: 217/255, alpha: 1).cgColor// vbet
        gradientFour = UIColor(red: 37/255, green: 20/255, blue: 59/255, alpha: 1).cgColor// purple
        gradientSet.append([gradientThree!, gradientOne!]) // , gradientFour!
        gradientSet.append([ gradientOne!, gradientThree!]) // gradientFour!,
        
        gradient.frame = view.bounds
        gradient.colors = gradientSet[currentGradient]
        gradient.startPoint = CGPoint(x:1, y:1)
        gradient.endPoint = CGPoint(x:1, y:1)
        gradient.drawsAsynchronously = true
        view.layer.addSublayer(gradient)
        
        if currentGradient < gradientSet.count - 1 {
            currentGradient += 1
        } else {
            currentGradient = 0
        }
        
        let gradientChangeAnimation = CABasicAnimation(keyPath: "colors")
        gradientChangeAnimation.duration = 5.4
        gradientChangeAnimation.toValue = gradientSet[currentGradient]
        gradientChangeAnimation.fillMode = CAMediaTimingFillMode.forwards
        gradientChangeAnimation.isRemovedOnCompletion = false
        gradientChangeAnimation.autoreverses = true
        gradientChangeAnimation.repeatCount = 100000000
        gradient.add(gradientChangeAnimation, forKey: "colorChange")
    }
   
}


extension UIView {
    func setGradientBacgroundWithTwoColors(colorOne: UIColor, colorTwo: UIColor, cornerRadius: CGFloat) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = cornerRadius
        gradientLayer.colors = [colorOne.cgColor, colorTwo.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.25, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 0.75, y: 0.5)
        
        self.layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func setGradientBacgroundBottomToTop(colorOne: UIColor, colorTwo: UIColor, cornerRadius: CGFloat) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = cornerRadius
        gradientLayer.colors = [colorOne.cgColor, colorTwo.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0)
        
        layer.insertSublayer(gradientLayer, at: 0)
    }

}
