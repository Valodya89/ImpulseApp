//
//  CreditCardCollectionViewCell.swift
//  MimoBike
//
//  Created by Vardan on 24.05.21.
//

import UIKit

class CreditCardCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var creditHolderName: UILabel!
    @IBOutlet weak var radioButton: UIButton!
    @IBOutlet weak var creditNumberLabel: UILabel!
    @IBOutlet weak var expirationDateLabel: UILabel!
    
    @IBOutlet weak var cardTypeImageView: UIImageView!
    
    var completion: ((_ isSelected: Bool)->())?
    var completionDeleteCard: (()->())?
    
    override var isSelected: Bool {
        didSet {
            radioButton.isSelected = isSelected
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        isSelected = false
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        radioButton.setImage(UIImage(named: "ic_unSelected_radioButton_image"), for: .normal)
        radioButton.setImage(UIImage(named: "ic_seected_radioButton_image"), for: .selected)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didSelectContext)))
    }

    func configUI(with card: WalletCard) {
        self.creditHolderName.text = card.cardholder
        self.creditNumberLabel.text = "****\t****\t****\t\(card.cardMask.suffix(4))"
        self.expirationDateLabel.text = card.expiration
        if card.cardMask.prefix(1) == "4" {
            self.cardTypeImageView.image = UIImage(named: "ic_visa")
        } else if card.cardMask.prefix(2) == "51" || card.cardMask.prefix(2) == "52" || card.cardMask.prefix(2) == "53" || card.cardMask.prefix(2) == "54" || card.cardMask.prefix(2) == "55" {
            self.cardTypeImageView.image = UIImage(named: "ic_masterCard")
        } else if card.cardMask.prefix(2) == "34" || card.cardMask.prefix(2) == "37" {
            self.cardTypeImageView.image = UIImage(named: "ic_american_express")
        } else if (Int(card.cardMask.prefix(4)) ?? 0) >= 2200 && (Int(card.cardMask.prefix(4)) ?? 0) <= 2204 {
            self.cardTypeImageView.image = UIImage(named: "ic_mir")
        } else {
            self.cardTypeImageView.image = UIImage(named: "ic_arca")
        }
        
    }
    
    @IBAction func didSelectContext() {
        VibrateManager.vibrate()
        isSelected = !isSelected
        completion?(isSelected)
    }

    @IBAction func deleteCardAction(_ sender: UIButton) {
        VibrateManager.vibrate()
        completionDeleteCard?()
    }
    
}
