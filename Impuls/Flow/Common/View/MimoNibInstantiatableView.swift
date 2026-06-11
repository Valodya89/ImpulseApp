//
//  MimoNibInstantiatableView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 02.05.23.
//

import Foundation
import UIKit

class MimoNibInstantiatableView: UIView {
    
    var contentView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadViewFromNib()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        loadViewFromNib()
    }
    
    private func loadViewFromNib() {
        if let contentView = Bundle.main.loadNibNamed(String(describing: type(of: self)), owner: self)?.first as? UIView {
            self.contentView = contentView
            self.contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.contentView.frame = bounds
            addSubview(self.contentView)
        }
    }
}
