//
//  ShowDebtViewController.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 23.08.22.
//

import UIKit

protocol ShowDebtViewControllerDdelegate: AnyObject {
    func didSelectPayDdebt()
    func didSelectTransfer(wallet: WalletDebts)
    func didSelectTransfer()
}

class ShowDebtViewController: UIViewController, StoryboardInitializable, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DebtTBCell", for: indexPath) as? DebtTBCell
        cell?.setData(wallet: self.wallets[indexPath.row])
        cell?.delegate = self
        
        return cell!
    }
    

    @IBOutlet weak var debtLabel: UILabel!
    @IBOutlet weak var payDebtBtn: UILocalizedButton!
    
    @IBOutlet weak var debtTb: UITableView!
    weak var delegate: ShowDebtViewControllerDdelegate?
    
    var amount =  0.0
    var wallets: [WalletDebts] = []    
    
    override func viewDidLoad() {
        self.debtTb.isHidden = true
        
        super.viewDidLoad()
       
        updateUI(amount: amount, wallets: wallets)
    }
    
    func updateUI(amount: Double, wallets: [WalletDebts]) {
        self.wallets = wallets
        if wallets.count > 0 {
            self.debtTb.isHidden = false
            debtTb.delegate = self
            debtTb.dataSource = self
            self.debtTb.reloadData()
        }
        DispatchQueue.main.async {
            self.payDebtBtn.layer.cornerRadius = self.payDebtBtn.frame.height / 2
            self.amount = amount
            self.debtLabel.text = "\(amount - (UserManager.share.walletModel?.balance ?? 0.0).rounded()) ֏"
        }
    }
    
    @IBAction func closeActioon(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func payDebtAction(_ sender: UILocalizedButton) {
        UserManager.share.debtAmount = amount
        self.dismiss(animated: true) { [delegate] in
            delegate?.didSelectPayDdebt()
        }
    }
}

extension ShowDebtViewController: DebtTBCellDelegate {
    
    func didSelectTransfer(wallet: WalletDebts) {
        delegate?.didSelectTransfer()
        self.dismiss(animated: true) { [delegate] in
            delegate?.didSelectTransfer(wallet: wallet)
        }
    }
}
