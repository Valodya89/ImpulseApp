//
//  EVFastDecisionTableViewCell.xib.swift
//  MimoBike
//
//  Created by Andrey Lupin on 08.10.25.
//


import UIKit
import CoreLocation

class EVFastDecisionTableViewCell: BaseTableViewCell {
    
    @IBOutlet private weak var mimoImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var qrLabel: UILabel!
    @IBOutlet private weak var qrView: UIView!
    @IBOutlet weak var statusBGView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var connectorTypeLabel: UILabel!
    
    private let addressHelper = AddressHelper()

    override func awakeFromNib() {
        super.awakeFromNib()
        statusBGView.layer.cornerRadius = 10.0
        selectionStyle = .none
    }
    
    func set(scooter: ScooterResult?, currentLocation: CLLocationCoordinate2D?) {
        guard let scooter else { return }
        
//        mimoImageView.image = "Mimo_scooter_New".image
        nameLabel.text = "MAX PLUSE"
        qrLabel.text = String(scooter.qr.suffix(4))
        qrView.isHidden = false
        
        Task {
            do {
                let address = try await AddressHelper().getAddress(for: scooter.coordinate, fullAddress: false)
                self.locationLabel.text = address
            } catch {
                self.locationLabel.text = "-"
                print("EVFastDecisionTableViewCell: Failed to fetch address — \(error)")
            }
        }
        
        if let currentLocation {
            let distance = currentLocation.clLocation.distance(from: scooter.coordinate.clLocation)
            distanceLabel.text = "\("SCOOTER_global_distance".localized()): \(distance.prettyDistance)"
        } else {
            distanceLabel.text = "\("SCOOTER_global_distance".localized()): -"
        }
    }
    
    
    func set(evCharger: EVChargingStation, currentLocation: CLLocationCoordinate2D?) {
//        mimoImageView.image = "mimo_ev_charger_station".image
        nameLabel.text = evCharger.destinationName
        qrLabel.text = String(evCharger.id.suffix(4))
        qrView.isHidden = false
        switch evCharger.connectors.first?.state {
        case .available:
            statusLabel.text = "EV_CHARGER_connector_state_available".localized()
            statusBGView.backgroundColor = UIColor(named: "stateAvailable")
            statusLabel.textColor = UIColor(named: "stateAvailableTitle")
        case .preparing:
            statusLabel.text = "EV_CHARGER_connector_state_preparing".localized()
            statusBGView.backgroundColor = UIColor(named: "statePreparing")
            statusLabel.textColor = UIColor(named: "statePreparingTitle")
        case .charging:
            statusLabel.text = "EV_CHARGER_connector_state_charging".localized()
            statusBGView.backgroundColor = UIColor(named: "stateCharging")
            statusLabel.textColor = UIColor(named: "stateChargingTitle")
        case .finishing:
            statusLabel.text = "EV_CHARGER_connector_state_finishing".localized()
            statusBGView.backgroundColor = UIColor(named: "stateFinishing")
            statusLabel.textColor = UIColor(named: "stateFinishingTitle")
        case .suspendedEvse, .suspendedEv:
            statusLabel.text = "EV_CHARGER_connector_state_suspended".localized()
            statusBGView.backgroundColor = UIColor(named: "stateSuspended")
            statusLabel.textColor = UIColor(named: "stateSuspendedTitle")
        case .reserved, .unavailable, .faulted:
            statusLabel.text = "EV_CHARGER_connector_state_unavailable".localized()
            statusBGView.backgroundColor = UIColor(named: "stateUnAvailable")
            statusLabel.textColor = UIColor(named: "stateUnAvailableTitle")
        case .none:
            statusLabel.text = "EV_CHARGER_connector_state_unavailable".localized()
            statusBGView.backgroundColor = UIColor(named: "stateUnAvailable")
            statusLabel.textColor = UIColor(named: "stateUnAvailableTitle")
        }
        connectorTypeLabel.text = evCharger.connectors.first?.type.title
        locationLabel.text = evCharger.destinationAddress
        if let currentLocation {
            let distance = currentLocation.clLocation.distance(from: evCharger.coordinate.clLocation)
            distanceLabel.text = "\("MOBILE_global_distance".localized()): \(distance.prettyDistance)"
        } else {
            distanceLabel.text = "\("MOBILE_global_distance".localized()): -"
        }
    }
}
