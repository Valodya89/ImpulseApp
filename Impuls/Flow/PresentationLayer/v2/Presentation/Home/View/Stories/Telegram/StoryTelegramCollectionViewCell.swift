//
//  StoryTelegramCollectionViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.10.23.
//

import UIKit

class StoryTelegramCollectionViewCell: BaseCollectionViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.backgroundColor = UIColor(red: 0.12, green: 0.44, blue: 0.73, alpha: 1)
        contentView.cornerRadius = 10
        contentView.addShadow(color: .black.withAlphaComponent(0.25), offset: .init(width: 0, height: 0), shadowRadius: 5)
    }

}
