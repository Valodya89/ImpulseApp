//
//  MimoRatesViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 26.11.23.
//

import UIKit
import Combine

class MimoRatesViewController: MimoBaseViewController {
    
    private var cancellables = Set<AnyCancellable>()
    
    @IBOutlet private weak var navBar: UINavigationBar!
    @IBOutlet private weak var mimoTypesContainerView: UIView!
    @IBOutlet private weak var ratesContainerView: UIStackView!
    @IBOutlet private weak var ratesStackView: UIStackView!
    @IBOutlet private var mimoTypeButtons: [MimoToggleButton]!
    @IBOutlet private var plansViews: [UIView]!
    @IBOutlet private weak var tableView: UITableView!
    
    @IBOutlet private weak var tariffsTopConstraintFromNavigationView: NSLayoutConstraint!
    @IBOutlet private weak var tariffsTopConstraintFromTypesView: NSLayoutConstraint!
    
    var viewModel: MimoRatesViewModel!
    
    private var currentAnimateIndex = 0
    private var timer: Timer?
    private var studentNavVC: UINavigationController?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupViewModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let isSpecificType = viewModel.supportedTypes.count == 1
        self.mimoTypesContainerView.isHidden = isSpecificType
        if isSpecificType {
            NSLayoutConstraint.deactivate([self.tariffsTopConstraintFromTypesView])
            NSLayoutConstraint.activate([self.tariffsTopConstraintFromNavigationView])
        }
    }
    
    private func setupUI() {
        tableView.register(ChargerTariffTableViewCell.self)
        tableView.register(BikeTariffTableViewCell.self)
        tableView.register(BikePackageTableViewCell.self)
        tableView.register(ChargerDiscountsTableViewCell.self)
        tableView.register(ChargerPackageTableViewCell.self)
        
        tableView.contentInset.top = 10
        tableView.sectionHeaderTopPadding = 0
        
        let missingTypes = MimoType.allCases.filter({ !viewModel.supportedTypes.contains($0) })
        missingTypes.forEach { type in
            if let view = ratesStackView.subviews.first(where: { $0.tag == type.rawValue }) {
                view.alpha = 0
                ratesStackView.removeArrangedSubview(view)
            }
        }
        
        navBar.topItem?.title = "MOBILE_rates_title".localized()
    }
    
    private func setupViewModel() {
        viewModel.$errorMessage.sink { [weak self] errorMessage in
            guard let errorMessage else { return }
            self?.showErrorAlertMessage(errorMessage.localized())
            
            MILoader.hide()
        }
        .store(in: &cancellables)
        
        viewModel.mimoType.sink(receiveValue: { [weak self] mimoType in
            guard let self else { return }
            
            self.mimoTypeButtons.forEach({ $0.isSelected = mimoType.rawValue == $0.tag })
            self.viewModel.rateType.send(.tariff)
            
            let rateTypes = self.viewModel.rateTypes(for: mimoType)
            ratesContainerView.subviews.forEach { view in
                let isHidden = !rateTypes.map({ $0.rawValue }).contains(view.tag)
                view.alpha = isHidden ? 0 : 1
                view.isUserInteractionEnabled = !isHidden
            }
            
            self.tableView.reloadData()
        })
        .store(in: &cancellables)
        
        viewModel.rateType.sink { [weak self] type in
            self?.tableView.contentInset.top = 8
            
            switch type {
            case .tariff:
                self?.viewModel.getTariffsForSelectedType()
            case .plan:
                self?.viewModel.getPackagesForSelectedType()
                
                if self?.viewModel.mimoType.value == .charger {
                    self?.tableView.contentInset.top = 24
                }
            case .discounts:
                self?.tableView.reloadData()
            }
            
            self?.plansViews.forEach({ $0.isHidden = type.rawValue != $0.tag })
            
            self?.tableView.reloadData()
        }
        .store(in: &cancellables)
        
        viewModel.bikeTariffs.sink(receiveValue: { [weak self] _ in
            self?.tableView.reloadData()
        })
        .store(in: &cancellables)
        
        viewModel.bikePcakages.sink { [weak self] _ in
            self?.tableView.reloadData()
        }
        .store(in: &cancellables)
        
        viewModel.chargerTariffs.sink { [weak self] _ in
            self?.animateTable()
        }
        .store(in: &cancellables)
        
        viewModel.chargerPackages.sink { [weak self] _ in
            self?.tableView.reloadData()
        }
        .store(in: &cancellables)
        
        viewModel.$activatedPackage.sink { activatedPackage in
            guard let activatedPackage else { return }
            MILoader.hide()
            MiAlertView().showSuccess("MOBILE_charger_package_\(activatedPackage.package?.name ?? "")_activated".localized(), closeButtonTitle: "OK")
        }
        .store(in: &cancellables)
        
        viewModel.$bikeActivatedPackage.sink { activatedPackage in
            guard let activatedPackage else { return }
            MILoader.hide()
            MiAlertView().showSuccess("SHARING_package_\(activatedPackage.package?.name ?? "")_activated".localized(), closeButtonTitle: "OK")
        }
        .store(in: &cancellables)
    }
    
    func animateTable() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            
            if self.currentAnimateIndex == 3 {
                self.currentAnimateIndex = 0
            } else {
                self.currentAnimateIndex += 1
            }
            
            guard viewModel.mimoType.value == .charger, viewModel.rateType.value == .tariff else { return }
            
            self.tableView.reloadData()
        }
    }
}

//MARK: - Actions
extension MimoRatesViewController {
    
    @IBAction private func mimoTypeAction(_ sender: MimoToggleButton) {
        VibrateManager.vibrate()
        
        let newMimoType = MimoType(rawValue: sender.tag) ?? .scooter
        guard newMimoType != viewModel.mimoType.value else { return }
        
        viewModel.mimoType.send(newMimoType)
    }
    
    @IBAction private func tariffPlanAction(_ sender: UIButton) {
        VibrateManager.vibrate()
        
        let newRateType = RateType(rawValue: sender.tag) ?? .tariff
        guard newRateType != viewModel.rateType.value else { return }
        viewModel.rateType.send(newRateType)
    }
    
    @IBAction private func closeAction() {
        dismiss(animated: true)
    }
}

extension MimoRatesViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        switch viewModel.mimoType.value {
        case .scooter:
            return 0
        case .bike:
            return 1
        case .charger:
            return viewModel.rateType.value == .tariff ? viewModel.chargerTariffs.value.count : 1
        case .evCharger:
            return viewModel.rateType.value == .tariff ? viewModel.chargerTariffs.value.count : 1
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch viewModel.mimoType.value {
        case .scooter:
            return 0
        case .bike:
            switch viewModel.rateType.value {
            case .tariff:
                return viewModel.bikeTariffs.value.count
            case .plan:
                return viewModel.bikePcakages.value.count
            default:
                return 0
            }
        case .charger:
            switch viewModel.rateType.value {
            case .tariff:
                return 1
            case .plan:
                return viewModel.chargerPackages.value.count
            case .discounts:
                return viewModel.chargerDiscounts.count
            }
        case .evCharger:
            switch viewModel.rateType.value {
            case .tariff:
                return 1
            case .plan:
                return viewModel.chargerPackages.value.count
            case .discounts:
                return viewModel.chargerDiscounts.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch viewModel?.mimoType.value {
        case .scooter:
            return UITableViewCell()
        case .bike:
            switch viewModel.rateType.value {
            case .tariff:
                let cell: BikeTariffTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                
                let tariff = viewModel.bikeTariffs.value[indexPath.row]
                cell.set(tariff: tariff)
                cell.delegate = self
                
                return cell
            case .plan:
                let cell: BikePackageTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                
                let package = viewModel.bikePcakages.value[indexPath.row]
                cell.set(package: package)
                cell.delegate = self
                
                return cell
            case .discounts:
                return UITableViewCell()
            }
        case .charger:
            switch viewModel.rateType.value {
            case .tariff:
                let cell: ChargerTariffTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.contentView.alpha = self.currentAnimateIndex == indexPath.section ? 1 : 0.3
                cell.set(data: viewModel.chargerTariffs.value[indexPath.section])
                
                return cell
            case .plan:
                let cell: ChargerPackageTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                let package = viewModel.chargerPackages.value[indexPath.row]
                
                cell.set(data: package, isActivated: package.id == viewModel.alreadyActivatedChargerPackage?.package?.id)
                cell.delegate = self
                
                return cell
            case .discounts:
                let cell: ChargerDiscountsTableViewCell = tableView.dequeueReusableCell(for: indexPath)
                cell.set(data: viewModel.chargerDiscounts[indexPath.row])
                
                return cell
            }
            
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if viewModel.mimoType.value == .charger, viewModel.rateType.value == .tariff {
            if section == 0 {
                let view = UIView()
                let headerTitle = UILabel()
                headerTitle.numberOfLines = 0
                headerTitle.text = "MOBILE_charger_tariffs_hint".localized()
                headerTitle.font = .systemFont(ofSize: 14, weight: .light)
                
                view.addSubview(headerTitle)
                headerTitle.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    headerTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                    headerTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 20),
                    headerTitle.topAnchor.constraint(equalTo: view.topAnchor)
                ])
                
                return view
            } else {
                let headerView = UIView()
                
                let stackView = UIStackView()
                stackView.axis = .vertical
                stackView.spacing = 3
                stackView.distribution = .fillEqually
                
                headerView.addSubview(stackView)
                stackView.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    stackView.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
                    stackView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                    stackView.heightAnchor.constraint(equalToConstant: 28),
                    stackView.widthAnchor.constraint(equalToConstant: 2)
                ])
                
                let lineColor: UIColor = currentAnimateIndex == section ? .mimoDarkGray.withAlphaComponent(0.5) : .mimoDarkGray.withAlphaComponent(0.2)
                let lineView1 = UIView()
                lineView1.backgroundColor = lineColor
                let lineView2 = UIView()
                lineView2.backgroundColor = lineColor
                let lineView3 = UIView()
                lineView3.backgroundColor = lineColor
                stackView.addArrangedSubview(lineView1)
                stackView.addArrangedSubview(lineView2)
                stackView.addArrangedSubview(lineView3)
                
                return headerView
            }
        } else if viewModel.mimoType.value == .charger, viewModel.rateType.value == .discounts {
            let view = UIView()
            let headerTitle = UILabel()
            headerTitle.numberOfLines = 0
            headerTitle.text = "MOBILE_charger_discounts_hint".localized()
            headerTitle.font = .systemFont(ofSize: 14, weight: .light)
            
            view.addSubview(headerTitle)
            headerTitle.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                headerTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                headerTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                headerTitle.topAnchor.constraint(equalTo: view.topAnchor)
            ])
            
            return view
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if viewModel.mimoType.value == .charger && viewModel.rateType.value == .tariff {
            return section == 0 ? 44 : 40
        }
        
        if viewModel.mimoType.value == .charger && viewModel.rateType.value == .discounts {
            return 56
        }
        
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNormalMagnitude
    }
}

extension MimoRatesViewController: ChargerPackageTableViewCellDelegate {
    func didSelectActivatePackage(for cell: ChargerPackageTableViewCell) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        let id = viewModel.chargerPackages.value[index].id
        
        MILoader.show()
        viewModel.chargerPackageActivate(id: id)
    }
}

extension MimoRatesViewController: BikeTariffTableViewCellDelegate {
    func didSelectActivateStudent(for cell: BikeTariffTableViewCell) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        
        let studentViewContoller = StudentInformationViewController.initFromStoryboard(name: Constant.Storyboards.plan)
        studentViewContoller.tarrifStident = viewModel.bikeTariffs.value[index]
        studentNavVC = UINavigationController(rootViewController: studentViewContoller)
        
        let backButton = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(Self.studentBackButtonTapped))
        studentViewContoller.navigationItem.leftBarButtonItem = backButton
        
        present(studentNavVC!, animated: true, completion: nil)
    }
    
    @objc func studentBackButtonTapped() {
        studentNavVC?.dismiss(animated: true)
    }
}

extension MimoRatesViewController: BikePackageTableViewCellDelegate {
    func didSelectBikePackageActivate(for cell: BikePackageTableViewCell) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        let id = viewModel.bikePcakages.value[index].id
        
        viewModel.bikePackageActivate(id: id)
    }
}
