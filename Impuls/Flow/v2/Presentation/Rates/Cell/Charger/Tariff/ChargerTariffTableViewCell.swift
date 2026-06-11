//
//  ChargerTariffTableViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 26.11.23.
//

import UIKit

class ChargerTariffTableViewCell: BaseTableViewCell {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var indexLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.addShadow(color: .black.withAlphaComponent(0.3), offset: .init(width: 0, height: 2), shadowRadius: 4)
        selectionStyle = .none
    }
    
    func set(data: ChargerTariff) {
        indexLabel.text = "\(data.order)"
        titleLabel.text = data.title
        descriptionLabel.text = data.description
        amountLabel.text = data.priceName
    }
}
