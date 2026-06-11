//
//  ChargerDiscountsTableViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 09.03.24.
//

import UIKit

class ChargerDiscountsTableViewCell: BaseTableViewCell {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var discountIcon: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.addShadow(color: .black.withAlphaComponent(0.3), offset: .init(width: 0, height: 2), shadowRadius: 4)
        selectionStyle = .none
    }
    
    func set(data: ChargerDiscount) {
        titleLabel.text = data.title
        descriptionLabel.text = data.description
        discountIcon.image = data.icon
    }
}
