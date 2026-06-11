//
//  ChangeRideRateViewController.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/28/22.
//

import UIKit

protocol ChangeRideRateViewControllerDeelegate: AnyObject {
    func didChangeTariff(tripId: String?, speedId: String?)
    func didCloseChangeTariff()
}

final public class ChangeRideRateViewController: UIViewController, StoryboardInitializable {

    // MARK: Outlets
    @IBOutlet private weak var alertView: UIView!
    @IBOutlet private weak var changeRideRateTitleLabel: UILabel!
    @IBOutlet private weak var changeRideRateDescriptionLabel: UILabel!
    @IBOutlet private weak var speedTitleLabel: UILabel!
    @IBOutlet private weak var speedLabel: UILabel!
    @IBOutlet private weak var costTitleLabel: UILabel!
    @IBOutlet private weak var costLabel: UILabel!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var changeRateButton: UIButton!
    
    weak var delegate:  ChangeRideRateViewControllerDeelegate?
    var speedId: String?
    var tripId: String?
    
    // MARK: View Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    func updateUI(speedTarif: SpeedTariff,  scooterPlanMOed: String) {
        var price = 0.0
        if scooterPlanMOed == "FIXED" || scooterPlanMOed == "DO_NOT_SIT" {
            price = 0.0
        } else {
            price = speedTarif.price ?? 0
        }
        speedLabel.text = "\(speedTarif.speed ?? 0) " + "SCOOTER_global_km_hour".localized()
        costLabel.text = "\(price) ֏/" + "SCOOTER_global_minute".localized()
    }
    
    // MARK: Methods
    private func setupView() {
        alertView.layer.cornerRadius = 12
        cancelButton.layer.cornerRadius = cancelButton.frame.height / 2
        cancelButton.layer.borderWidth = 1
        cancelButton.layer.borderColor = UIColor(named: "mimoDarkGray")?.cgColor
        
        changeRateButton.layer.cornerRadius = changeRateButton.frame.height / 2
    }

    // MARK: Actions
    @IBAction private func cancelButtonAction(_ sender: UIButton) {
        delegate?.didCloseChangeTariff()
    }
    
    
    @IBAction private func changeRideButtonAction(_ sender: UIButton) {
        delegate?.didChangeTariff(tripId: tripId, speedId: speedId)
    }
}
