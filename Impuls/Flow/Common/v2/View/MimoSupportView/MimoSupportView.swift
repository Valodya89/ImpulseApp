//
//  MimoSupportView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 13.08.23.
//

import UIKit

class MimoSupportView: UIView {
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet private weak var containerView: UIView!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("MimoSupportView", owner: self)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        containerView.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
    }
    
    @IBAction private func supportAction() {
        let telegramURL = URL(string: "tg://resolve?domain=MimoReview")!
        if UIApplication.shared.canOpenURL(telegramURL) {
            UIApplication.shared.open(telegramURL)
        }
    }
}
