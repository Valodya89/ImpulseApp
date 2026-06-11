//
//  CustomGestureView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 24.01.24.
//

import UIKit
import SwiftUI

class CustomGestureView: UIView {
    var onRightTap: (() -> Void)?
    var onLeftTap: (() -> Void)?
    var onLongPressBegan: (() -> Void)?
    var onLongPressEnded: (() -> Void)?
    
    let halfScreenViewLeft: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.1)
        return view
    }()
    
    let halfScreenViewRight: UIView = {
        let view = UIView()
        view.backgroundColor = .black.withAlphaComponent(0.1)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestures()
    }
    
    private func setupGestures() {
        self.isUserInteractionEnabled = false
        addSubview(halfScreenViewLeft)
        addSubview(halfScreenViewRight)

        halfScreenViewLeft.translatesAutoresizingMaskIntoConstraints = false
        
        //Place the top side of the view to the top of the screen
        halfScreenViewLeft.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        
        //Place the left side of the view to the left of the screen.
        halfScreenViewLeft.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor).isActive = true
        
        //Set the width of the view. The multiplier indicates that it should be half of the screen.
        halfScreenViewLeft.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5).isActive = true
        
        //Set the same height as the view´s height
        halfScreenViewLeft.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.55).isActive = true
        
        //We do the same for the right view
        
        //Enable Autolayout
        halfScreenViewRight.translatesAutoresizingMaskIntoConstraints = false
        
        //Place the top side of the view to the top of the screen
        halfScreenViewRight.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        
        //The left position of the right view depends on the position of the right side of the left view
        
        halfScreenViewRight.leadingAnchor.constraint(equalTo: halfScreenViewLeft.trailingAnchor).isActive = true
        
        //Place the right side of the view to the right of the screen.
        halfScreenViewRight.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor).isActive = true
        
        //Set the same height as the view´s height
        halfScreenViewRight.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 0.55).isActive = true
        
        
        let rightTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleRightTap))
        halfScreenViewRight.addGestureRecognizer(rightTapGesture)
        
        let leftTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLeftTap))
        halfScreenViewLeft.addGestureRecognizer(leftTapGesture)
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.1
        halfScreenViewLeft.addGestureRecognizer(longPressGesture)
        halfScreenViewRight.addGestureRecognizer(longPressGesture)
    }
    
    @objc private func handleRightTap() {
        onRightTap?()
    }
    
    @objc private func handleLeftTap() {
        onLeftTap?()
    }
    
    @objc private func handleLongPress(gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            onLongPressBegan?()
        }
        if gesture.state == .ended {
            onLongPressEnded?()
        }
    }
}

struct CustomGestureRepresentable: UIViewRepresentable {
    var onRightTap: () -> Void
    var onLeftTap: () -> Void
    var onLongPressBegan: () -> Void
    var onLongPressEnded: () -> Void
    
    func makeUIView(context: Context) -> CustomGestureView {
        let view = CustomGestureView()
        view.onRightTap = onRightTap
        view.onLeftTap = onLeftTap
        view.onLongPressBegan = onLongPressBegan
        view.onLongPressEnded = onLongPressEnded
        return view
    }
    
    func updateUIView(_ uiView: CustomGestureView, context: Context) {
        // Update the view if needed
    }
}
