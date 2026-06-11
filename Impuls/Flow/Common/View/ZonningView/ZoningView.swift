//
//  ZoningView.swift
//  MimoBike
//
//  Created by Dose on 7/4/21.
//

import UIKit

final class ZoningView: UIView {
    
    @IBOutlet weak var animatedView: AnimatedView!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var contextView: UIView!
    @IBOutlet weak var contentTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var zoneDescriptionLabel: UILabel!

    override func removeFromSuperview() {
        hideContent { state in
            super.removeFromSuperview()
        }
    }
    
    private init() {
        super.init(frame: .zero)
    }
    
    required init?(coder: NSCoder) {
        fatalError("Doesnt support initialization with coder")
    }

    private func commonInit(_ freeMinutes: Int, parent: UIView) {
        loadFromNib()
        parent.addSubviewSizedConstraints(view: self)
        self.contentTopConstraint.constant = 0
        layoutIfNeeded()

        var zoneDescription: String = "MOBILE_zone_bonus".localized()
        
        zoneDescription = zoneDescription.replacingOccurrences(of: "[minutes]", with: String(freeMinutes))
        let range = zoneDescription.range(of: String(freeMinutes))!
        
        let attributedString = NSMutableAttributedString(string: zoneDescription, attributes: [NSAttributedString.Key.font: UIFont(name: "Roboto-light", size: 15)!, NSAttributedString.Key.foregroundColor: UIColor.mimoBlackWith05alpha.cgColor])
        attributedString.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.mimoBlackWith075alpha, NSAttributedString.Key.font: UIFont(name: "Roboto-medium", size: 15)!], range: NSRange(range, in: zoneDescription))
        zoneDescriptionLabel.attributedText = attributedString
    }
    
    private func showContent() {

        self.contentTopConstraint.constant = -self.contextView.frame.height
        shadowView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.shadowView.alpha = 1
            self.layoutIfNeeded()
        }
    }
    
    private func hideContent(_ completion: ((Bool)->())?) {
        self.contentTopConstraint.constant = 0
        shadowView.alpha = 1
        UIView.animate(withDuration: 0.3, animations: {
            self.shadowView.alpha = 0
            self.layoutIfNeeded()
        }, completion: completion)
    }
    
    static func show(with minutes: Int) {
        guard let parentController = UIApplication.topController(), let window = parentController.view.window else { return }
        let zoneView = ZoningView()
        zoneView.commonInit(minutes, parent: window)
        zoneView.layoutIfNeeded()
        window.layoutIfNeeded()
        zoneView.showContent()
        
        NotificationCenter.default.addObserver(zoneView, selector: #selector(updateAnimation), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    @IBAction func removeContent() {
        removeFromSuperview()
    }
    
    @objc func updateAnimation() {
        animatedView.play()
    }
}

