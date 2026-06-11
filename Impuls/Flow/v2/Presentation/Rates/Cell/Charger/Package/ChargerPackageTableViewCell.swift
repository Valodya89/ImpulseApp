//
//  ChargerPackageTableViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 09.03.24.
//

import UIKit

protocol ChargerPackageTableViewCellDelegate: AnyObject {
    func didSelectActivatePackage(for cell: ChargerPackageTableViewCell)
}

class ChargerPackageTableViewCell: BaseTableViewCell {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var popularView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var activatedView: UIView!
    @IBOutlet private weak var activateButton: UIButton!
    
    weak var delegate: ChargerPackageTableViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.addShadow(color: .black.withAlphaComponent(0.3), offset: .init(width: 0, height: 2), shadowRadius: 4)
        selectionStyle = .none
    }
    
    func set(data: ChargerPackage, isActivated: Bool) {
        popularView.isHidden = !data.popular || isActivated
        titleLabel.text = data.localizedName
        amountLabel.text = data.priceName
        descriptionLabel.text = data.description
        activatedView.isHidden = !isActivated
        containerView.borderWidth = isActivated ? 2 : 0
        containerView.borderColor = isActivated ? UIColor.mimoYellow500 : .clear
        
        activateButton.backgroundColor = isActivated ? UIColor.clear : UIColor.mimoYellow500
        activateButton.setTitle(isActivated ? "MOBILE_charger_package_activated".localized() : "MOBILE_charger_package_activate".localized(), for: .normal)
        activateButton.borderWidth = isActivated ? 1 : 0
        activateButton.borderColor = isActivated ? UIColor.mimoDarkGray : UIColor.clear
        activateButton.isUserInteractionEnabled = !isActivated
    }
    
    @IBAction private func activateAction() {
        delegate?.didSelectActivatePackage(for: self)
    }
}
