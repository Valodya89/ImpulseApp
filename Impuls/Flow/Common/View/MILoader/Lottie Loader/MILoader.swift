//
//  CustomLottie.swift
//  MIMO
//
//  Created by Albert Mnatsakanyan on 4/1/20.
//  Copyright © 2020 IMED APPS LLC. All rights reserved.
//

import UIKit

class MILoader: NSObject {
    
    static var isToast = false
    static private var supView: UIView?
    static private var customLottieView: MILoaderView!
    
    
    class func registerNotification() {
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { (notification) in
            
            MILoader.customLottieView.animationView.play()
            
        }
    }
    
    class func run(containerView: UIView?) {
        
        if let view = containerView {
            self.supView = view
            if let vc = Bundle.main.loadNibNamed("MILoaderView", owner: self, options: nil)?.first as? MILoaderView {
                self.customLottieView = vc
                self.customLottieView.frame = view.bounds
                view.addSubview(self.customLottieView)
                self.isToast = false
            }
        }
    }
    
    class func refresh() {
        if let inner = self.customLottieView, let outter = self.supView {
            inner.frame = outter.bounds
            outter.bringSubviewToFront(inner)
        }
    }    
    
    class func show(message: String = "", animated: Bool = true, blocking: Bool = true, touchable: Bool = false) {
        registerNotification()
        DispatchQueue.main.async {
            self.refresh()
            if let tView = self.customLottieView {
                self.isToast = true
                supView?.isUserInteractionEnabled = !blocking
                tView.isHidden = false
                tView.contentView.isHidden = false
                tView.message.text = message
                tView.message.isHidden = false
                tView.waiter.stopAnimating()
                tView.waiter.startAnimating()
                tView.message.text = "\(message)"
                tView.blurrer.isHidden = true
                tView.isUserInteractionEnabled = true
                tView.tapper.isHidden = false
                tView.isUserInteractionEnabled = false
                tView.settingsButton.isHidden = true
                
                UIView.animate(withDuration: 0.369) {
                    tView.blurrer.alpha = 1.0
                    tView.message.alpha = 1.0
                    tView.contentView.alpha = 1.0
                }
                
            }
        }
    }
        
        class func hide(on: Bool = false) {
            DispatchQueue.main.async {
                supView?.isUserInteractionEnabled = true
                
                if on {
                    if let tView = self.customLottieView {
                        if tView.message.text != NSLocalizedString("offline", comment: "") {
                            return
                        }
                    }
                }
                if let tView = self.customLottieView {
                    UIApplication.topController()?.view.subviews.first(where: {$0 is MILoaderView})?.removeFromSuperview()
                    self.isToast = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.162) {
                        tView.invisible()
                    }
                }
            }
        }
    }
    
    class Haptics {
        static let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
        static let feedbackGenerator = UINotificationFeedbackGenerator()
        static let selectionGenerator = UISelectionFeedbackGenerator()
        class func hapt() {
            self.impactGenerator.impactOccurred()
        }
        class func warning() {
            self.feedbackGenerator.notificationOccurred(.warning)
        }
        class func success() {
            self.feedbackGenerator.notificationOccurred(.success)
        }
        class func error() {
            self.feedbackGenerator.notificationOccurred(.error)
        }
    }
