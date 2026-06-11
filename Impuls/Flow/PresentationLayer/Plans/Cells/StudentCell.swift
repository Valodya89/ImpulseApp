//
//  StudentCell.swift
//  MimoBike
//
//  Created by Dose on 6/5/21.
//

import UIKit

final class StudentCell: UITableViewCell {
    
    @IBOutlet weak var contentImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var actionButton: ActionButton!
    @IBOutlet weak var contextView: UIView!
    @IBOutlet weak var priceLabel: UILabel!
    
    var actionHandler: ((StudentCell)->())?
    
    func setup(_ info: TariffModel) {
        self.actionButton.isActive = true
        print("tarifffff = \(info)")
        print("student logo URL: \(info.logo.imageURL?.absoluteString)")
        self.contentImageView.setImage(info.logo.imageURL?.absoluteString, defaultImage: UIImage(named: "ic_calendar_package")!)
        self.priceLabel.text = info.priceName
        self.titleLabel.text = info.name
        self.descriptionLabel.text = info.description
    }
    
    @IBAction func actionTapped(_ sender: ActionButton) {
        actionHandler?(self)
    }
}
