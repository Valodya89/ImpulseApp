//
//  AddCreditCardCollectionViewCell.swift
//  MimoBike
//
//  Created by Vardan on 24.05.21.
//

import UIKit

final class AddCreditCardCollectionViewCell: UICollectionViewCell {
    
    //MARK: - Life cycles
    
    var completion: ((_ isSelected: Bool)->())?
    var completionDeleteCard: (()->())?
    
    @IBOutlet weak var minFreeLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func didClick(_ sender: UIButton) {
        completion?(true)
    }
    @objc func didTappContext() {
        completion?(true)
    }
    
}
