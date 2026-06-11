//
//  TarrifCell.swift
//  MimoBike
//
//  Created by Dose on 6/5/21.
//

import UIKit

final class TarrifCell: UITableViewCell {
    @IBOutlet weak var contentIcon: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var contextView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    func setup(_ info: TariffModel) {
        print("info = \(info)")
        self.contentIcon.setImage(info.logo.imageURL?.absoluteString, defaultImage: UIImage(named: "ic_calendar_package")!)
        self.descriptionLabel.text = info.priceName
        self.timeLabel.text = info.name
        self.infoLabel.text = info.description
    }
}
