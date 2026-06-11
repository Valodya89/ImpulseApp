//
//  AccountBoardController.swift
//  MimoBike
//
//  Created by Dose on 6/11/21.
//

import UIKit

protocol AccountBoardActions: AnyObject {
    func plusTapped()
    func verifyEmailTapped()
    func packageTapped()
}

final class AccountBoardController: UITableViewController {
    
    @IBOutlet weak var accountCurrencyLabel: UILabel!
    @IBOutlet weak var emailVerifyCell: UITableViewCell!
    @IBOutlet weak var emailLabel: UILabel!
    
    @IBOutlet weak var freeMinutesDurationLabel: UILabel!
    @IBOutlet weak var accountBallanceLabel: UILabel!
    
    @IBOutlet weak var addAnimationView: UIView!
    
    @IBOutlet weak var activePackageView: UIView!
    @IBOutlet weak var activeStudentView: UIView!
    @IBOutlet weak var packageNameLabel: UILabel!
    @IBOutlet weak var studentNameLabel: UILabel!
    @IBOutlet weak var packageStartDate: UILabel!
    @IBOutlet weak var packageEndDateLabel: UILabel!
    @IBOutlet weak var studentStartDate: UILabel!
    @IBOutlet weak var studentEndDateLabel: UILabel!
    @IBOutlet weak var settingsContainer: UIView!
    
    @IBOutlet weak var contentViewHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: AccountBoardActions?
    
    private(set) var settingsViewController: SettingsBoardController!
        
    var sizedTableView: UITableView {
        return tableView as! SizedTableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self 
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        super.view.layoutIfNeeded()
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let settingsController = segue.destination as? SettingsBoardController {
            self.settingsViewController = settingsController
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
//        settingsViewController.sizedTableView.reloadData()
        contentViewHeightConstraint.constant = settingsViewController.sizedTableView.intrinsicContentSize.height
    }
    
    func setUserPackage(_ userPackage: ActivePackage?) {
        guard let package = userPackage else {
            activePackageView.isHidden = true
            sizedTableView.reloadData()
            return 
        }
        
        activePackageView.isHidden = false
        packageNameLabel.text = package.name.localized().capitalized
        packageStartDate.text = package.startDate.toString(dateStyle: .short, timeStyle: .short)
        packageEndDateLabel.text = package.endDate.toString(dateStyle: .short, timeStyle: .short)
    }
    
    func setUserTarrif(_ userTarrif: ActiveTarrif?) {
        guard let tarrif = userTarrif else {
            activeStudentView.isHidden = true
            sizedTableView.reloadData()
            return
        }
        
        activeStudentView.isHidden = false
        studentNameLabel.text = tarrif.name.localized().capitalized
        studentStartDate.text = tarrif.startDate.toString(dateStyle: .short, timeStyle: .short)
        studentEndDateLabel.text = tarrif.endDate.toString(dateStyle: .short, timeStyle: .short)
    }

    func setUserWallet(_ wallet: WalletModel) {
        if wallet.balance - (UserManager.share.debtAmount ?? 0.0) < 0 {
            accountBallanceLabel.textColor = .red
            
        }
        accountBallanceLabel.text = String((wallet.balance - (UserManager.share.debtAmount ?? 0.0)))
        accountCurrencyLabel.text = String(wallet.currency)
    }
    
    func setUser(_ user: UserResponse) {
        if !(user.emailVerified ?? false) {
            if let _ = user.email {
                emailLabel.text = "MOBILE_global_verify_email_button".localized()
            } else {
                emailLabel.text = "Attach email".localized()
            }
        } else {
            emailVerifyCell.isHidden = true
            sizedTableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if indexPath.row == 0 {
            return emailVerifyCell.isHidden ? 0 : UITableView.automaticDimension
        }
      
        return UITableView.automaticDimension
    }
  
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        VibrateManager.vibrate()
        if indexPath.row == 0 {
            delegate?.verifyEmailTapped()
        }
        if indexPath.row == 4 {
            delegate?.packageTapped()
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    @IBAction func plusTapped(_ sender: Any) {
        delegate?.plusTapped()
    }
}
