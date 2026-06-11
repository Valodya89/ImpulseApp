//
//  ScooterPlanViewController.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/17/22.
//

import UIKit
import SwiftUI

protocol ScooterPlanViewControllerDelegate: AnyObject {

    func didSelectBookNow(scooterId: String)
    func didStartLeasedScooter(with scooterId: String)
    func didStopLeasedScooter(with scooterId: String)
    func didOpenLeasedScooter(with scooterId: String)
}

final class ScooterPlanViewController: BaseViewController, StoryboardInitializable, ShowDebtViewControllerDdelegate {
   
    func didSelectTransfer() {
        
    }
    
    func didSelectTransfer(wallet: WalletDebts) {
        
    }
    
    func didSelectPayDdebt() {
        self.dismiss(animated: true)
        self.openWalletVC()
    }
    
    // MARK: Outlets
    @IBOutlet weak var choosePlanTitleLabel: UILabel!
    @IBOutlet weak var choosePlanTableView: UITableView!
    @IBOutlet weak var bookNowButton: UIButton!
    @IBOutlet weak var letUsGoButton: UIButton!
    @IBOutlet private weak var startLeasedScooterButton: UIButton!
    @IBOutlet private weak var stopLeasedScooterButton: UIButton!
    @IBOutlet private weak var openLeasedScooterButton: UIButton!
    
    var scooterId: String = ""
    var leasedScooters: [String]?
    var singleScooterResult: SingleScooterResponse?
    var selectedSpeedTariff: SpeedTariff?
    var billingTarifId = ""
    var speedTariffsId = ""
    var billCounter = 0
    var viewModel = WalletViewModel()
    var minBalanceVC: DebtInfoViewController?
    var showDebtVc: ShowDebtViewController?
    var insuaranceSwitchIsOn: Bool = false
    private let splashViewModel = SplashViewModel()
    var currencySymbol = ""
    private let storageManager = StorageManager()
    
    weak var delegate: ScooterPlanViewControllerDelegate?
    weak var testDelegate: TestDelegate?
    
    lazy var homeViewController: HomeViewController = {
        let homeVC = HomeViewController.initFromStoryboard(name: Constant.Storyboards.home)
        homeVC.state = .smallBottomSheet
        return homeVC
    }()
    
//    private let insuaranceSwitch: UISwitch = {
//        let uiSwitch = UISwitch()
//        uiSwitch.translatesAutoresizingMaskIntoConstraints = false
//        return uiSwitch
//    }()
    
    private let homeViewModel = HomeViewModel()
    var previewCells = 3
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
//        choosePlanTableView.addSubview(insuaranceSwitch)
        self.choosePlanTableView.isHidden = true
        getBalancee(complation: { isHaveBalance in
            if isHaveBalance {
                
            }
        })
        homeViewModel.getInsurancePrice()
//        NSLayoutConstraint.activate([
//            insuaranceSwitch.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            insuaranceSwitch.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
//        insuaranceSwitch.onTintColor = UIColor.mimoYellow500
//        insuaranceSwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        getSingleScooterData()
    }
    
    func getSingleScooterData() {
        homeViewModel.getScooterDetails(id: scooterId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                MILoader.hide()
                self.singleScooterResult = data
                QRStore.sharedInstance.speedTariffs = data.speedTariffs ?? []
                DispatchQueue.main.async {
                    self.choosePlanTableView.isHidden = false
                    self.setupTableView()
                }
                print(data)
            case .failure(let error):
                MILoader.hide()
                switch error {
                case .validatorError(let message):
                    UIAlertController.showError(message: message.localized())
                default:
                    UIAlertController.showError(message: "Server error!")
                }
                print(error)
            }
        }
    }
    
    // MARK: Methods
    private func setupViews() {
        bookNowButton.layer.cornerRadius = bookNowButton.frame.height / 2
        bookNowButton.layer.borderWidth = 1
        bookNowButton.layer.borderColor = UIColor(named: "mimoDarkGray")?.cgColor
        letUsGoButton.layer.cornerRadius = letUsGoButton.frame.height / 2
        
        let isScooterLeased = leasedScooters?.contains(scooterId) ?? false
        
        bookNowButton.isHidden = isScooterLeased
        letUsGoButton.isHidden = isScooterLeased
        startLeasedScooterButton.isHidden = !isScooterLeased
        stopLeasedScooterButton.isHidden = !isScooterLeased
        openLeasedScooterButton.isHidden = !isScooterLeased
    }
    
    private func setupTableView() {
        choosePlanTableView.delegate = self
        choosePlanTableView.dataSource = self
        singleScooterResult?.speedTariffs?.sort(by: {$0.speed ?? 0 < $1.speed ?? 0})
        singleScooterResult?.speedTariffs?[2].isSelected = true
        singleScooterResult?.billingTariffs?[0].isSelected = true
        selectedSpeedTariff = singleScooterResult?.speedTariffs?.last
        choosePlanTableView.register(ScooterInformationTableViewCell.cellNibName, forCellReuseIdentifier: ScooterInformationTableViewCell.cellIdentifier)
        choosePlanTableView.register(SpeedChargeTableViewCell.cellNibName, forCellReuseIdentifier: SpeedChargeTableViewCell.cellIdentifier)
        choosePlanTableView.register(InsuranceTableViewCell.cellNibName, forCellReuseIdentifier: InsuranceTableViewCell.cellIdentifier)
        choosePlanTableView.register(ChoosePlanTableViewCell.cellNibName, forCellReuseIdentifier: ChoosePlanTableViewCell.cellIdentifier)
        choosePlanTableView.register(PlanDescriptionTableViewCell.cellNibName, forCellReuseIdentifier: PlanDescriptionTableViewCell.cellIdentifier)
        choosePlanTableView.reloadData()
    }
    
    private func goToHomeVC(scooter: ScooterStateModel) {
//        self.homeViewController.view.backgroundColor = .white
//        self.homeViewController.updateControllerState(state: .smallBottomSheet)
//        self.homeViewController.updateControllerState(state: .scanScooter(scooter: scooter) )
//        NotificationCenter.default.post(name: .init(rawValue: "UpdateHomeControllerState"), object: nil, userInfo: ["scooter": scooter])
//        self.testDelegate?.updateHomeControllerState(scooter: scooter)
//        self.dismiss(animated: true)
//        let navVC = UINavigationController(rootViewController: homeViewController)
//        setRootViewController(navVC)
        
        let messageService: MessageServiceProtocol = Resolver.resolve()
        messageService.publish(.scooterScanned)
        self.dismiss(animated: true)
    }
    
    func getBalancee(complation: @escaping ((_ isHaveBalance: Bool) -> Void)) {
        MILoader.show()
        self.viewModel.walletInfo { info in
            if case .success(let model) = info {
                self.currencySymbol = model.currency.currencySymbol
                self.choosePlanTableView.reloadData()
                // String(model.balance)
//                MILoader.hide()
                QRStore.sharedInstance.currentBanalce = model.balance
//                let card = UserManager.share.walletModel?.card
//                if QRStore.sharedInstance.currentBanalce < 5000 &&  card == nil {
////                    UIAlertController.showError(message: "SCOOTER_min_balance_error".localized())
//                    self.showErrorMinBalanceVC()
//                    complation(false)
//                } else {
                    complation(true)
//                }
            } else if case .failure(_) = info {
                MILoader.hide()
                complation(false)
            }
        }
    }
    
    @available(iOS 16.0, *)
    @objc private func switchChanged(_ sender: UISwitch) {
        if sender.isOn {
            openSheet()
        }
    }
    
    @available(iOS 16.0, *)
    private func openSheet() {
        let viewModel = InsuranceViewModel()

            var swiftUIView = InsuranceView(
                viewModel: viewModel
            ) { [weak self] in
                // 👇 This will be called from SwiftUI
                self?.choosePlanTableView.reloadData()
            }
        swiftUIView.onAction = { [weak self] in
            guard let self else { return }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                let nowMs = Date().timeIntervalSince1970 * 1000.0
                let plus24hMs = nowMs + 24 * 60 * 60 * 1000.0

                StorageManager().store(plus24hMs, key: .activeInsuranceEnd)

                // don't call setupTableView again (call it once in viewDidLoad)
                self.choosePlanTableView.reloadData()
                // or even better:
                 self.choosePlanTableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
            }
        }
        
        swiftUIView.onDismiss = { [weak self] in
            guard let self else { return }
            self.choosePlanTableView.reloadRows(at: [IndexPath(row: 2, section: 0)], with: .automatic)
        }
        
        let hostingController = UIHostingController(rootView: swiftUIView)
        if let sheet = hostingController.sheetPresentationController {
            sheet.detents = [
                .custom(identifier: .init("dynamic")) { context in
                    return context.maximumDetentValue * 0.65
                }
            ]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 20
        }
        
        present(hostingController, animated: true)
    }
    
    func showErrorMinBalanceVC(message: String, isShowOK: Bool = true) {
        self.present(ScooterErrorViewController(message: message.localized(), isReplenishable: !isShowOK, onReplenish: { [weak self] in
            self?.openWallet()
        }), animated: true)
    }
    
    func openWalletVC() {
        var walletNavigationController: UINavigationController?
        let walletVC = WalletViewController.initFromStoryboard(name: Constant.Storyboards.wallet)
        walletNavigationController = UINavigationController(rootViewController: walletVC)
        walletNavigationController?.navigationBar.barTintColor = .white
        walletNavigationController?.navigationBar.backgroundColor = .white
        
        self.present(walletNavigationController!, animated: true, completion: nil)
    }
    
    // MARK: Actions
    @IBAction private func dismissButtonAction(_ sender: UIButton) {
        dismiss(animated: true)
    }
    
    @IBAction func bookNowButtonAction(_ sender: UIButton) {
        homeViewModel.deactivateInsurance()
//        self.delegate?.didSelectBookNow(scooterId: scooterId)
//        dismiss(animated: true)
    }
    
    @IBAction func letUsGoButtonAction(_ sender: UIButton) {
        splashViewModel.getFinansialState { [weak self] result in
            guard let self = self else { return }
            
            switch result {
                case .success(let state):
                    if state.state != UserManager.share.debtState?.state {
                        UserManager.share.debtState = state
                        NotificationCenter.default.post(name: Constant.Notifications.updateFinansialState, object: nil)
                    } else if state.state == FinancialState.Debt {
                        self.showDebtVc = ShowDebtViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
                        self.showDebtVc?.modalPresentationStyle = .fullScreen
                        self.showDebtVc?.view.backgroundColor = .white
                        self.showDebtVc?.updateUI(amount: state.additional ?? 0.0, wallets: state.wallets ?? [])
                        self.showDebtVc?.delegate = self
                        self.present(self.showDebtVc!, animated: true)
                    } else {
                        self.getBalancee(complation: { [weak self] isHaveBalance in
                            guard let self else { return }
                            
                            if isHaveBalance {
                                if self.speedTariffsId == "" {
                                    self.speedTariffsId = self.singleScooterResult?.speedTariffs?.last?.id ?? ""
                                }
                                
                                if self.billingTarifId == "" {
                                    self.billingTarifId = self.singleScooterResult?.billingTariffs?.first?.id ?? ""
                                }
                                //40.220469, 44.485995 Davtashen // 40.803909, 43.821601 Gyumri
                                MILoader.show()
                                self.homeViewModel.scanScooter(id: self.singleScooterResult?.scooter?.id ?? "", insurance: insuaranceSwitchIsOn, speedModeTariff: self.speedTariffsId, billingModeTariff: self.billingTarifId, longitude: MALocation.current.currentLocation?.coordinate.longitude ?? 0.0, latitude: MALocation.current.currentLocation?.coordinate.latitude ?? 0.0) { [weak self] result in
                                    guard let self = self else { return }
                                    
                                    switch result {
                                    case .success(let userResponse):
                                        UserManager.share.isHaveScooterTrip = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                                            MILoader.hide()
                                            self.goToHomeVC(scooter: userResponse)
                                        })
                                    case .failure(let err):
                                        MILoader.hide()
                                        switch (err) {
                                        case .tooFar(let message):
                                            self.showErrorMinBalanceVC(message: message, isShowOK: false)
                                        case .invalidParse(let message):
                                            UIAlertController.showError(message: message.localized())
                                        case .validatorError(let message):
                                            UIAlertController.showError(message: message.localized())
                                        case .responseError(let message):
//                                            if message == "SCOOTER_no_minimal_requirements" {
                                                self.showErrorMinBalanceVC(message: message)
//                                            } else {
//                                                UIAlertController.showError(message: message.localized())
//                                            }
                                        case .serverError:
                                            UIAlertController.showError(message: "Something went wrong!")
                                        }
                                        print("scan error = \(err.localizedDescription)")
                                        
                        //                MILoader.show(message: err.localizedDescription, animated: true, blocking: false, touchable: true)
                                    }
                                }
                            } else {
                                MILoader.hide()
                                return
                            }
                        })

                    }
                case .failure(let error):
                    UIAlertController.showError(message: error.message.localized())
            }
        }
    }
    
    @IBAction private func startLeasedScooterAction() {
        delegate?.didStartLeasedScooter(with: scooterId)
        dismiss(animated: true)
    }
    
    @IBAction private func stopLeasedScooterAction() {
        delegate?.didStopLeasedScooter(with: scooterId)
        dismiss(animated: true)
    }
    
    @IBAction private func openLeasedScooterAction() {
        delegate?.didOpenLeasedScooter(with: scooterId)
        dismiss(animated: true)
    }
}

extension ScooterPlanViewController: DebtInfoViewControllerDelegate {
    func didClose() {
        minBalanceVC?.dismiss(animated: true)
        self.openWalletVC()
    }
}

extension ScooterPlanViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
}

extension ScooterPlanViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if MimoMeta.appConfig.isInsuranceAvailable {
            return (singleScooterResult?.billingTariffs?.count ?? 0) + 4 // with insurance should be 7
        } else {
            return (singleScooterResult?.billingTariffs?.count ?? 0) + 3
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if MimoMeta.appConfig.isInsuranceAvailable {
            cellsWithInsurance(tableView, cellForRowAt: indexPath)
        } else {
            cellsWithoutInsurance(tableView, cellForRowAt: indexPath)
        }
    }
    
    func cellsWithInsurance(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
            case 0:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: ScooterInformationTableViewCell.cellIdentifier, for: indexPath) as? ScooterInformationTableViewCell else { return UITableViewCell() }
                if let singleScooterResult = singleScooterResult {
                    cell.setData(singleScooterDto: singleScooterResult)
                }
                return cell
            case 1:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: SpeedChargeTableViewCell.cellIdentifier, for: indexPath) as? SpeedChargeTableViewCell else { return UITableViewCell() }
                if let singleScooterResult = singleScooterResult {
                    cell.setData(singleScooterDto: singleScooterResult)
                }
                cell.delegate = self
                cell.speedChargeCollectionView.reloadData()
                return cell
            case 2:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: InsuranceTableViewCell.cellIdentifier, for: indexPath) as? InsuranceTableViewCell else { return UITableViewCell() }
                cell.configure()
            cell.currencySymbol = self.currencySymbol
            cell.onInsuranceToggled = { [weak self, weak cell] isOn in
                guard let self, let cell else { return }
                if isOn && cell.isHaveActiveInsurance == nil {
                    if #available(iOS 16.0, *) {
                        self.openSheet()
                    }
                }
                self.insuaranceSwitchIsOn = isOn
            }
                return cell
            case 3:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: ChoosePlanTableViewCell.cellIdentifier, for: indexPath) as? ChoosePlanTableViewCell else { return UITableViewCell() }
                cell.delegate = self
                if let singleScooterResult = singleScooterResult {
                    if let speed = self.selectedSpeedTariff ?? self.singleScooterResult?.speedTariffs?.last {
                        cell.setData(singleScooterDto: singleScooterResult, speedTariff: speed)
                    }
                }
                return cell
            default:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: PlanDescriptionTableViewCell.cellIdentifier, for: indexPath) as? PlanDescriptionTableViewCell else { return UITableViewCell() }
                if let singleScooterResult = singleScooterResult {
                    if let speed = self.selectedSpeedTariff ?? self.singleScooterResult?.speedTariffs?.last {
                        if billCounter == singleScooterResult.billingTariffs?.count {
                            billCounter = 0
                        }
                        if  let bill = singleScooterResult.billingTariffs?[indexPath.row - 4] {
                            cell.setData(billingTarif: bill, speedTariff: speed)
                            billCounter +=  1
                        }
                    }
                }
                return cell
        }
    }
    
    func cellsWithoutInsurance(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
            case 0:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: ScooterInformationTableViewCell.cellIdentifier, for: indexPath) as? ScooterInformationTableViewCell else { return UITableViewCell() }
                if let singleScooterResult = singleScooterResult {
                    cell.setData(singleScooterDto: singleScooterResult)
                }
                return cell
            case 1:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: SpeedChargeTableViewCell.cellIdentifier, for: indexPath) as? SpeedChargeTableViewCell else { return UITableViewCell() }
                if let singleScooterResult = singleScooterResult {
                    cell.setData(singleScooterDto: singleScooterResult)
                }
                cell.delegate = self
                cell.speedChargeCollectionView.reloadData()
                return cell
            case 2:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: ChoosePlanTableViewCell.cellIdentifier, for: indexPath) as? ChoosePlanTableViewCell else { return UITableViewCell() }
                cell.delegate = self
                if let singleScooterResult = singleScooterResult {
                    if let speed = self.selectedSpeedTariff ?? self.singleScooterResult?.speedTariffs?.last {
                        cell.setData(singleScooterDto: singleScooterResult, speedTariff: speed)
                    }
                }
                return cell
            default:
                guard let cell = tableView.dequeueReusableCell(withIdentifier: PlanDescriptionTableViewCell.cellIdentifier, for: indexPath) as? PlanDescriptionTableViewCell else { return UITableViewCell() }
                if let singleScooterResult = singleScooterResult {
                    if let speed = self.selectedSpeedTariff ?? self.singleScooterResult?.speedTariffs?.last {
                        if billCounter == singleScooterResult.billingTariffs?.count {
                            billCounter = 0
                        }
                        if  let bill = singleScooterResult.billingTariffs?[indexPath.row - 3] {
                            cell.setData(billingTarif: bill, speedTariff: speed)
                            billCounter +=  1
                        }
                    }
                }
                return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension ScooterPlanViewController: SpeedChargeTableViewCellDelegate {
    func didSelectRow(speedTariff: SpeedTariff) {
        
        DispatchQueue.main.async {
            VibrateManager.vibrate()
            self.selectedSpeedTariff = speedTariff
            self.speedTariffsId = speedTariff.id ?? ""
            self.singleScooterResult?.speedTariffs?.enumerated().forEach({ (index, speedTarif) in
                if speedTariff.id == speedTarif.id {
                    self.singleScooterResult?.speedTariffs?[index].isSelected = true
                } else {
                    self.singleScooterResult?.speedTariffs?[index].isSelected = false
                }
            })
            self.billCounter = 0
            self.choosePlanTableView.reloadData()
        }
        //        self.choosePlanTableView.reloadRows(at: [IndexPath(row: 2, section: 0), IndexPath(row: 2, section: 0)], with: .automatic)
    }
}

extension ScooterPlanViewController: ChoosePlanTableViewCellDelegate {
    func didSelectRow(billingTariff: BillingTarif) {
        
        DispatchQueue.main.async {
            VibrateManager.vibrate()
            
            if billingTariff.mode == "MINUTE_BY_MINUTE" {
                self.billingTarifId = billingTariff.id ?? ""
                self.singleScooterResult?.billingTariffs?.enumerated().forEach({ (index, billingTarif) in
                    if billingTariff.id == billingTarif.id {
                        self.singleScooterResult?.billingTariffs?[index].isSelected = true
                    } else {
                        self.singleScooterResult?.billingTariffs?[index].isSelected = false
                    }
                })
                DispatchQueue.main.async {
//                    self.billCounter
                    self.choosePlanTableView.reloadData()
                }
            } else {
                let message = "SCOOTER_check_sellect_tariff".localized().replacingOccurrences(of: "[tariff]", with: billingTariff.title ?? "")
                let yesAction = UIAlertAction(title: "MOBILE__confirmation_yes".localized(), style: .default) { alert in
                    self.singleScooterResult?.billingTariffs?.enumerated().forEach({ (index, billingTarif) in
                        if billingTariff.id == billingTarif.id {
                            self.singleScooterResult?.billingTariffs?[index].isSelected = true
                            self.billingTarifId = billingTariff.id ?? ""
                        } else {
                            self.singleScooterResult?.billingTariffs?[index].isSelected = false
                        }
                    })
                    DispatchQueue.main.async {
//                        self.billCounter
                        self.choosePlanTableView.reloadData()
                    }
                }
                
//                let noAction = UIAlertAction(title: "MOBILE_confirmation_no".localized(), style: .cancel, handler: nil)
                UIAlertController.showAction(title: "MOBILE__global_attention".localized(), message: message, actions: ("MOBILE__confirmation_no".localized(), .cancel, { alert in }),  ("MOBILE__confirmation_yes".localized(), .default, { alert in
                    self.singleScooterResult?.billingTariffs?.enumerated().forEach({ (index, billingTarif) in
                        if billingTariff.id == billingTarif.id {
                            self.billingTarifId = billingTariff.id ?? ""
                            self.singleScooterResult?.billingTariffs?[index].isSelected = true
                        } else {
                            self.singleScooterResult?.billingTariffs?[index].isSelected = false
                        }
                    })
                    DispatchQueue.main.async {
//                        self.billCounter
                        self.choosePlanTableView.reloadData()
                    }
                }) )
            }
            
        }
        
        
        //        self.choosePlanTableView.reloadRows(at: [IndexPath(row: 2, section: 0), IndexPath(row: 2, section: 0)], with: .automatic)
    }
}
