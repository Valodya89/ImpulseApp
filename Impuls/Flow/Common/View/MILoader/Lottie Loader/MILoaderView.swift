//
//  CustomLottieView.swift
//  MIMO
//
//  Created by Dose on 3/30/20.
//

import UIKit
import Lottie

class MILoaderView: UIView {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var lottieView: UIView!
    @IBOutlet weak var message: UILabel!
    
    @IBOutlet weak var blurrer: UIVisualEffectView!
    @IBOutlet weak var waiter: UIActivityIndicatorView!
    @IBOutlet weak var tapper: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var progress: UIProgressView!
    
    private let topViewController = UIApplication.topController()
    var animationView = LottieAnimationView()
    
    @IBAction func tapped(_ sender: Any) {
        self.invisible()
    }
    
    @IBAction func settingsTaped(_ sender: Any) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                self.settingsButton.isHidden = true
            }
        } else {
            self.settingsButton.isHidden = true
        }
        
        self.invisible()

    }
    
    func invisible() {
        self.settingsButton.setTitle(self.settingsButton.currentTitle?.uppercased(), for: .normal)
        self.waiter.stopAnimating()
        self.progress.isHidden = true
        self.progress.progress = 0.0
        self.tapper.isHidden = true
        self.settingsButton.isHidden = true
        self.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.639, animations: {
            self.message.alpha = 0
            self.blurrer.alpha = 0
            self.contentView.alpha = 0
        }) { (completed) in
            if completed {
                self.message.isHidden = true
                self.message.text = ""
                self.blurrer.isHidden = true
                self.contentView.isHidden = true
            }
        }
    }
    
    override func awakeFromNib() {
        self.setupLottie()
        self.waiter.stopAnimating()
        self.waiter.hidesWhenStopped = true
        self.progress.trackTintColor = .white
        self.clipsToBounds = true
        self.invisible()
    }

    func setupLottie() {
        self.animationView = LottieAnimationView(name: "logo")
        animationView.frame = lottieView.bounds
        animationView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        lottieView.addSubview(animationView)
        animationView.loopMode = .loop
        animationView.play()
    }
    
    private func animateContent() {
        
        alpha = 0
        UIView.animate(withDuration: 0.2) {[weak self] in
            self?.alpha = 1.0
        }
    }
}

