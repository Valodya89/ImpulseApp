//
//  MimoImportantView.swift
//  Mimo
//
//  Created by Vardan on 29.05.21.
//

import UIKit

final class MimoImportantView: UIView {
    
    @IBOutlet weak var mediaView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var mediaViewLeftConstraint: NSLayoutConstraint!
    
        
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public func commonInit(isSuccess: Bool, title: String?, message: String) {

        titleLabel.font = UIFont(name: Constant.Font.robotoBold, size: 24)
        if isSuccess {
            mediaViewLeftConstraint.constant = Constant.Width.width79
            imageView.image = #imageLiteral(resourceName: "ic_POP_UP_chekmark")
            titleLabel.text = title ?? "Thank you"
            messageLabel.font = UIFont(name: Constant.Font.robotoBold, size: 15)
            messageLabel.text = message
        } else {
            mediaViewLeftConstraint.constant =  Constant.Width.width68
            imageView.image = #imageLiteral(resourceName: "ic_POP_UP_credit_card")
            titleLabel.text = title ?? "Insufficient account"
            messageLabel.font = UIFont(name: Constant.Font.robotoBold, size: 15)
            messageLabel.text = message
        }
    }
}
