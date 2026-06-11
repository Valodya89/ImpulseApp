//
//  BikePackageTableViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.11.23.
//

import UIKit

protocol BikePackageTableViewCellDelegate: AnyObject {
    func didSelectBikePackageActivate(for cell: BikePackageTableViewCell)
}

class BikePackageTableViewCell: BaseTableViewCell {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    @IBOutlet private weak var feeTitleLabel: UILabel!
    @IBOutlet private weak var feeAmountLabel: UILabel!
    @IBOutlet private weak var ridesLabel: UILabel!
    
    weak var delegate: BikePackageTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        containerView.addShadow(color: .black.withAlphaComponent(0.3), offset: .init(width: 0, height: 2), shadowRadius: 4)
    }
    
    func set(package: PackageModel) {
        nameLabel.text = package.localizedName
        feeAmountLabel.text = String(format: "%.2f \("MOBILE_global_total_currency".localized())", package.price)
        ridesLabel.text = package.description
        iconImageView.sd_setImage(with: package.logo.imageURL)
        feeTitleLabel.text = "\(package.name.capitalized) fee"
    }
    
    @IBAction private func activateAction() {
        delegate?.didSelectBikePackageActivate(for: self)
    }
}
