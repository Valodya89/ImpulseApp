//
//  UIView.swift
//  MimoBike
//
//  Created by Vardan on 20.04.21.
//

import UIKit

extension UIView {
    
    /// shake animation
    func shake() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        layer.add(animation, forKey: "shake")
    }
    
    /// add to view shadow 4 sides
    func addShadow(color: UIColor, offset: CGSize = .init(width: 0.5, height: 1), opacity: Float = 0.5, shadowRadius: CGFloat = 5) {
        self.layer.shadowColor = color.cgColor
//        self.layer.shadowOffset = CGSize(width: 0.5, height: 1)
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = shadowRadius
        self.layer.shadowOffset = offset
        self.layer.masksToBounds = false
    }
    
    /// add gradient view from bottom to top
    func setGradientBackgroundBottomToTop(colorOne: UIColor, colorTwo: UIColor, cornerRadius: CGFloat) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.cornerRadius = cornerRadius
        gradientLayer.colors = [colorOne.cgColor, colorTwo.cgColor]
        gradientLayer.locations = [0.0, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0)
        
        if var layerGradient = layer.sublayers?.first(where: {$0 is CAGradientLayer}) {
            print(layerGradient)
            layerGradient = gradientLayer
        } else {
            layer.addSublayer(gradientLayer)
        }
    }
    
    func animatePositionY(to pointY: CGFloat, duration: Double = 0.3, completion: (()->())? = nil) {
        CATransaction.begin()
        let yPositionAnimation = CABasicAnimation(keyPath: "position.y")
        yPositionAnimation.fromValue = layer.presentation()?.position.y
        yPositionAnimation.toValue = pointY
        yPositionAnimation.fillMode = .forwards
        yPositionAnimation.isRemovedOnCompletion = false
        yPositionAnimation.duration = duration
        yPositionAnimation.timingFunction = CAMediaTimingFunction(controlPoints: 0.215, 0.61, 0.355, 1)
        CATransaction.setCompletionBlock(completion)
        layer.add(yPositionAnimation, forKey: "transform.position.y")
        CATransaction.commit()
    }

    func setMask(with hole: CGRect, cornerRadius: CGFloat) {
        
        // Create a mutable path and add a rectangle that will be h
        let mutablePath = CGMutablePath()
        mutablePath.addRect(self.bounds)
        mutablePath.addRoundedRect(in: hole, cornerWidth: cornerRadius, cornerHeight: cornerRadius)
        // Create a shape layer and cut out the intersection
        let mask = CAShapeLayer()
        mask.path = mutablePath
        mask.fillRule = CAShapeLayerFillRule.evenOdd
        mask.backgroundColor = UIColor.mimoYellow100.cgColor
        // Add the mask to the view
        self.layer.mask = mask
        
    }
    
    class func initFromNib<T: UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: self), owner: nil, options: nil)?[0] as! T
    }
}

extension UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat {
        get { layer.cornerRadius }
        set { layer.cornerRadius = newValue }
    }
    
    @IBInspectable
    var borderWidth: CGFloat {
        get { layer.borderWidth }
        set { layer.borderWidth = newValue }
    }
    
    @IBInspectable
    var borderColor: UIColor {
        get { layer.borderColor != nil ? UIColor(cgColor: layer.borderColor!) : .black }
        set { layer.borderColor = newValue.cgColor }
    }
    
    @IBInspectable var shadowOffset: CGSize {
        get { return self.layer.shadowOffset }
        set { self.layer.shadowOffset = newValue }
    }
    
    @IBInspectable var shadowColor: UIColor {
        get { return UIColor(cgColor: self.layer.shadowColor ?? UIColor.blue.cgColor) }
        set { self.layer.shadowColor = newValue.cgColor }
    }
    
    @IBInspectable var shadowRadius: CGFloat {
        get { return self.layer.shadowRadius }
        set { self.layer.shadowRadius = newValue }
    }
    
    @IBInspectable var shadowOpacity: Float {
        get { return self.layer.shadowOpacity }
        set { self.layer.shadowOpacity = newValue }
    }
}

extension UIView {
    
    func fadeIn(duration: TimeInterval = 0.2, delay: TimeInterval = 0.0, completion: @escaping ((Bool) -> Void) = {(finished: Bool) -> Void in }) {
        self.alpha = 0.0
        
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.isHidden = false
            self.alpha = 1.0
        }, completion: completion)
    }
    
    func fadeOut(duration: TimeInterval = 0.2, delay: TimeInterval = 0.0, completion: @escaping (Bool) -> Void = {(finished: Bool) -> Void in }) {
        self.alpha = 1.0
        
        UIView.animate(withDuration: duration, delay: delay, options: UIView.AnimationOptions.curveEaseIn, animations: {
            self.alpha = 0.0
        }) { (completed) in
            self.isHidden = true
            completion(true)
        }
    }
}

extension UIView {
    func addOverlay(frame: CGRect, xOffset: CGFloat, yOffset: CGFloat, size: CGSize, tag: Int = 999) {
        // Step 1
        let overlayView = UIView(frame: frame)
        overlayView.tag = tag
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        // Step 2
        let path = CGMutablePath()
        let path2 = CGMutablePath(roundedRect: CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: size),
                                  cornerWidth: 12,
                                  cornerHeight: 12,
                                  transform: nil)
//        path.addRect(CGRect(origin: CGPoint(x: xOffset, y: yOffset), size: size))
        path.addRect(CGRect(origin: .zero, size: overlayView.frame.size))
        // Step 3
        let maskLayer = CAShapeLayer()
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.path = path
        maskLayer.fillRule = .evenOdd
        // Step 4
        overlayView.layer.mask = maskLayer
        overlayView.clipsToBounds = true

        insertSubview(overlayView, at: 0)
    }
}

extension UIView {

    var safeAreaBottom: CGFloat {
        if let window = UIApplication.shared.keyWindowInConnectedScenes {
            return window.safeAreaInsets.bottom
        }
        
        return 0
    }
    
    var safeAreaTop: CGFloat {
        if let window = UIApplication.shared.keyWindowInConnectedScenes {
            return window.safeAreaInsets.top
        }
        
        return 0
    }
}
