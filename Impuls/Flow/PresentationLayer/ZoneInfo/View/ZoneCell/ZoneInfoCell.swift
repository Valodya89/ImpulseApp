//
//  ZoneInfoCell.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 21.01.23.
//

import UIKit

class ZoneInfoCell: BaseTableViewCell {

    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var titleLable: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.colorView.layer.cornerRadius = self.colorView.frame.height / 2
        self.selectionStyle = .none
    }

    func setData(zoneeInfo: ZoneInfo) {
        self.titleLable.text = zoneeInfo.title
        self.descriptionLabel.text = zoneeInfo.description
        
        switch zoneeInfo.id {
        case "Parking":
            print("Parking")
            icon.image = UIImage(named: "parking_nim")
        case "RIDE":
            print("Green")
            self.colorView.backgroundColor = .green
            icon.image = UIImage(named: "riding")
        case "FORBIDDEN":
            print("Red")
            self.colorView.backgroundColor = .red
            icon.image = UIImage(named: "noRiding")
        case "RESTRICTED":
            print("Yellow")
            self.colorView.backgroundColor = .yellow
            icon.image = UIImage(named: "speedLimit")
        default: break
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
