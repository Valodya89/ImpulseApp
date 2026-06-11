//
//  HomePromoCollectionViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 06.06.23.
//

import UIKit

class HomePromoCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet private weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.addShadow(color: .mimoBlackWith025alpha)
    }
    
}
