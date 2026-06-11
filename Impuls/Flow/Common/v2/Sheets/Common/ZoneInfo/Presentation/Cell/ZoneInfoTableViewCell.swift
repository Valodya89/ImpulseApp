//
//  ZoneInfoTableViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 19.07.23.
//

import UIKit

class ZoneInfoTableViewCell: BaseTableViewCell {
    
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    
    @IBOutlet private weak var titleLableTopConstraint: NSLayoutConstraint!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
    
    func set(zoneInfo: ZoneInfo) {
        titleLabel.text = zoneInfo.title
        descriptionLabel.text = zoneInfo.description.trimmingCharacters(in: .whitespaces)
        titleLableTopConstraint.constant = 8
        
        switch zoneInfo.id {
        case "Parking":
            iconImageView.image = "parking_nim".image
            titleLableTopConstraint.constant = 12
        case "RIDE":
            iconImageView.image = "riding".image
        case "FORBIDDEN":
            iconImageView.image = "noRiding".image
        case "RESTRICTED":
            iconImageView.image = "speedLimit".image
        default:
            break
        }
    }
}
