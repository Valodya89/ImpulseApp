//
//  MultiTransportPlusCollectionViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.06.23.
//

import UIKit

class MultiTransportPlusCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet private weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.addShadow(color: .black, offset: CGSize(width: 0, height: 2), opacity: 0.24, shadowRadius: 6)
    }

}
