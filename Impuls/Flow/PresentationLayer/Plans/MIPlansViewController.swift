//
//  MIPlansViewController.swift
//  MimoBike
//
//  Created by Dose on 6/5/21.
//

import UIKit

class MIPlansNavigationController: UINavigationController, StoryboardInitializable {
    
}

final class MIPlansViewController: UIViewController, StoryboardInitializable {
    
    @IBOutlet weak var miPackageStack: UIStackView!
    @IBOutlet weak var contextView: UIView!
    @IBOutlet weak var activePackageContent: PlanCells!
    @IBOutlet weak var activePackageView: UIView!
    @IBOutlet weak var contentStackView: UIStackView!
    @IBOutlet weak var toolBar: MAToolBar!
    
    private var packageTableView: PlanTableView!
    private var tarrifTableView: PlanTableView!
    
    var tarrifs: [TariffModel] = []
    var packages: [PackageModel] = []
    var userResult: UserResponse?
    
    let viewModel = MIPlanViewModel()
    
    var isPackageSelected: Bool = false
    
    var activeVC: UINavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contextView.animateOut(animatable: false)
        UserManager.share.getAccount { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let userResult):
                self.setUser(userResult)
            case .failure(let error):
                print(error)
                MILoader.hide()
                UIAlertController.showError(message: error.localizedDescription)
            }
        }
    }
    
    private func setUser(_ user: UserResponse) {
        self.userResult = user
        self.activePackageView.isHidden = user.package == nil
        self.view.setNeedsLayout()
        self.getTarrifs()
        self.getPackages()
        self.activePackageView.layoutIfNeeded()
        self.contextView.layoutSubviews()
        self.miPackageStack.layoutSubviews()
        self.configureContent()
    }
    
    private func configureContent() {
        
        activePackageContent.commonInit(type: .package)
        if let packageView = activePackageContent.contentView as? PackageCell {
            packageView.backgroundColor = .mimoYellow500
            packageView.ridesLabel.textColor = .black
            packageView.feeTitleLabel.textColor = .black
            packageView.feeIcon.image = packageView.feeIcon.image?.withRenderingMode(.alwaysTemplate)
            packageView.feeIcon.tintColor = .black
            packageView.ridesLabel.textColor = .black
            packageView.ridesIcon.image = packageView.ridesIcon.image?.withRenderingMode(.alwaysTemplate)
            packageView.ridesIcon.tintColor = .black
            packageView.hideActionButton()
            
        }
        let packageTableView = PlanTableView(frame: toolBar.frame)
        packageTableView.register(cells: (PlanCellTypes.package.nib, PlanCellTypes.package.type))
        packageTableView.delegate = self
        self.packageTableView = packageTableView
        
        let tarrifTableView = PlanTableView(frame: toolBar.frame)
        tarrifTableView.delegate = self
        tarrifTableView.register(cells:
                                    (PlanCellTypes.tarrif.nib, PlanCellTypes.tarrif.type),
                                 (PlanCellTypes.student.nib, PlanCellTypes.student.type),
                                  (PlanCellTypes.extendTariff.nib, PlanCellTypes.extendTariff.type)
        )
        self.tarrifTableView = tarrifTableView
        toolBar.setup(titles: ["MOBILE_plans_rates_tariffs".localized(), "MOBILE_plans_rates_packages".localized()], bars: [tarrifTableView, packageTableView])
    }
    
    private func getTarrifs() {
        viewModel.fetchTariff { [weak self] (result) in
            switch result {
            case .success(let tarrifs):
                self?.tarrifs = tarrifs.reversed()
//                if let studentIndex = tarrifs.firstIndex(where: {$0.name == "Student"}) {
//                    let studentModel = tarrifs[studentIndex]
//                    self?.tarrifs.remove(at: studentIndex)
//                    self?.tarrifs.insert(studentModel, at: 0)
//                }
                self?.tarrifTableView.reloadData()
                self?.contextView.animateIn(animatable: true)
                
            case .failure(let error):
                UIAlertController.showError(message: error.localizedDescription)
            }
        }
    }
    
    private func getPackages() {
        viewModel.fetchPackage { [weak self] (result) in
            switch result {
            case .success(let packages):
                self?.packages = packages
                
                self?.activePackageView.isHidden = self?.userResult?.package == nil
                
                if let userPackage = self?.packages.first(where: { $0.id == self?.userResult?.package?.id }) {
                    self?.activePackageContent.setup(userPackage)
                } else {
                    self?.activePackageView.isHidden = true
                }
                
                
                self?.packages.removeAll(where: { $0.id == self?.userResult?.package?.id })
                self?.packageTableView.reloadData()
                self?.packageTableView.layoutIfNeeded()
                if self?.isPackageSelected ?? false {
                    self?.toolBar.updateContentScrollView(to: 1)
                    self?.packageTableView.reloadData()
                }
                self?.contextView.animateIn(animatable: true)
            case .failure(let error):
                UIAlertController.showError(message: error.localizedDescription)
            }
        }
    }
    
    @objc func backButtonTapped() {
        activeVC?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func closeAction() {
        self.dismiss(animated: true)
    }
}

extension MIPlansViewController: PlanTableViewDelegate {
    
    func numberOfItems(in tableView: UITableView) -> Int {
        return tableView == packageTableView.tableView ? self.packages.count : self.tarrifs.count
    }
    
    func cell(for index: Int, table tableView: UITableView) -> UITableViewCell {
        
        if tableView == packageTableView.tableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(String(describing: PlanCellTypes.package.type))") as! PackageCell
            let package = self.packages[index]
            let hideActiveButton = package.id == self.userResult?.package?.id
            cell.setup(package, hideActiveButton: hideActiveButton)
            
            cell.actionHandler = { [weak self] _ in
                let activeViewController = CompletePurchaseViewController.initFromStoryboard(name: Constant.Storyboards.plan)
                activeViewController.updateUI = {
                    UserManager.share.getUser {[weak self] result in
                        switch result {
                        case .success(let user):
                            self?.setUser(user)
                        case .failure(let error):
                            UIAlertController.showError(message: error.localizedDescription)
                        }
                    }
                }
                activeViewController.package = package
                self?.navigationController?.pushViewController(activeViewController, animated: true)
            }
            
            return cell
        } else {
            var tariff: TariffModel? = self.tarrifs[index]
//            if index == 0 {
//                tariff = self.tarrifs.first(where: { $0.code == "basic"})
//            } else if index == 1 {
//                tariff = self.tarrifs.first(where: { $0.code == "student"})
//            } else if index == 2 {
//                tariff = self.tarrifs.first(where: { $0.code == "booking"})
//            }
            let tarrif = tariff! // TODO: Need to change
            
            if tarrif.activable && self.userResult?.tariff == nil {
                let cell = tableView.dequeueReusableCell(withIdentifier: "\(String(describing: PlanCellTypes.student.type))") as! StudentCell
                cell.setup(tarrif)
                
                cell.actionHandler = { [weak self] _ in
                    let studentViewContoller = StudentInformationViewController.initFromStoryboard(name: Constant.Storyboards.plan)
                    studentViewContoller.updateUI = {
                        UserManager.share.getUser {[weak self] result in
                            switch result {
                            case .success(let user):
                                self?.setUser(user)
                            case .failure(let error):
                                UIAlertController.showError(message: error.localizedDescription)
                            }
                        }
                    }
                    studentViewContoller.tarrifStident = tarrif
                    self?.activeVC = UINavigationController(rootViewController: studentViewContoller)
                    
                    let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_arrow_left"), style: .plain, target: self, action: #selector(Self.backButtonTapped))
                    studentViewContoller.navigationItem.leftBarButtonItem = backButton
                    
                    self?.present((self?.activeVC)!, animated: true, completion: nil)
                    
                }
                
                return cell
            } else if tarrif.type == "RIDE_BIKE_EXTENDED" {
                let cell = tableView.dequeueReusableCell(withIdentifier: "TarrifEXTENDEDCell") as! TarrifEXTENDEDCell
                cell.setup(self.tarrifs[index])
                return cell
            }
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "\(String(describing: PlanCellTypes.tarrif.type))") as! TarrifCell
            cell.setup(self.tarrifs[index])
            return cell
        }
        
    }
    
}
