//
//  SettingsBoard.swift
//  MimoBike
//
//  Created by Dose on 6/11/21.
//

import UIKit

enum AccountRoutes {
    case rates
    case settings
    case partnership
    case support
    case howToUse
    case privacyPolicy
    case logout
    case agreement
    case deleteAccount
}

final class SettingsBoardController: UITableViewController {
    
    @IBOutlet weak var howToUseCell: UITableViewCell!
    @IBOutlet weak var supportCell: UITableViewCell!
    @IBOutlet weak var settingsCell: UITableViewCell!
    
    @IBOutlet weak var logOutCell: UITableViewCell!
    @IBOutlet weak var mimoAgreemnetCell: UITableViewCell!
    @IBOutlet weak var privacyPolicyCell: UITableViewCell!
    
    var actions: ((AccountRoutes) -> ())?
    
    var sizedTableView: UITableView {
        return tableView as! SizedTableView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        VibrateManager.vibrate()
        switch indexPath.row - 1 {
        case 0:
            actions?(.rates)
        case 1:
            actions?(.support)
        case 2:
            actions?(.howToUse)
        case 3:
            actions?(.settings)
        case 4:
            actions?(.partnership)
        case 5:
            actions?(.privacyPolicy)
        case 6:
            actions?(.agreement)
        case 7:
            actions?(.logout)
        case 8:
            actions?(.deleteAccount)
        default: return
        }
    }
        
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 56
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footer = UIView()
        let version = UILabel(frame: .init(origin: .init(x: view.frame.width/2 - 100/3, y: 10), size: CGSize(width: 100, height: 56)))
        version.textAlignment = .center
        version.textColor = .black
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        
        version.text = "v " + (appVersion ?? "")
        footer.addSubview(version)
        
        version.topAnchor.constraint(equalTo: footer.topAnchor).isActive = true
        version.bottomAnchor.constraint(equalTo: footer.bottomAnchor).isActive = true
        version.leadingAnchor.constraint(equalTo: footer.leadingAnchor).isActive = true
        version.trailingAnchor.constraint(equalTo: footer.trailingAnchor).isActive = true
        
        return footer
    }
}
