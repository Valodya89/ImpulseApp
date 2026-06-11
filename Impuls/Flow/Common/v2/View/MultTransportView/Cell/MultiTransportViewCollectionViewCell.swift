//
//  MultiTransportViewCollectionViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.06.23.
//

import UIKit

class MultiTransportViewCollectionViewCell: BaseCollectionViewCell {

    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var titleLabel: UILabel!
    
    var title: String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    var isChecked: Bool = false {
        didSet {
            containerView.borderColor = isChecked ? .black : .clear
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        containerView.addShadow(color: .black, offset: CGSize(width: 0, height: 2), opacity: 0.3, shadowRadius: 6)
    }

}
