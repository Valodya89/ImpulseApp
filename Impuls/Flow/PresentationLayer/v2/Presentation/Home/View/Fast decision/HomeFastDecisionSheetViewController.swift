//
//  HomeFastDecisionSheetViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.06.23.
//

import UIKit
import Combine
import CoreLocation

protocol HomeFastDecisionSheetViewControllerDelegate: AnyObject {
    func didSelect(mimo: MimoResult, type: MimoProductType)
}

class HomeFastDecisionSheetViewController: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    
    @IBOutlet private weak var tableView: UITableView!
    
    var viewModel: MimoHomeViewModel?
    weak var delegate: HomeFastDecisionSheetViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(FastDecisionTableViewCell.self)
        tableView.register(EVFastDecisionTableViewCell.self)
        
        viewModel?.$availableServices.sink { [weak self] services in
            guard let availableServices = services,
                  !availableServices.isEmpty else { return }
            self?.viewModel?.loadData(for: availableServices)
        }
        .store(in: &cancellables)
        
        viewModel?.fastDecisions.sink { [weak self] _ in
            self?.tableView.reloadData()
        }
        .store(in: &cancellables)
    }
}

extension HomeFastDecisionSheetViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100.0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.fastDecisions.value.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel else { return UITableViewCell() }
        let cell: FastDecisionTableViewCell = tableView.dequeueReusableCell(withIdentifier: "FastDecisionTableViewCell")
        
        if let scooter = viewModel.fastDecisions.value[indexPath.row] as? ScooterResult {
            cell.set(scooter: scooter, currentLocation: viewModel.currentLocation)
        } else if let bike = viewModel.fastDecisions.value[indexPath.row] as? BikeResult {
            cell.set(bike: bike, currentLocation: viewModel.currentLocation)
        } else if let charger = viewModel.fastDecisions.value[indexPath.row] as? ChargingStation {
            cell.set(charger: charger, currentLocation: viewModel.currentLocation)
        } else if let evCharger = viewModel.fastDecisions.value[indexPath.row] as? EVChargingStation {
            let chargerCell: EVFastDecisionTableViewCell = tableView.dequeueReusableCell(withIdentifier: "EVFastDecisionTableViewCell")
            chargerCell.set(evCharger: evCharger, currentLocation: viewModel.currentLocation)
            return chargerCell
        }
        
        return cell
    }
}

extension HomeFastDecisionSheetViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        if let scooter = viewModel.fastDecisions.value[indexPath.row] as? ScooterResult {
            delegate?.didSelect(mimo: scooter, type: .scooter)
        } else if let bike = viewModel.fastDecisions.value[indexPath.row] as? BikeResult {
            delegate?.didSelect(mimo: bike, type: .bike)
        } else if let charger = viewModel.fastDecisions.value[indexPath.row] as? ChargingStation {
            delegate?.didSelect(mimo: charger, type: .charger)
        } else if let evCharger = viewModel.fastDecisions.value[indexPath.row] as? EVChargingStation {
            delegate?.didSelect(mimo: evCharger, type: .evCharger)
        }
    }
}
