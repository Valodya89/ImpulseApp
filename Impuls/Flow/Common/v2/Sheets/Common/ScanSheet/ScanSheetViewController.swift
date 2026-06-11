//
//  ScanSheetViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.05.23.
//

import UIKit

enum ScanSheetAction: Int {
    case scanQr
    case rates
}

fileprivate enum CollectionsSection: Int, CaseIterable {
    case trips
    case rates
    case support
    
    var title: String {
        switch self {
        case .trips:
            return "MOBILE_profile_history".localized()
        case .rates:
            return "MOBILE_map_rates".localized()
        case .support:
            return "MOBILE_map_support".localized()
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .trips:
            return "ic_tips_homeCollection".image
        case .rates:
            return "ic_rates_homeCollection".image
        case .support:
            return "ic_support_homeCollection".image
        }
    }
    
    static let rowHeight: CGFloat = 70
}

protocol ScanSheetViewControllerDelegate: AnyObject {
    func scanSheetAction(actionType: ScanSheetAction)
}

class ScanSheetViewController: MimoBaseViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var scanQRButtonView: UIView!
    @IBOutlet private weak var freeMinutesLabel: UILabel!
    @IBOutlet private weak var minLabel: UILabel!
    
    @IBOutlet private weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var balanceViewTopConstraint: NSLayoutConstraint!
    
    private var sections: [CollectionsSection] {
        return mimoType == .scooter || mimoType == .charger ? [.trips, .support] : CollectionsSection.allCases
    }
    
    private var mimoType: MimoType = .scooter
    private var walletInfo: WalletModel?
    private var financialState: FinancialStateModel?
    private var user: UserResponse?
    
    var data: Data? {
        didSet {
            mimoType = data?.mimoType ?? .scooter
            walletInfo = data?.walletInfo
            financialState = data?.financialState
            user = data?.user
            
            setupBalance()
        }
    }
    
    var isFullyVisible: Bool = false {
        didSet {
            updateContentConstraints()
        }
    }
    
    weak var delegate: ScanSheetViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBalance()
    }
    
    private func setupUI() {
        tableViewHeightConstraint.constant = CGFloat(sections.count) * CollectionsSection.rowHeight
        minLabel.text = "SCOOTER_global_minute".localized()
        
        tableView.register(MimoIconTitileTableViewCell.self)
        updateContentConstraints()
    }
    
    private func setupBalance() {
        guard let walletInfo = walletInfo, let financialState = financialState, isViewLoaded else {
            if isViewLoaded {
                balanceLabel.text = "0"
            }
            return
        }
        
        if walletInfo.balance - (financialState.additional ?? 0) < 0 {
            balanceLabel.textColor = .red
        } else {
            balanceLabel.textColor = .mimoBlackWith075alpha
        }
        
        let balance = (walletInfo.balance - (financialState.additional ?? 0))
        balanceLabel.text = String(format: "%.2f", balance)
        
        freeMinutesLabel.text = String(format: "%.2f", user?.minutes ?? 0)
    }
    
    private func updateContentConstraints() {
        guard isViewLoaded else { return }
        balanceViewTopConstraint.constant = isFullyVisible ? 20 : 50
        
        UIView.animate(withDuration: isFullyVisible ? 0.3 : 0.1) {
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction private func action(_ sender: UIButton) {
        guard let actionType = ScanSheetAction(rawValue: sender.tag) else { return }
        delegate?.scanSheetAction(actionType: actionType)
    }
    
    @IBAction private func balanceAction() {
        openWallet()
    }
}

extension ScanSheetViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: MimoIconTitileTableViewCell = tableView.dequeueReusableCell(for: indexPath)
        cell.title = sections[indexPath.row].title
        cell.icon = sections[indexPath.row].icon
        
        return cell
    }
}

extension ScanSheetViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        VibrateManager.vibrate()
        
        switch sections[indexPath.row] {
        case .trips:
            let tripsListViewController = TripsNavigationController.initFromStoryboard(name: Constant.Storyboards.wallet)
            (tripsListViewController.topViewController as? TripsListViewController)?.mimoType = mimoType
            self.present(tripsListViewController, animated: true, completion: nil)
        case .support:
            let supportController = SupportNavigationViewController.initFromStoryboard(name: Constant.Storyboards.accountCover)
            present(supportController, animated: true, completion: nil)
        case .rates:
            BikeRouter.shared.showTariffsViewController(self)
        }
    }
}

extension ScanSheetViewController {
    struct Data {
        let mimoType: MimoType
        var walletInfo: WalletModel?
        var financialState: FinancialStateModel?
        var user: UserResponse?
    }
}
