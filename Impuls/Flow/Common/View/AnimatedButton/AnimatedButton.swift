//
//  AnimatedButton.swift
//  MimoBike
//
//  Created by Dose on 6/12/21.
//

import UIKit
import Lottie

final class AnimatedButton: UIControl {
    
    @IBInspectable var playAnimation: Bool = false
    @IBInspectable var loopAnimation: Bool = false
    @IBInspectable var repeatCount: Double = 1
    @IBInspectable var animationName: String = ""
    
    @IBInspectable var circleCorners: Bool = false
    
    private var animationView: LottieAnimationView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if circleCorners {
            layer.cornerRadius =  min(frame.width, frame.height) / 2
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !animationName.isEmpty else { return }
        loadAnimation(with: animationName)
    }
    
    private func loadAnimation(with name: String) {
        let animation = LottieAnimationView(name: name)
        animation.contentMode = .scaleAspectFit
        addSubviewSizedConstraints(view: animation)
        animation.loopMode = .repeat(Float(repeatCount))

        if loopAnimation {
            animation.loopMode = .loop
        }
        
        if playAnimation {
            animation.play()
        }
        
        self.animationView = animation
    }
    
    func play() {
        animationView.play()
    }
    
    func stop() {
        animationView.stop()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        sendActions(for: .touchUpInside)
    }
    
}

final class AnimatedView: UIImageView {
    
    @IBInspectable var playAnimation: Bool = false
    @IBInspectable var loopAnimation: Bool = false
    @IBInspectable var repeatCount: Double = 1
    @IBInspectable var animationName: String = ""
    
    var didPlayRequestedCount: (()->())?
    
    var animationView: LottieAnimationView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard !animationName.isEmpty else { return }
        loadAnimation(with: animationName)
    }
    
    private func loadAnimation(with name: String) {
        let animation = LottieAnimationView(name: name)
        animation.contentMode = .scaleAspectFill
        addSubviewSizedConstraints(view: animation)
        animation.loopMode = .repeat(Float(repeatCount))

        if loopAnimation {
            animation.loopMode = .loop
        }
        
        if playAnimation {
            animation.play {[weak self] state in
                if state {
                    
                }
                self?.didPlayRequestedCount?()
            }
        }
        
        
        
        self.animationView = animation
    }
    
    func play() {
        animationView.play()
    }
    
    func stop() {
        animationView.stop()
    }
    
}
