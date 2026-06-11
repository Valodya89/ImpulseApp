//
//  ScooterCollectionViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.05.23.
//

import UIKit

protocol ScooterCollectionViewCellDelegate: AnyObject {
    func chooseScooterAction(for cell: ScooterCollectionViewCell)
    func bookScooterAction(for cell: ScooterCollectionViewCell)
}

class ScooterCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var batteryImageView: UIImageView!
    @IBOutlet private weak var batteryPercentLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var bookButton: UIButton!
    @IBOutlet private weak var takeButton: UIButton!
    @IBOutlet private weak var qrLabel: UILabel!
    
    weak var delegate: ScooterCollectionViewCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
    }
    
    func set(scooter: ScooterResult?) {
        guard let scooter else { return }
        
        durationLabel.text = scooter.remainingMileage.prettyPrinted
        batteryPercentLabel.text = scooter.batteryPercent.percentPrettyPrinted
        qrLabel.text = scooter.qr
        batteryImageView.image = scooter.batteryPercent.image
    }
    
    @IBAction private func chooseAction() {
        delegate?.chooseScooterAction(for: self)
    }
    
    @IBAction private func bookAction() {
        delegate?.bookScooterAction(for: self)
    }
}
