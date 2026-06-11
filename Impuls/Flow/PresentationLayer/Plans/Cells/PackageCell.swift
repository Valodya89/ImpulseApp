//
//  PackageCell.swift
//  MimoBike
//
//  Created by Dose on 6/5/21.
//

import UIKit

final class PackageCell: UITableViewCell {
    @IBOutlet weak var contentIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusView: CircleView!
    @IBOutlet weak var feeIcon: UIImageView!
    @IBOutlet weak var feeTitleLabel: UILabel!
    @IBOutlet weak var feePriceLabel: UILabel!
    @IBOutlet weak var ridesLabel: UILabel!
    @IBOutlet weak var ridesIcon: UIImageView!
    @IBOutlet weak var ridesDescription: UILabel!
    @IBOutlet weak var actionButton: ActionButton!
    @IBOutlet weak var contextView: GradientFillView!
    @IBOutlet weak var actionView: UIView!
    
    var actionHandler: ((PackageCell)->())?
    
    override var backgroundColor: UIColor? {
        didSet {
            guard contextView != nil else { return }
            contextView.topColor = backgroundColor ?? .white
            contextView.bottomColor = backgroundColor ?? .white
            layer.backgroundColor = UIColor.clear.cgColor
        }
    }
    
    func setup(_ model: PackageModel, hideActiveButton: Bool) {
        self.titleLabel.text = model.localizedName
        self.statusView.isHidden = !model.popular
        self.ridesDescription.text = model.description
        self.feePriceLabel.text = model.price.description + " " + "MOBILE_global_total_currency".localized()
        self.feeTitleLabel.text = "MOBILE__label_fee".localized().replacingOccurrences(of: "[name]", with: model.localizedName)
        self.contentIcon.setImage(model.logo.imageURL?.absoluteString, defaultImage: UIImage(named: "ic_calendar_package")!)
        self.actionView.isHidden = hideActiveButton
        self.actionButton.isActive = true
        
//        self.descriptionLabel.text = model.description
//        self.timeLabel.text = model.localizedName
//        self.actionView.isHidden = model.
    }
    
    func hideActionButton() {
        actionView.isHidden = true 
    }
    
    @IBAction func actionTapped(_ sender: ActionButton) {
        actionHandler?(self)
    }
}
