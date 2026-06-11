//
//  DebtTBCell.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 12.09.22.
//

import UIKit

protocol DebtTBCellDelegate: AnyObject {
    func didSelectTransfer(wallet: WalletDebts)
}

class DebtTBCell: UITableViewCell {

    @IBOutlet weak var walleetIdLbl: UILabel!
    @IBOutlet weak var debtAmountLbl: UILabel!
    @IBOutlet weak var transferBtn: UIButton!
    
    weak var delegate: DebtTBCellDelegate?
    var wallet: WalletDebts?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        transferBtn.layer.cornerRadius = transferBtn.frame.height / 2
        transferBtn.layer.borderColor = UIColor.mimoBlack.cgColor
        transferBtn.layer.borderWidth = 1.0
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func setData(wallet: WalletDebts) {
        self.wallet = wallet
        self.walleetIdLbl.text = wallet.walletId
        self.debtAmountLbl.text = "-\(wallet.debtSum ?? 0.0)"
        self.debtAmountLbl.textColor = .red
    }
    
    @IBAction func transferAction(_ sender: UIButton) {
        if let wallet = wallet {
            delegate?.didSelectTransfer(wallet: wallet)
        }
    }
    
}
