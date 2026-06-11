//
//  UIView+AddSubviewWithConstraints.swift
//  Management App
//
//  Created by Vardan on 8/27/20.
//

import UIKit

extension UIView {
    
    func addSubviewSizedConstraints(view: UIView, atIndex: Int? = nil) {
    
        if let index = atIndex {
            insertSubview(view, at: index)
        } else {
            addSubview(view)
        }
        view.translatesAutoresizingMaskIntoConstraints = false
        view.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        view.topAnchor.constraint(equalTo: topAnchor).isActive = true
        view.setNeedsLayout()
    
        
    }
}
