//
//  AccountViewController.swift
//  MimoBike
//
//  Created by Vardan on 06.05.21.
//

import UIKit
import Lottie
import SwiftUI

final class AccountViewController: UIViewController, StoryboardInitializable {

    
    //MARK: - Outlets
    
    var blurView: AccountHintView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contextContainerView: UIView!
    @IBOutlet weak var userPorfileImageView: CircleImageView!
    @IBOutlet weak var userPhoneLabel: UILabel!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var carbonView: ProfileActivityView!
    @IBOutlet weak var caloriesView: ProfileActivityView!
    @IBOutlet weak var distanceView: ProfileActivityView!
    @IBOutlet weak var contentViewHeightConstaint: NSLayoutConstraint!
    
    @IBOutlet weak var navBar: UINavigationBar!
    
    var tripNavigationController: UINavigationController?

    
    var storageManager = StorageManager()
    private(set) var accountViewController: AccountBoardController! {
        didSet {
            accountViewController.tableView.reloadData()
        }
    }
    
    private(set) var settingsViewController: SettingsBoardController! {
        didSet {
            settingsViewController.tableView.reloadData()
        }
    }
    
    private(set) var userViewController: UserBoardController! {
        didSet {
            userViewController.tableView.reloadData()
        }
    }
    
    
    // MARK: - Properties
    
    private let accountViewModel = AccountViewModel()

    var user: UserResponse?
    var account: UserResponse?
    var avataturURLString: String?

    
    //MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()
        
        //startFirstLabel.text = "MOBILE_map_minimum_requirments".localized()//.replacingOccurrences(of: "[num]", with: "99.9").replacingOccurrences(of: "[currency]", with: "MOBILE_global_total_currency".localized())
        scrollView.animateOut(animatable: false)
        getUser()
        
        NotificationCenter.default.addObserver(self, selector: #selector(verified), name: Constant.Notifications.accountVerified, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(userChanged), name: Constant.Notifications.updateUserUI, object: nil)
        
        navBar.topItem?.localizedTitle = "MOBILE_global_profile"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.configureUI()
    }
    
    @objc func userChanged() {
        getUser()
    }
    
    @objc func verified() {
        UserManager.share.getUser { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let userResult):
                self.handleUserData(userResult)
            case .failure(let error):
                UIAlertController.showError(message: error.localizedDescription)
                self.scrollView.animateIn(animatable: true)
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.contentInset.bottom = view.safeAreaInsets.bottom
    }
    
    //MARK: - Methods
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let accountViewController = segue.destination as? AccountBoardController {
            self.accountViewController = accountViewController
            self.view.layoutSubviews()
            self.handleSettingBoardActions()
            
            self.view.layoutIfNeeded()
        } else if let settingsController = segue.destination as? SettingsBoardController {
            self.settingsViewController = settingsController
        } else if let userController = segue.destination as? UserBoardController {
            self.userViewController = userController
        }
    }
    
    // configure user interface
    private func configureUI() {
        let window = UIApplication.shared.windows.first
        let _ = window?.safeAreaInsets.top ?? 0
        let _ = window?.safeAreaInsets.bottom ?? 0
        blurView = AccountHintView.initFromStoryboard(name: Constant.Storyboards.account)
        blurView.view.frame = self.view.bounds
        print("view.safeAreaInsets.top = \(view.safeAreaInsets.top)")
        blurView.circleTopConstraint.constant = (view.getConvertedFrame(fromSubview: accountViewController.addAnimationView)?.minY ?? 0.0) - view.safeAreaInsets.top
        blurView.circleVieew.layoutIfNeeded()
        contentViewHeightConstaint.constant = accountViewController.sizedTableView.intrinsicContentSize.height
        blurView.textLabel.text = "MOBILE_map_minimum_requirments".localized()//.replacingOccurrences(of: "[num]", with: "99.9").replacingOccurrences(of: "[currency]", with: "MOBILE_global_total_currency".localized())
        accountViewController.delegate = self
        accountViewModel.getPhoneNumber { [weak self] phoneNumber in
            guard let self = self else { return }
            self.userPhoneLabel.text = phoneNumber
        }
        
        
        configTutorialView(isShow: !UserDefaults.standard.bool(forKey: "isAlreadyOpenPaymentTutorial"))
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFindBike))
        blurView.view.addGestureRecognizer(tapGesture)
    }
    
    @objc func tapFindBike() {
        blurView.view.isHidden = true
    }
    
    private func goToWalletVC() {
        guard let user = user else { return }
        guard let account = account else { return }
        let walletVC = WalletViewController.initFromStoryboard(name: Constant.Storyboards.wallet)
//        navigationController?.isNavigationBarHidden = false
        walletVC.user = AccountMapper.toUserResult(from: user)
        walletVC.account = AccountMapper.toUserResult(from: account)
        walletVC.avataturURLString = avataturURLString
        
        let walletNavVC = WalletNavigationController(rootViewController: walletVC)
        self.present(walletNavVC, animated: true)
    }
    
    private func configTutorialView(isShow: Bool) {
        view.addSubview(blurView.view)
        blurView.view.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        blurView.blurView.effect = UIBlurEffect(style: .dark)
        blurView.blurView.alpha = 0.45
        blurView.delegate = self
        blurView.view.layoutIfNeeded()
        self.view.layoutIfNeeded()
        blurView.blurView.layoutIfNeeded()
        blurView.view.backgroundColor = UIColor.white.withAlphaComponent(0)
        blurView.view.isHidden = true //!isShow
        print(blurView.view.frame)
        self.perform(#selector(updateblurFrame), with: nil, afterDelay: 0.2)
    }
    
    @objc func updateblurFrame() {
        blurView.blurView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height)
        print("self frame = \(self.view.frame)")

    }

    private func getUser() {
        UserWalletManager.shared.getWallet {[weak self] result in
            switch result {
            case .success(let model):
                self?.accountViewController.setUserWallet(model)
            case .failure(let error):
                UIAlertController.showError(message: error.localizedDescription)
            }
        }
        
        UserManager.share.getUser { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let userResult):
                self.handleUserData(userResult)
            case .failure(let error):
                print(error)
                MILoader.hide()
                UIAlertController.showError(message: error.localizedDescription)
                self.scrollView.animateIn(animatable: true)
            }
        }
        
        UserManager.share.getAccount { result in
            switch result {
            case .success(let userResult):
                print(userResult)
                self.handleUserAccountData(userResult)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    private func handleUserData(_ user: UserResponse) {
        self.user = user
        self.getAvatar()
        let _ = user.distance ?? 1.0
        self.accountViewController.sizedTableView.reloadData()
        self.accountViewController.setUser(user)
        scrollView.animateIn(animatable: true)
        userNameLabel.text = "\(user.name ?? "") \(user.surname ?? "")"
        accountViewController.sizedTableView.reloadData()
        contentViewHeightConstaint.constant = accountViewController.sizedTableView.intrinsicContentSize.height
        
    }
     
    private func handleUserAccountData(_ user: UserResponse) {
        self.account = user
        let distance = user.distance ?? 1.0
        self.accountViewController.sizedTableView.reloadData()
        self.accountViewController.setUserPackage(user.package)
        self.accountViewController.setUserTarrif(user.tariff)
        scrollView.animateIn(animatable: true)
        accountViewController.freeMinutesDurationLabel.text = "\(user.minutes ?? 0)"
        
        distanceView.setup(iconImageView: UIImage(named: "ic_distance")!, decimal: String(format: "%.f", ((distance / 1000.0))), currency: "MOBILE_global_km".localized(), decimalDescription: "MOBILE_global_distance".localized())
        caloriesView.setup(iconImageView: UIImage(named: "ic_ccal_fire")!, decimal: String(format: "%.f", ((distance / 1000.0) * 21)), currency: "MOBILE_global_ccal".localized(), decimalDescription: "MOBILE_global_calories".localized())
        carbonView.setup(iconImageView: UIImage(named: "ic_carbon")!, decimal: String(format: "%.f", (distance / 19000)), currency: "".localized(), decimalDescription: "MOBILE_global_carbon".localized())
        accountViewController.sizedTableView.reloadData()
        contentViewHeightConstaint.constant = accountViewController.sizedTableView.intrinsicContentSize.height
        
    }
    /// Get avatar url and set image
    private func getAvatar() {
        
        self.userPorfileImageView.setImage(user?.avatar?.getURL()?.absoluteString, defaultImage: #imageLiteral(resourceName: "ic_default_avatar"))
    }
    
    /// Logout and remove all saved data
    private func logOut() {
        if UserDefaults.standard.bool(forKey: "isHaveActiveTrip") {
            self.showAlertMessage("MOBILE_you_have_active_trip".localized())
        } else {
            self.showAlertMessage("MOBILE__profile_log_out_message".localized(), actionText: ["MOBILE__confirmation_yes".localized(), "MOBILE__confirmation_no".localized()]) { text in
                switch text {
                case "MOBILE__confirmation_yes".localized():
                    self.accountViewModel.logout {
                        BaseRouter.shared.showSplashView()
                    }
                case "MOBILE__confirmation_no".localized():
                    print("no")
                default: break
                }
            }
        }
        
    }
    
    
    /// Delete Account will close account
    private func deleteAccount() {
        if UserDefaults.standard.bool(forKey: "isHaveActiveTrip") {
            self.showAlertMessage("MOBILE_you_have_active_trip".localized())
        } else {
            self.showAlertMessage("MOBILE_profice_deleete_confirm".localized(), actionText: ["MOBILE__confirmation_yes".localized(), "MOBILE__confirmation_no".localized()]) { text in
                switch text {
                case "MOBILE__confirmation_yes".localized():
                    self.accountViewModel.deleteAccount {

//                        let splashVC = SplashViewController.initFromStoryboard(name: Constant.Storyboards.splash)
//                        self.setRootViewController(splashVC)
                        BaseRouter.shared.showSplashView()
                    }
                case "MOBILE__confirmation_no".localized():
                    print("no")
                default: break
                }
            }
        }
    
}
    
    private func handleSettingBoardActions() {
        accountViewController.settingsViewController.actions = {[weak self] status in
            switch status {
            case .rates:
                self?.ratesTapped()
            case .agreement:
                self?.agreementTapped()
            case .howToUse:
                self?.howToUseTapped()
            case .logout:
                self?.logOutTapped()
            case .privacyPolicy:
                self?.privacyPolicyTapped()
            case .settings:
                self?.settingsTapped()
            case .partnership:
                self?.partnershipTapped()
            case .support:
                self?.supportTapped()
            case .deleteAccount:
                self?.deleteAccountTapped()
            }
        }
    }
    
    private func modifyUserPorfile() {
        
        let completeAccountViewController = CompleteProfileViewController.config(with: true, existingModel: user, delegate: self)
        present(completeAccountViewController, animated: true, completion: nil)
    }
    
    
    //MARK: - Actions
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        dismiss(animated: true) {
            NotificationCenter.default.post(name: Constant.Notifications.updateBlureState, object: nil)
        }
    }

    @IBAction func addPaymentTutorialButtonTapped(_ sender: AnimatedButton) {
        UserDefaults.standard.setValue(true, forKey: "isAlreadyOpenPaymentTutorial")
        configTutorialView(isShow: false)
        goToWalletVC()
    }
    
    @IBAction func editProfile() {
        modifyUserPorfile()
    }
    
    @IBAction func avatarTapped(_ sender: UIButton) {
        modifyUserPorfile()
    }
    
    @IBAction func aboutUsTapped(_ sender: UIButton) {
    
    }
    
    @IBAction func scanAction() {
        ScanRouter.shared.showQrScanViewController(self, delegate: self)
    }
    
    func howToUseTapped() {
        let howtoUseViewController = HowToUseNavigationViewController.initFromStoryboard(name: Constant.Storyboards.accountCover)
        
        self.present(howtoUseViewController, animated: true, completion: nil)
    }
    
    func supportTapped() {
        let supportViewController = SupportNavigationViewController.initFromStoryboard(name: Constant.Storyboards.accountCover)
        self.present(supportViewController, animated: true, completion: nil)
    }
    
    func settingsTapped() {
        let settingViewController = SettingNavigationViewController.initFromStoryboard(name: Constant.Storyboards.accountCover)
        self.present(settingViewController, animated: true, completion: nil)
    }
    
    func partnershipTapped() {
//        ProfileRouter.shared.showPartnershipViewController(self)
        self.present(UIHostingController(rootView: PartnershipView()), animated: true)
    }
    
    func privacyPolicyTapped() {
        let privacyPolicyViewController = PrivacyPolicyViewController.initFromStoryboard(name: Constant.Storyboards.accountCover)
        
        self.present(UINavigationController(rootViewController: privacyPolicyViewController), animated: true, completion: nil)
    }
    
    func agreementTapped() {
        let agreementViewController = AgreementNavigationViewController.initFromStoryboard(name: Constant.Storyboards.accountCover)
        self.present(agreementViewController, animated: true, completion: nil)
    }
    
    func ratesTapped() {
        let tripsListViewController = TripsNavigationController.initFromStoryboard(name: Constant.Storyboards.wallet)
//        self.tripNavigationController = UINavigationController(rootViewController: tripsListViewController)
//
//        if #available(iOS 13, *) {
//            self.tripNavigationController?.navigationBar.standardAppearance = UINavigationBarAppearance()
//            self.tripNavigationController?.navigationBar.standardAppearance.configureWithDefaultBackground()
//            self.tripNavigationController?.navigationBar.barTintColor = .white
//        }
//        else {
//            self.tripNavigationController?.navigationBar.barTintColor = .white
//        }
//        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_arrow_left"), style: .plain, target: self, action: #selector(backButtonTapped))
//        tripsListViewController.navigationItem.leftBarButtonItem = backButton
        self.present(tripsListViewController, animated: true, completion: nil)
    }
    
    @objc func backButtonTapped() {
        self.tripNavigationController?.dismiss(animated: true, completion: nil)
    }
    
    func logOutTapped() {
        logOut()
    }
    
    func deleteAccountTapped() {
        deleteAccount()
    }
}

extension AccountViewController: MimoScanQrViewControllerDelegate {
    
    func didFinishScan(with value: String, type: MimoType) {
        switch type {
        case .scooter:
            ScooterRouter.shared.showScooterViewController(navigationController, scannedQR: value)
        case .bike:
            BikeRouter.shared.showBikeViewController(navigationController, scannedQR: value)
        default:
            break
        }
    }
}

extension AccountViewController: AccountHintViewDelegate {
    
    func closeHint() {
        blurView.view.isHidden = true
        UserDefaults.standard.setValue(true, forKey: "isAlreadyOpenPaymentTutorial")
        goToWalletVC()
    }
}

extension AccountViewController: AccountBoardActions {
    
    func plusTapped() {
        goToWalletVC()
    }
    
    func verifyEmailTapped() {
        if let email = user?.email {
            let verifyController = VerifyEmailConfigurator.config(with: email)
            let navVC = UINavigationController(rootViewController: verifyController)
            verifyController.addCloseButton()
            self.present(navVC, animated: true)
        } else {
            modifyUserPorfile()
        }
    }

    func packageTapped() {
        let planController = MIPlansViewController.initFromStoryboard(name: "MIPlan")
        let navVC = UINavigationController(rootViewController: planController)
        planController.addCloseButton()
        
        self.present(navVC, animated: true)
//        navigationController?.pushViewController(navVC, animated: true)
    }
}

extension AccountViewController: CompleteProfileViewControllerDelegate {
    
    func didUpdateModel(new model: UserModelLight) {
        MILoader.show()
        
        UserManager.share.getUser { [weak self] result in
            switch result {
            case .success(let user):
                self?.updateUser(settings: user.settings, model: model)
            case .failure(let error):
                self?.showErrorAlertMessage(error.localizedDescription)
            }
        }
        
    }
    
    private func updateUser(settings: UserResponse.SettingsModel?, model: UserModelLight) {
        UserManager.share.updateUser(name: model.name, surname: model.surname, gender: model.gender, email: model.email, birthday: model.birthday, bio: model.bio, settings: settings) {[weak self] result in
            switch result {
            case .success(let userResponse):
                MILoader.hide()
                if let image = model.avatar {
                    let sesson = SessionNetwork()
                    sesson.request(with: URLBuilder(from: ImageUploadAPI.upload(image: image))) { res in
                        self?.storeAvatar(userResponse.avatar)
                        self?.getAvatar()
                        NotificationCenter.default.post(name: Constant.Notifications.updateUserPicture, object: nil)
                    }
                }
                self?.handleUserData(userResponse)
            case .failure(let error):
                MILoader.hide()
                switch error as? NetworkError {
                case .invalidParse(let message):
                    UIAlertController.showError(message: message.localized())
                default:
                    UIAlertController.showError(message: "Server  error!")
                }
            }
        }
    }
    
    private func storeAvatar(_ avatar: AvatarResponse?) {
        guard let avatarId = avatar?.id,
              let node = avatar?.node else { return }
        let avatar = "https://\(node).impulsepower.ru/files?id=\(avatarId)&token="
        storageManager.store(avatar, key: .avatar)
    }
}

