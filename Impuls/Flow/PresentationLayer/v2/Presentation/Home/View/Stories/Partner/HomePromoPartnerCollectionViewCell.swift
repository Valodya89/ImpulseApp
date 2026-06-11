//
//  HomePromoPartnerCollectionViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 06.06.23.
//

import UIKit

class HomePromoPartnerCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet private weak var containerView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.addShadow(color: .black)
    }

}
