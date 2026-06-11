//
//  AlertController.swift
//  MimoBike
//
//  Created by Dose on 6/3/21.
//

import UIKit

final class AlertController: UIView {
    
    private static var visibiltyControll: [(parent: UIViewController, alert: AlertController)] = []
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var alertImageView: UIImageView!
    @IBOutlet weak var contentVisualEffect: UIVisualEffectView!
    
    private var visualEffect: UIVisualEffectView?
    fileprivate(set) var dismissOnTouch: Bool = false
    
    var didDismiss: (() -> ())?
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
 
    private func commonInit() {
        loadFromNib()
        insertTapGesture()
        
        contentVisualEffect.alpha = 0.8
    }
    
    func configUI(with title: String?, message: String?, image: UIImage) {
        messageLabel.isHidden = message == nil
        messageLabel.text = message
        titleLabel.isHidden = title == nil
        alertImageView.image = image
        titleLabel.text = title
        prefetchVisualEffect(0.3)
        zoomInContent(0.3)
    }
    
    func removeContent() {
        defetchVisualEffect(0.3)
        zoomOutContent(0.3, {[weak self] _ in
            self?.removeFromSuperview()
            self?.didDismiss?()
        })
    }
    
    private func insertTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTouchContext(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    private func zoomInContent(_ duration: Double) {
        self.alpha = 0
        self.contentView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        UIView.animate(withDuration: duration) {
            self.alpha = 1
            self.contentView.transform = CGAffineTransform.identity
        }
    }
    
    private func zoomOutContent(_ duration: Double, _ completion: ((Bool)->())?) {
        self.contentView.transform = CGAffineTransform.identity
        self.alpha = 1
        UIView.animate(withDuration: duration, animations: {
            self.contentView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.alpha = 0
        }, completion: completion)
    }
    
    private func prefetchVisualEffect(_ duration: Double) {
        let visiualEffect = UIVisualEffectView(effect: .none)
        self.addSubviewSizedConstraints(view: visiualEffect, atIndex: 0)
        self.visualEffect = visiualEffect
        UIView.animate(withDuration: duration) {
            visiualEffect.alpha = 0.6
            visiualEffect.effect = UIBlurEffect(style: .dark)
        }
    }
    
    private func defetchVisualEffect(_ duration: Double) {
        UIView.animate(withDuration: duration, animations: {
            self.visualEffect?.effect = nil
        })
    }
    
    @objc private func didTouchContext(_ sender: UITapGestureRecognizer) {
        if dismissOnTouch {
            removeContent()
        }
    }
}

extension AlertController {
    
    static func show(title: String?, message: String?, image: UIImage, in controller: UIViewController, dismissOnTouch: Bool, dismissed: (() -> ())? = nil) {
        let alertController = AlertController(frame: controller.view.bounds)
        alertController.configUI(with: title, message: message, image: image)
        alertController.dismissOnTouch = dismissOnTouch
        alertController.didDismiss  = dismissed
        controller.view.addSubviewSizedConstraints(view: alertController)
        visibiltyControll.append((controller, alertController))
    }
    
    static func dismissLast(from controller: UIViewController) {
        visibiltyControll.reversed().first(where: {$0.parent === controller})?.alert.removeContent()
    }
    
    static func dismissFirst(from controller: UIViewController) {
        visibiltyControll.first(where: {$0.parent === controller})?.alert.removeContent()
    }

    static func dismiss(from controller: UIViewController) {
        visibiltyControll.forEach { item in
            if item.parent === controller {
                item.alert.removeContent()
            }
        }
    }
    
}
