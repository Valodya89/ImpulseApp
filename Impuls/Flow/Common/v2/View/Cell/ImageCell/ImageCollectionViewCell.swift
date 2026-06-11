//
//  ImageCollectionViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 23.11.23.
//

import UIKit

class ImageCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet private weak var imgView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func set(imageURL: URL?) {
        imgView.sd_setImage(with: imageURL)
    }
}
