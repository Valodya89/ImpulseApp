//
//  TripsListViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/15/21.
//

import UIKit

final class TripsListViewController: UIViewController, StoryboardInitializable {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var debtLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    
    @IBOutlet weak var switchBackgroundView: UIView!
    @IBOutlet private weak var bikeView: UIView!
    @IBOutlet weak var scooterAnimationView: AnimatedView!
    @IBOutlet weak var bikeAnimationView: AnimatedView!
    
    @IBOutlet weak var bikeIconImageView: UIImageView! // ic_scooter / ic_bike
    @IBOutlet weak var scooterIconImageView: UIImageView!
    
    @IBOutlet weak var bikeTitleLbl: UILocalizedLabel!
    @IBOutlet weak var bikeIconLeftConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var servicesStackView: UIStackView!
    @IBOutlet private var mimoTypeButtons: [MimoToggleButton]!
    
    var bikeState: BikeState = .bike
    var mimoType: MimoType = .scooter
    
    let sessionNetwork = SessionNetwork()
    
    var viewModel = HomeScanQRViewModel()
    var bikeTrips: [TripBikeDataModel] = []
    var scooterTrips: [TripScooterDataModel] = []
    var chargerRents: [ChargerRentModel] = []
    var userResult: UserResult?
    var walletNavigationController: UINavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.\
        
        self.title = "MOBILE_profile_history".localized()
        self.tableView.isHidden = true
        setupDebt()
        
        tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
        if bikeState == .scooter {
            self.bikeIconLeftConstraint.constant = 170 - self.bikeView.frame.width - 4
            self.bikeTitleLbl.text = "SCOOTER_global_title".localized()
        } else {
            self.bikeIconLeftConstraint.constant = 4
            self.bikeTitleLbl.text = "SHARING_global_title".localized()
        }
        UserManager.share.getUser { [weak self] (result) in
            guard let unwrapSelf = self else { return }
            
            switch result {
            case .success(let user):
                unwrapSelf.userResult = AccountMapper.toUserResult(from: user)
            case .failure(let error):
                break
            }
        }
        switchBackgroundView.layer.cornerRadius = 24
        bikeView.layer.cornerRadius = Constant.CornerRadius.cornerRadiusFromScreenWidth20
        
        let missingTypes = MimoType.allCases.filter({ !ApplicationSettings.shared.availableServices.contains($0) })
        missingTypes.forEach { type in
            if let view = servicesStackView.subviews.first(where: { $0.tag == type.rawValue }) {
                view.alpha = 0
                servicesStackView.removeArrangedSubview(view)
            }
        }
        
        self.mimoType = ApplicationSettings.shared.availableServices.first ?? .scooter
        self.mimoTypeButtons.forEach({ $0.isSelected = mimoType.rawValue == $0.tag })
        
        setupData()
        
//        tableView.register(ChargerHistoryTableViewCell.self)
        tableView.register(UINib(nibName: "ChargerHistoryTableViewCell", bundle: nil), forCellReuseIdentifier: "ChargerHistoryTableViewCell")
    }
    
    private func setupDebt() {
        amountLabel.text = String(format: "%.2f", UserManager.share.debtAmount ?? 0.0) // "\((UserManager.share.debtAmount ?? 0.0) - (UserManager.share.walletModel?.balance ?? 0.0).rounded())"
        debtLabel.text = "MOBILE_trips_debt_phone".localized().replacingOccurrences(of: "[phone]", with: "")
        if (UserManager.share.debtState?.state == .Success) {
            topView.frame.size.height = 0
            self.topView.removeFromSuperview()
        } else {
            self.phoneNumberLabel.text = StorageManager().fetch(key: .phoneNumber, type: String.self) ?? ""
        }
    }
    
    private func setupData() {
        
        switch mimoType {
        case .scooter:
            sessionNetwork.request(with: URLBuilder(from: AuthAPI.getScooterTripList)) { [weak self] (result) in
                switch result {
                case .success(let data):
                    print("End: \(Date())")
                    guard let response = try? JSONDecoder().decode(BaseResponseModel<[TripScooterDataModel]>.self, from: data) else {
                        UIAlertController.showError(message: "Can not get trips")
                        return
                    }
                    
                    if response.statusCode == 200 {
                        self?.scooterTrips = (response.content ?? [])
                        if self?.scooterTrips.count ?? 0 > 0 {
                            self?.tableView.isHidden = false
                            self?.tableView.reloadData()
                        } else {
                            self?.tableView.isHidden = true
                        }
                        return
                    }
                    
                    
                    UIAlertController.showError(message: response.message)
                case .failure(let error):
                    UIAlertController.showError(message: error.description)
                }
            }
        case .bike:
            sessionNetwork.request(with: URLBuilder(from: AuthAPI.getBikeTripList)) { [weak self] (result) in
                switch result {
                case .success(let data):
                    print("End: \(Date())")
                    guard let response = try? JSONDecoder().decode(BaseResponseModel<[TripBikeDataModel]>.self, from: data) else {
                        UIAlertController.showError(message: "Can not get trips")
                        return
                    }
                    
                    if response.statusCode == 200 {
                        self?.bikeTrips = (response.content ?? [])
                        if self?.bikeTrips.count ?? 0 > 0 {
                            self?.tableView.isHidden = false
                            self?.tableView.reloadData()
                        } else {
                            self?.tableView.isHidden = true
                        }
                        return
                    }
                    
                    UIAlertController.showError(message: response.message)
                case .failure(let error):
                    UIAlertController.showError(message: error.description)
                }
            }
        case .charger:
            sessionNetwork.request(with: URLBuilder(from: AuthAPI.getChargerRentList)) { [weak self] (result) in
                switch result {
                case .success(let data):
                    print("End: \(Date())")
                    
                    guard let response = try? JSONDecoder().decode(BaseResponseModel<[ChargerRentModel]>.self, from: data) else {
                        UIAlertController.showError(message: "Can not get rents")
                        return
                    }
                    
                    if response.statusCode == 200 {
                        self?.chargerRents = (response.content ?? [])
                        if self?.chargerRents.count ?? 0 > 0 {
                            self?.tableView.isHidden = false
                            self?.tableView.reloadData()
                        } else {
                            self?.tableView.isHidden = true
                        }
                        return
                    }
                    
                    UIAlertController.showError(message: response.message)
                case .failure(let error):
                    UIAlertController.showError(message: error.description)
                }
            }
        case .evCharger:
            break
        }
    }
    
    @IBAction func payDebtTapped(_ sender: UIButton) {
        openWallet()
        
//        guard let unwrapUserResult = userResult else {
//            return UIAlertController.showError(message: "Can not show wallet page")
//        }
//        self.viewModel.getAvatar { [weak self] (avatarUrlStirng) in
//            guard let unwrapSelf = self else { return }
//            
////            let walletVC = WalletViewController.initFromStoryboard(name: Constant.Storyboards.wallet)
////            unwrapSelf.walletNavigationController = UINavigationController(rootViewController: walletVC)
////            unwrapSelf.walletNavigationController?.navigationBar.barTintColor = .white
////            unwrapSelf.walletNavigationController?.navigationBar.backgroundColor = .white
////
////            
////            let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_arrow_left"), style: .plain, target: self, action: #selector(unwrapSelf.backButtonTapped))
////            walletVC.navigationItem.leftBarButtonItem = backButton
////            
////            walletVC.user = unwrapUserResult
////            unwrapSelf.viewModel.getAvatar { (avatarUrlStirng) in
////                walletVC.avataturURLString = avatarUrlStirng
////            }
////            
////            unwrapSelf.present(unwrapSelf.walletNavigationController!, animated: true, completion: nil)
//            
//            self?.openWallet()
//        }
    }
    
    @objc func backButtonTapped() {
        self.walletNavigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func bikeButtonTapped(_ sender: UIButton) {
        
        UIView.setAnimationsEnabled(true)
        if bikeState == .bike {
            bikeState = .scooter
            self.bikeIconLeftConstraint.constant = 170 - self.bikeView.frame.width - 4
            self.bikeTitleLbl.text = "SCOOTER_global_title".localized()
        } else {
            bikeState = .bike
            self.bikeIconLeftConstraint.constant = 4
            self.bikeTitleLbl.text = "SHARING_global_title".localized()
        }
        setupData()
        self.view.setNeedsLayout()
        UIView.animate(withDuration: 0.8) {
            self.view.layoutIfNeeded()
        } completion: { isFinishedd in
            self.tableView.reloadData()
        }
    }
    
    @IBAction private func mimoTypeAction(_ sender: MimoToggleButton) {
        VibrateManager.vibrate()
        
        let newMimoType = MimoType(rawValue: sender.tag) ?? .scooter
        guard newMimoType != mimoType else { return }
        
        mimoType = newMimoType
        
        self.mimoTypeButtons.forEach({ $0.isSelected = mimoType.rawValue == $0.tag })
        
        setupData()
    }
    
    @IBAction private func closeAction() {
        self.dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource -

extension TripsListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch mimoType {
        case .scooter:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "TripsListTableViewCell") as? TripsListTableViewCell  {
                if indexPath.section < scooterTrips.count {
                    let item = scooterTrips[indexPath.section]
                    cell.setup(item)
                }
                
                return cell
            } else {
                return UITableViewCell()
            }
        case .bike:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "TripsListTableViewCell") as? TripsListTableViewCell  {
                if indexPath.section < bikeTrips.count {
                    let item = bikeTrips[indexPath.section]
                    cell.setup(item)
                } else {
                    return UITableViewCell()
                }
                    
                return cell
            } else {
                return UITableViewCell()
            }
        case .charger:
            if let cell = tableView.dequeueReusableCell(withIdentifier: "TripsListTableViewCell") as? TripsListTableViewCell  {
                if indexPath.section < chargerRents.count {
                    let item = chargerRents[indexPath.section]
                    cell.setup(data: item)
                } else {
                    return UITableViewCell()
                }
                    
                return cell
            } else {
                return UITableViewCell()
            }
        case .evCharger:
            return UITableViewCell()
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        switch mimoType {
        case .scooter:
            return scooterTrips.count
        case .bike:
            return bikeTrips.count
        case .charger:
            return chargerRents.count
        case .evCharger:
            return chargerRents.count
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
}


// MARK: - UITableViewDelegate -

extension TripsListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tripsDetailsViewController = TripsDetailsViewController.initFromStoryboard(name: Constant.Storyboards.wallet)
        VibrateManager.vibrate()
        
        switch mimoType {
        case .scooter:
            let item = scooterTrips[indexPath.section]

            tripsDetailsViewController.scooterTripModel = item

            self.navigationController?.pushViewController(tripsDetailsViewController, animated: true)
        case .bike:
            let item = bikeTrips[indexPath.section]
            
            tripsDetailsViewController.bikeTripModel = item
            
            self.navigationController?.pushViewController(tripsDetailsViewController, animated: true)
        case .charger:
            let item = chargerRents[indexPath.section]
            
            tripsDetailsViewController.chargerModel = item
            
            self.navigationController?.pushViewController(tripsDetailsViewController, animated: true)
        case .evCharger:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 30))
        
        switch mimoType {
        case .scooter:
            guard scooterTrips.count > 0 else { return headerView }
            let item = scooterTrips[section]
            let label = UILabel()
            
            headerView.addSubview(label)
            
            label.translatesAutoresizingMaskIntoConstraints = false
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 0).isActive = true
            label.bottomAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 0).isActive = true

            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10).isActive = true
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: 10).isActive = true

            let date = Date(timeIntervalSince1970: TimeInterval((item.start ?? 0) / 1000))
            
            var locale: Locale = Locale.current
            if let language = StorageManager().fetch(key: .language, type: String.self) {
                locale = Locale(identifier: language)
            }
            
            label.text = date.toString(dateStyle: .medium, timeStyle: .short, locale: locale)
            label.font = .systemFont(ofSize: 16)
            label.textColor = UIColor.mimoBlackWith075alpha
        case .bike:
            let item = bikeTrips[section]
            let label = UILabel()
            
            headerView.addSubview(label)
            
            label.translatesAutoresizingMaskIntoConstraints = false
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 0).isActive = true
            label.bottomAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 0).isActive = true

            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10).isActive = true
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: 10).isActive = true

            let date = Date(timeIntervalSince1970: TimeInterval((item.start ?? 0) / 1000))
            
            var locale: Locale = Locale.current
            if let language = StorageManager().fetch(key: .language, type: String.self) {
                locale = Locale(identifier: language)
            }
            
            label.text = date.toString(dateStyle: .medium, timeStyle: .short, locale: locale)
            label.font = .systemFont(ofSize: 16)
            label.textColor = UIColor.mimoBlackWith075alpha
        case .charger:
            let item = chargerRents[section]
            let label = UILabel()
            
            headerView.addSubview(label)
            
            label.translatesAutoresizingMaskIntoConstraints = false
            label.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 0).isActive = true
            label.bottomAnchor.constraint(equalTo: headerView.centerYAnchor, constant: 0).isActive = true

            label.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 10).isActive = true
            label.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: 10).isActive = true

            let date = Date(timeIntervalSince1970: TimeInterval((item.start) / 1000))
            
            var locale: Locale = Locale.current
            if let language = StorageManager().fetch(key: .language, type: String.self) {
                locale = Locale(identifier: language)
            }
            
            label.text = date.toString(dateStyle: .medium, timeStyle: .short, locale: locale)
            label.font = .systemFont(ofSize: 16)
            label.textColor = UIColor.mimoBlackWith075alpha
        case .evCharger:
            break
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 104
    }
}
