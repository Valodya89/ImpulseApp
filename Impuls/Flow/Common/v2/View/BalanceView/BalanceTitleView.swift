//
//  BalanceTitleView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 09.08.23.
//

import Foundation

class BalanceTitleView: UIView {
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    var action: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed("BalanceTitleView", owner: self)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        activityIndicator.transform = .init(scaleX: 0.9, y: 0.9)
    }
    
    func set(balance: WalletModel?, financialState: FinancialStateModel?) {
        guard let walletInfo = balance, let financialState = financialState else { return }
        
        if walletInfo.balance - (financialState.additional ?? 0) < 0 {
            balanceLabel.textColor = .red
        } else {
            balanceLabel.textColor = .mimoBlackWith075alpha
        }
        
        let balance = (walletInfo.balance - (financialState.additional ?? 0))
        let currency = walletInfo.currency.currencySymbol
        balanceLabel.text = String(format: "%.2f %@", balance, currency)
        balanceLabel.alpha = 1
        activityIndicator.stopAnimating()
    }
    
    @IBAction private func addBalanceAction() {
        VibrateManager.vibrate()
        action?()
    }
}
