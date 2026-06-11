//
//  BikeTariffTableViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.11.23.
//

import UIKit

protocol BikeTariffTableViewCellDelegate: AnyObject {
    func didSelectActivateStudent(for cell: BikeTariffTableViewCell)
}

class BikeTariffTableViewCell: BaseTableViewCell {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var description1Label: UILabel!
    @IBOutlet private weak var description2Label: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var activateButtonContainerView: UIView!
    
    weak var delegate: BikeTariffTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.addShadow(color: .black.withAlphaComponent(0.3), offset: .init(width: 0, height: 2), shadowRadius: 4)
        selectionStyle = .none
    }
    
    func set(tariff: TariffModel) {
        nameLabel.text = tariff.name
        priceLabel.text = tariff.priceName
        activateButtonContainerView.isHidden = !tariff.activable
        iconImageView.sd_setImage(with: tariff.logo.imageURL)
        
        if let extendedDetails = tariff.extendedDetails {
            let sortedDetails = extendedDetails.sorted(by: { $0.order < $1.order })
            var description1 = sortedDetails.compactMap({ "\($0.name)\n" }).reduce("", +)
            var description2 = sortedDetails.compactMap({ "\($0.priceName)\n" }).reduce("", +)
            
            description1 = String(description1.replacingOccurrences(of: "\"", with: "").dropLast(1))
            description2 = String(description2.replacingOccurrences(of: "\"", with: "").dropLast(1))
            
            let paragraphStyle1 = NSMutableParagraphStyle()
            paragraphStyle1.lineSpacing = 6
            
            let attributedString1 = NSMutableAttributedString(string: description1)
            attributedString1.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle1, range: NSMakeRange(0, attributedString1.length))
            
            let paragraphStyle2 = NSMutableParagraphStyle()
            paragraphStyle2.lineSpacing = 6
            paragraphStyle2.alignment = .right
            
            let attributedString2 = NSMutableAttributedString(string: description2)
            attributedString2.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle2, range: NSMakeRange(0, attributedString2.length))
            
            description1Label.attributedText = attributedString1
            description2Label.attributedText = attributedString2
        } else {
            description1Label.text = tariff.description
            description2Label.text = ""
        }
    }
    
    @IBAction private func activateAction() {
        delegate?.didSelectActivateStudent(for: self)
    }
}
