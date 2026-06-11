//
//  MimoIconTitileTableViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.05.23.
//

import UIKit

class MimoIconTitileTableViewCell: BaseTableViewCell {
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var iconImageView: UIImageView!
    
    var title: String? {
        didSet {
            titleLabel.text = title?.localized()
        }
    }
    
    var icon: UIImage? {
        didSet {
            iconImageView.image = icon
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.selectionStyle = .none
    }

}
