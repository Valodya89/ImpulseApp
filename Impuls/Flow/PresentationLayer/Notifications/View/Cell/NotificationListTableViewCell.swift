//
//  NotificationListTableViewCell.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 11.08.21.
//

import UIKit

class NotificationListTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .mimoGray100
        contentView.backgroundColor = .mimoGray100
        titleLabel.textColor = .appLabel
        dateLabel.textColor = .appLabel
        descriptionLabel.backgroundColor = .clear
        descriptionLabel.textColor = .appLabel
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
