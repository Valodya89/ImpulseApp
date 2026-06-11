//
//  HomeScanQrSheetViewController.swift
//  MimoBike
//
//  Created by Vardan on 03.05.21.
//

import UIKit
import Lottie

enum BikeState {
    case bike
    case scooter
}

enum HomeScanQrSheetButtonsState {
    case scanQR
    case bike
    case scooter
}

protocol HomeScanQrSheetViewControllerDelegate: AnyObject {
    func didTappedButton(state: HomeScanQrSheetButtonsState, isShowList: Bool)
    
    func didSelectCollection(state: HomeScanQrSheetViewController.CollectionModel)
    func closedWalletPage()
    func openShowDebt(amount: Double, wallets: [WalletDebts])
}


class HomeScanQrSheetViewController: BaseViewController, StoryboardInitializable {
    
    @IBOutlet weak var scooterAnimationView: AnimatedView!
    @IBOutlet weak var bikeAnimationView: AnimatedView!
    
    @IBOutlet weak var bikeIconImageView: UIImageView! // ic_scooter / ic_bike
    
    @IBOutlet weak var bikeTitleLbl: UILocalizedLabel!
    @IBOutlet weak var bikeIconLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var scooterImage: UIImageView!
    
    var collectionModel: [CollectionModel] = [.trips, .rates, .support]
    
    var bikeState: BikeState = .bike
    
    enum CollectionModel: CaseIterable {
        
        case trips
        case rates
        case support
        
        var icon: UIImage {
            switch self {
            case .trips:
                return UIImage(named: "ic_tips_homeCollection")!
            case .rates:
                return UIImage(named: "ic_rates_homeCollection")!
            case .support:
                return UIImage(named: "ic_support_homeCollection")!
            }
        }
        
        var title: String {
            switch self {
            case .trips:
                return "MOBILE_map_trips".localized()
            case .rates:
                return "MOBILE_map_rates".localized()
            case .support:
                return "MOBILE_map_support".localized()
            }
        }
        
        var index: Int {
            return CollectionModel.allCases.firstIndex(of: self)!
        }
    }
    
    
    //MARK: - Outlets
    @IBOutlet private weak var joinNowView: UIView!
    @IBOutlet private weak var bikeContentView: UIView!
    @IBOutlet private weak var bikeView: UIView!
    @IBOutlet weak var balanceContentView: UIView!
    @IBOutlet weak var plusButton: UIButton!
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    
    //MARK: - Variables

    weak var delegate: HomeScanQrSheetViewControllerDelegate?
    var viewModel = HomeScanQRViewModel()
    var userResult: UserResult?
    var userAccountResult: UserResult?
    var avatarUrlStirng: String?
    var walletNavigationController: UINavigationController?
    var usertDebt: Double = 0.0
    var planNavVC: UINavigationController?
    
    
    
    //MARK: - Life cycles
    override func viewDidLoad() {
        super.viewDidLoad()
        if (UserDefaults.standard.value(forKey: "BikeState") as? String) == nil {
            UserDefaults.standard.set("bike", forKey: "BikeState")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: Constant.Notifications.LanguageUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userChanged), name: Constant.Notifications.updateUserUI, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateFinansialState), name: Constant.Notifications.updateFinansialState, object: nil)

        registerCell()
        configureDelegates()
        configureUI()
        
        if (UserDefaults.standard.value(forKey: "BikeState") as? String) != "bike" {
            collectionModel = [.trips, .support]
            self.bikeContentView.layoutIfNeeded()
            self.bikeIconLeftConstraint.constant = self.bikeContentView.frame.width - self.bikeView.frame.width - 4
            self.bikeTitleLbl.text = "SCOOTER_global_title".localized()
        } else {
            collectionModel = [.trips, .rates, .support]
            self.bikeIconLeftConstraint.constant = 4
            self.bikeTitleLbl.text = "MOBILE_guest_map_bike".localized()
        }
        self.view.setNeedsLayout()
        self.delegate?.didTappedButton(state: (UserDefaults.standard.value(forKey: "BikeState") as? String) == "bike" ? .bike : .scooter, isShowList: true)
        self.perform(#selector(self.changeSwitchState), with: nil, afterDelay: 0.9)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        joinNowView.layer.cornerRadius = joinNowView.frame.height / 2
        
        plusButton.layer.cornerRadius = plusButton.frame.height / 2
        balanceContentView.layer.cornerRadius = balanceContentView.frame.height / 2
        balanceContentView.layer.borderWidth = 1
        balanceContentView.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
        
        bikeContentView.layer.cornerRadius = bikeContentView.frame.height / 2
        bikeContentView.layer.borderWidth = 1
        bikeContentView.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
        
        bikeView.layer.cornerRadius = bikeView.frame.height / 2
    }
    
    @objc func updateUI() {
        self.tableView.reloadData()
    }
    
    @objc func updateFinansialState() {
        if let finansialModel = UserManager.share.debtState {
            self.joinNowView.backgroundColor = finansialModel.state == .Success ? UIColor.mimoYellow500 : UIColor.mimoBlackWith025alpha
            //self.bikeView.backgroundColor = finansialModel.state == .Success ? UIColor.mimoYellow500 : UIColor.mimoBlackWith025alpha
        }
    }
    
    @objc func willEnterForeground() {
//        bikeView.play()
    }
    
    @objc func userChanged() {
        configureUI()
    }
    
    
    //MARK: - Methods
    
    // configure delegates
    private func configureDelegates() {
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    private func registerCell() {
        tableView.register(UINib(nibName: HomeSheetSupportTableViewCell.reuseIdentifier(), bundle: nil), forCellReuseIdentifier: HomeSheetSupportTableViewCell.reuseIdentifier())
    }

    ///configure user interface
    func configureUI() {
        if let finansialModel = UserManager.share.debtState {
            self.joinNowView.backgroundColor = finansialModel.state == .Success ? UIColor.mimoYellow500 : UIColor.mimoBlackWith025alpha
            //self.bikeView.backgroundColor = finansialModel.state == .Success ? UIColor.mimoYellow500 : UIColor.mimoBlackWith025alpha
        }
        
        
        
        self.viewModel.getUser { [weak self] (result) in
            switch result {
            case .success(let user):
                self?.userResult = user
                if (UserDefaults.standard.value(forKey: "BikeState") as? String) == "bike" {
                    self?.minutesLabel.text = user.minutes.description
                } else {
                    self?.minutesLabel.text = "0"
                }
            case .failure: break
            }
        }
        
        self.viewModel.getUserAccount { [weak self] (result) in
            switch result {
            case .success(let user):
                self?.userAccountResult = user
                if (UserDefaults.standard.value(forKey: "BikeState") as? String) == "bike" {
                    self?.minutesLabel.text = user.minutes.description
                } else {
                    self?.minutesLabel.text = "0"
                }
            case .failure: break
            }
        }
        
        self.viewModel.walletInfo { [weak self] (result) in
            switch result {
            case .success(let wallet):
                QRStore.sharedInstance.currentBanalce = Double(wallet.balance.description) ?? 0.0
                if (wallet.balance - (self?.usertDebt ?? 0.0)) < 0 {
                    self?.balanceLabel.textColor = .red
                }
                var balance = (wallet.balance - (self?.usertDebt ?? 0.0)).rounded()
                self?.balanceLabel.text = balance.description
            case .failure: break
            }
        }
        
        self.viewModel.getAvatar { [weak self] (avatarUrlStirng) in
            self?.avatarUrlStirng = avatarUrlStirng
        }
        
        joinNowView.layer.cornerRadius = Constant.CornerRadius.cornerRadiusFromScreenWidth24
        
        plusButton.layer.cornerRadius = Constant.CornerRadius.cornerRadiusFromScreenWidth19
        balanceContentView.layer.cornerRadius = Constant.CornerRadius.cornerRadiusFromScreenWidth8
        balanceContentView.layer.borderWidth = 1
        balanceContentView.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
        
        bikeContentView.layer.cornerRadius = Constant.CornerRadius.cornerRadiusFromScreenWidth24
        bikeContentView.layer.borderWidth = 1
        bikeContentView.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
        
        bikeView.layer.cornerRadius = Constant.CornerRadius.cornerRadiusFromScreenWidth20
//        bikeView.animationName = Constant.Lottie.bike
    }
    

    //MARK: - Actions

    @IBAction func joinNowTapped(_ sender: UIButton) {
        VibrateManager.vibrate()
        guard let finansialModel = UserManager.share.debtState else {
            UIAlertController.showError(message: "Incorrect financial state. Please restart application")
            
            return
        }

        if finansialModel.state == .Debt || finansialModel.state == .DebtOnCard || finansialModel.state == .DebtOnDevice {
            self.delegate?.openShowDebt(amount: finansialModel.additional ?? 0.0, wallets: finansialModel.wallets ?? [])
        } else {
            delegate?.didTappedButton(state: .scanQR, isShowList: false)
        }
        
//        if !(finansialModel.state == .Success) {
//            UIAlertController.showAction(title: "MOBILE__global_attention".localized(), message: finansialModel.message?.localized() ?? "", actions: ("OK", .default, { [weak self] _ in
//                guard let unwrapSelf = self else { return }
//
//                let walletVC = WalletViewController.initFromStoryboard(name: Constant.Storyboards.wallet)
//                unwrapSelf.walletNavigationController = UINavigationController(rootViewController: walletVC)
//
//                let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_arrow_left"), style: .plain, target: self, action: #selector(unwrapSelf.backButtonTapped))
//                walletVC.navigationItem.leftBarButtonItem = backButton
//
//                walletVC.user = unwrapSelf.userResult
//                walletVC.account = unwrapSelf.userAccountResult
//                walletVC.avataturURLString = unwrapSelf.avatarUrlStirng
//
//                unwrapSelf.present(unwrapSelf.walletNavigationController!, animated: true, completion: nil)
//            }))
//
//            return
//        }
        
    }
    
    @IBAction func bikeButtonTapped(_ sender: UIButton) {
        VibrateManager.vibrate()
        UIView.setAnimationsEnabled(true)
        if (UserDefaults.standard.value(forKey: "BikeState") as? String) == "bike" {
            UserDefaults.standard.set("scooter", forKey: "BikeState")
            self.bikeIconLeftConstraint.constant = self.bikeContentView.frame.width - self.bikeView.frame.width - 4
            self.bikeTitleLbl.text = "SCOOTER_global_title".localized()
        } else {
            UserDefaults.standard.set("bike", forKey: "BikeState")
            self.bikeIconLeftConstraint.constant = 4
            self.bikeTitleLbl.text = "Bike"
        }
        self.view.setNeedsLayout()
        UIView.animate(withDuration: 0.8) {
            self.view.layoutIfNeeded()
        } completion: { isFinishedd in
            self.changeState()
        }
        
       
    }
    
    func changeState() {
        self.delegate?.didTappedButton(state: (UserDefaults.standard.value(forKey: "BikeState") as? String) == "bike" ? .bike : .scooter, isShowList: false)
        self.perform(#selector(self.changeSwitchState), with: nil, afterDelay: 0.9)
    }
    
    func  animateCircleView() {
        if (UserDefaults.standard.value(forKey: "BikeState") as? String) == "bike" {
            UserDefaults.standard.set("scooter", forKey: "BikeState")
            self.bikeIconLeftConstraint.constant = self.bikeContentView.frame.width - self.bikeView.frame.width - 4
            self.bikeTitleLbl.text = "SCOOTER_global_title".localized()
        } else {
            UserDefaults.standard.set("bike", forKey: "BikeState")
            self.bikeIconLeftConstraint.constant = 4
            self.bikeTitleLbl.text = "MOBILE_guest_map_bike".localized()
        }
        self.view.layoutIfNeeded()
    }
    
    @objc func changeSwitchState() {
        guard let finansialModel = UserManager.share.debtState else {
            UIAlertController.showError(message: "Incorrect financial state. Please restart application")

            return
        }
        
        if !(finansialModel.state == .Success) && ((UserDefaults.standard.value(forKey: "BikeState") as? String) == "bike") {
            UIAlertController.showAction(title: "MOBILE__global_attention".localized(), message: finansialModel.message?.localized() ?? "", actions: ("OK", .default, { [weak self] _ in
                guard let unwrapSelf = self else { return }

                let walletVC = WalletViewController.initFromStoryboard(name: Constant.Storyboards.wallet)
                unwrapSelf.walletNavigationController = UINavigationController(rootViewController: walletVC)

                let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_arrow_left"), style: .plain, target: self, action: #selector(unwrapSelf.backButtonTapped))
                walletVC.navigationItem.leftBarButtonItem = backButton

                walletVC.user = unwrapSelf.userResult
                walletVC.account = unwrapSelf.userAccountResult
                walletVC.avataturURLString = unwrapSelf.avatarUrlStirng

                unwrapSelf.present(unwrapSelf.walletNavigationController!, animated: true, completion: nil)
            }))

            return
        }

    }
    
    @IBAction func plusButtonTapped(_ sender: UIButton) {
        VibrateManager.vibrate()
        let walletVC = WalletViewController.initFromStoryboard(name: Constant.Storyboards.wallet)
        self.walletNavigationController = UINavigationController(rootViewController: walletVC)
        
        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_arrow_left"), style: .plain, target: self, action: #selector(backButtonTapped))
        walletVC.navigationItem.leftBarButtonItem = backButton
        
        walletVC.user = userResult
        walletVC.account = userAccountResult
        walletVC.avataturURLString = avatarUrlStirng
        
        self.present(walletNavigationController!, animated: true, completion: nil)
    }
    
    @objc func backButtonTapped() {
        self.walletNavigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc func planbackButtonTapped() {
        self.planNavVC?.dismiss(animated: true, completion: nil)
    }
}


//MARK: - TableView delegate dataSource

extension HomeScanQrSheetViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return collectionModel.count

    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = HomeSheetSupportTableViewCell.reuseIdentifire(from: tableView, indexPath: indexPath)
        let model = collectionModel[indexPath.row]
        cell.titleLabel.text = model.title
        cell.iconImageView.image = model.icon
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constant.Height.height70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        VibrateManager.vibrate()
        delegate?.didSelectCollection(state: collectionModel[indexPath.row])
    }
}
