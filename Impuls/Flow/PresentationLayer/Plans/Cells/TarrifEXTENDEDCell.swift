//
//  TarrifCell.swift
//  MimoBike
//
//  Created by Dose on 6/5/21.
//

import UIKit

final class TarrifEXTENDEDCell: UITableViewCell {
    @IBOutlet weak var contentIcon: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var contextView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet var extandTitles: [UILabel]!
    @IBOutlet var extandValluues: [UILabel]!
    
    
    func setup(_ info: TariffModel) {
        print("info = \(info)")
        for (i, item) in (info.extendedDetails ?? []).enumerated() {
            extandTitles[i].text = item.name
            extandValluues[i].text = item.priceName
        }
        self.contentIcon.setImage(info.logo.imageURL?.absoluteString, defaultImage: UIImage(named: "ic_calendar_package")!)
        self.descriptionLabel.text = info.priceName
        self.timeLabel.text = info.name


    }
}
