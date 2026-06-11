//
//  MarkedGradidentView.swift
//  MimoBike
//
//  Created by Dose on 6/11/21.
//

import UIKit

final class MarkedCornersView: GradientFillView {
    
    @IBInspectable var minXMinYCorner: Bool = true
    @IBInspectable var maxXMinYCorner: Bool = true
    @IBInspectable var minXMaxYCorner: Bool = true
    @IBInspectable var maxXMaxYCorner: Bool = true
//    @IBInspectable var cornerRadius: CGFloat = 0

    override func layoutSubviews() {
        super.layoutSubviews()
      
        var corners: [CACornerMask] = []
        
        if minXMaxYCorner {
            corners.append(.layerMinXMaxYCorner)
        }
        if minXMinYCorner {
            corners.append(.layerMinXMinYCorner)
        }
        if maxXMaxYCorner {
            corners.append(.layerMaxXMaxYCorner)
        }
        if maxXMinYCorner {
            corners.append(.layerMaxXMinYCorner)
        }
        
        layer.maskedCorners = .init(corners)
        layer.cornerRadius = cornerRadius
    }
}
