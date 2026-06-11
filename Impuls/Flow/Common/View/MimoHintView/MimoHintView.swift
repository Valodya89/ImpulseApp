//
//  MimoHintView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 05.05.23.
//

import Foundation

class MimoHintView: MimoNibInstantiatableView {
    
    @IBOutlet private weak var blureView: UIView!
    @IBOutlet private weak var hintTextView: UITextView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        blureView.alpha = 0.8
        
        let paragraphStyle: NSMutableParagraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = NSTextAlignment.center
        
        let demoText = "MOBILE_demo_info".localized()
        let supportPart = (demoText as NSString).range(of: "Mimo Support")
        let attributedString = NSMutableAttributedString(string: demoText, attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle,
                                                                                        NSAttributedString.Key.font: UIFont(name: "Roboto", size: 15) as Any])
        attributedString.addAttribute(.link, value: "tg://resolve?domain=MimoReview", range: supportPart)
        hintTextView.attributedText = attributedString
    }
}
