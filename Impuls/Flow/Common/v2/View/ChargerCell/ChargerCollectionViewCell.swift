//
//  ChargerCollectionViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.11.23.
//

import UIKit

protocol ChargerCollectionViewCellDelegate: AnyObject {
    func didSelectChoose(cell: ChargerCollectionViewCell)
    func didSelectScan(cell: ChargerCollectionViewCell)
}

class ChargerCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var availableSlotsLabel: UILabel!
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var discountLabel: UILabel!
    
    @IBOutlet private weak var scanButton: UIButton!
    @IBOutlet private weak var chooseButton: UIButton!
    
    weak var delegate: ChargerCollectionViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        scanButton.titleLabel?.numberOfLines = 1
        scanButton.titleLabel?.adjustsFontSizeToFitWidth = true
        scanButton.titleLabel?.lineBreakMode = .byClipping
        scanButton.titleLabel?.minimumScaleFactor = 0.7
        
        chooseButton.titleLabel?.numberOfLines = 1
        chooseButton.titleLabel?.adjustsFontSizeToFitWidth = true
        chooseButton.titleLabel?.lineBreakMode = .byClipping
        scanButton.titleLabel?.minimumScaleFactor = 0.7
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
    }

    func set(station: ChargingStation) {
        titleLabel.text = station.destinationName ?? "-"
        addressLabel.text = station.destinationAddress ?? "-"
        availableSlotsLabel.text = "\(station.powerBanksCount ?? 0) \("MOBILE_charger_slotsAvailable".localized())"
        discountLabel.text = "\(station.discount)% \("MOBILE_charger_discount".localized())"
        
        logoImageView.sd_setImage(with: station.logo?.imageURL)
    }
    
    @IBAction private func scanAction() {
        delegate?.didSelectScan(cell: self)
    }
    
    @IBAction private func chooseAction() {
        delegate?.didSelectChoose(cell: self)
    }
}
