//
//  StoryPartnershipCollectionViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.10.23.
//

import UIKit

class StoryPartnershipCollectionViewCell: BaseCollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.cornerRadius = 10
        contentView.addShadow(color: .black.withAlphaComponent(0.25), offset: .init(width: 0, height: 0), shadowRadius: 5)
    }

}
