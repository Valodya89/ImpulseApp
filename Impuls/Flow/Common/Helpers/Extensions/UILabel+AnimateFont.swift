//
//  UILabel+AnimateFont.swift
//  Management App
//
//  Created by Vardan on 9/3/20.
//

import UIKit
import QuartzCore

struct LabelAnimateAnchorPoint {
  static let leadingCenterY         = CGPoint.init(x: 0, y: 0.5)
  static let trailingCenterY        = CGPoint.init(x: 1, y: 0.5)
  static let centerXCenterY         = CGPoint.init(x: 0.5, y: 0.5)
  static let leadingTop             = CGPoint.init(x: 0, y: 0)
}

extension UILabel {
    
    /// Animate label font size
    /// - Parameters:
    ///   - fontSize: New font size
    ///   - duration: Animation duration
    ///   - animateAnchorPoint: Last state anchor point (default is centerXCenterY)
    func scale(fontSize: CGFloat, duration: TimeInterval, animateAnchorPoint: CGPoint = LabelAnimateAnchorPoint.centerXCenterY) {
    let startTransform = transform
    let oldFrame = frame
    var newFrame = oldFrame
    let archorPoint = layer.anchorPoint
    let scaleRatio = fontSize / font.pointSize

    layer.anchorPoint = animateAnchorPoint

    newFrame.size.width *= scaleRatio
    newFrame.size.height *= scaleRatio
    newFrame.origin.x = oldFrame.origin.x - (newFrame.size.width - oldFrame.size.width) * animateAnchorPoint.x
    newFrame.origin.y = oldFrame.origin.y - (newFrame.size.height - oldFrame.size.height) * animateAnchorPoint.y
    frame = newFrame

    font = font.withSize(fontSize)

    transform = CGAffineTransform.init(scaleX: 1 / scaleRatio, y: 1 / scaleRatio);
    layoutIfNeeded()
        
    UIView.animate(withDuration: duration, animations: {
      self.transform = startTransform
      newFrame = self.frame
    }) { (Bool) in
      self.layer.anchorPoint = archorPoint
    }
  }
    
    func animateColor(to color: UIColor, duration: Double) {
        let textLayer = CATextLayer()
        textLayer.foregroundColor = textColor.cgColor
        
        textLayer.frame = layer.bounds
        textLayer.string = text
        layer.addSublayer(textLayer)
        let animation1 = CABasicAnimation(keyPath: "foregroundColor")
        animation1.toValue = color.cgColor
        animation1.duration = duration
        layer.add(animation1, forKey: "label")

    }
}


