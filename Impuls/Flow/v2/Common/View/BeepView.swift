//
//  BeepView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.11.23.
//

import Foundation
import UIKit

class BeepView: UIView {
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1)
        view.cornerRadius = 20
        
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    private func commonInit() {
        isUserInteractionEnabled = false
        addSubview(containerView)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        let horizontalConstraint = NSLayoutConstraint(item: containerView, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let verticalConstraint = NSLayoutConstraint(item: containerView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: -150)
        let widthConstraint = NSLayoutConstraint(item: containerView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 105)
        let heightConstraint = NSLayoutConstraint(item: containerView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 105)
        
        addConstraints([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
        
        let bellImageView = UIImageView(image: UIImage(systemName: "bell.and.waves.left.and.right"))
        bellImageView.translatesAutoresizingMaskIntoConstraints = false
        bellImageView.contentMode = .scaleAspectFit
        bellImageView.tintColor = .black
        containerView.addSubview(bellImageView)
        
        let horizontalConstraint1 = NSLayoutConstraint(item: bellImageView, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: containerView, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let verticalConstraint1 = NSLayoutConstraint(item: bellImageView, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: containerView, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
        let widthConstraint1 = NSLayoutConstraint(item: bellImageView, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 52)
        let heightConstraint1 = NSLayoutConstraint(item: bellImageView, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: nil, attribute: NSLayoutConstraint.Attribute.notAnAttribute, multiplier: 1, constant: 52)
        
        containerView.addConstraints([horizontalConstraint1, verticalConstraint1, widthConstraint1, heightConstraint1])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.removeFromSuperview()
        }
    }
}
