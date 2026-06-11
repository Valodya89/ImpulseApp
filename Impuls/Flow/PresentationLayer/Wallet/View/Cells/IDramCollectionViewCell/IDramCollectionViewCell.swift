//
//  IDramCollectionViewCell.swift
//  MimoBike
//
//  Created by Vardan on 24.05.21.
//

import UIKit

final class IDramCollectionViewCell: UICollectionViewCell {
  
    @IBOutlet weak var checkboxButton: UIButton!
    @IBOutlet weak var contentImageView: UIImageView!
    
    var completion: ((_ isSelected: Bool)->())?
    
    override var isSelected: Bool {
        didSet {
            checkboxButton.isSelected = isSelected
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isSelected = false 
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        checkboxButton.setImage(UIImage(named: "ic_unSelected_radioButton_image"), for: .normal)
        checkboxButton.setImage(UIImage(named: "ic_seected_radioButton_image"), for: .selected)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didSelectContext)))
    }

    
    @IBAction func didSelectContext() {
        VibrateManager.vibrate()
        isSelected = !isSelected
        completion?(isSelected)
    }
}
