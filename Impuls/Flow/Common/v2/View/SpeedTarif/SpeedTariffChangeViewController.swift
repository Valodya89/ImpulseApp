//
//  SpeedTariffChangeViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.06.23.
//

import UIKit

protocol SpeedTariffChangeViewControllerDelegate: AnyObject {
    func didChangeSpeedTariff(tripId: String?, speedId: String?)
}

class SpeedTariffChangeViewController: BaseViewController {
    
    @IBOutlet private weak var speedLabel: UILabel!
    @IBOutlet private weak var costLabel: UILabel!
    
    weak var delegate: SpeedTariffChangeViewControllerDelegate?
    
    var speedTariff: SpeedTariff?
    var scooterPlanMode: ScooterPlanMode?
    var tripId: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        var price = 0.0
        if scooterPlanMode == .FIXED || scooterPlanMode == .DO_NOT_SIT {
            price = 0.0
        } else {
            price = speedTariff?.price ?? 0
        }
        
        speedLabel.text = "\(speedTariff?.speed ?? 0) " + "SCOOTER_global_km_hour".localized()
        costLabel.text = "\(price) ֏/" + "SCOOTER_global_minute".localized()
    }
    
    @IBAction private func cancelAction() {
        dismiss(animated: true)
    }
    
    @IBAction private func changeRateAction() {
        delegate?.didChangeSpeedTariff(tripId: tripId, speedId: speedTariff?.id)
        dismiss(animated: true)
    }
}
