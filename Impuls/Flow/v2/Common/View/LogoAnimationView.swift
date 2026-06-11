//
//  LogoAnimationView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 16.09.23.
//

import SwiftUI
import Lottie

struct LogoAnimationView: UIViewRepresentable {
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView(name: Constant.Lottie.logo)
        animationView.loopMode = .loop
        animationView.play(fromProgress: animationView.currentProgress, toProgress: 1, loopMode: .loop)
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}
