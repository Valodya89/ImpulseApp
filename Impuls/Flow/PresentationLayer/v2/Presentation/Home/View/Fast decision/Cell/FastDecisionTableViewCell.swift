//
//  FastDecisionTableViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.06.23.
//

import UIKit
import CoreLocation

class FastDecisionTableViewCell: BaseTableViewCell {
    
    @IBOutlet private weak var mimoImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var batteryImageView: UIImageView!
    @IBOutlet private weak var batteryPercentLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var batteryView: UIView!
    @IBOutlet private weak var qrLabel: UILabel!
    @IBOutlet private weak var qrView: UIView!
    
    private let addressHelper = AddressHelper()

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }
    
    func set(scooter: ScooterResult?, currentLocation: CLLocationCoordinate2D?) {
        guard let scooter else { return }
        
        mimoImageView.image = "Mimo_scooter_New".image
        nameLabel.text = "MAX PLUSE"
        batteryView.isHidden = false
        batteryImageView.image = scooter.batteryPercent.image
        batteryPercentLabel.text = scooter.batteryPercent.percentPrettyPrinted
        durationLabel.text = scooter.remainingMileage.prettyPrintedWithoutRange
        qrLabel.text = scooter.qr
        qrView.isHidden = false
        
        Task {
            let address = try await AddressHelper().getAddress(for: scooter.coordinate, fullAddress: false)
            self.locationLabel.text = address
        }
        
        if let currentLocation {
            let distance = currentLocation.clLocation.distance(from: scooter.coordinate.clLocation)
            distanceLabel.text = "\("SCOOTER_global_distance".localized()): \(distance.prettyDistance)"
        } else {
            distanceLabel.text = "\("SCOOTER_global_distance".localized()): -"
        }
    }
    
    func set(bike: BikeResult?, currentLocation: CLLocationCoordinate2D?) {
        guard let bike else { return }
        
        mimoImageView.image = "Mimo_bike_New".image
        nameLabel.text = "BIKE"
        qrLabel.text = bike.qr
        qrView.isHidden = false
        batteryView.isHidden = true
        durationLabel.isHidden = true
        
        Task {
            let address = try await AddressHelper().getAddress(for: bike.coordinate, fullAddress: false)
            self.locationLabel.text = address
        }
        
        if let currentLocation {
            let distance = currentLocation.clLocation.distance(from: bike.coordinate.clLocation)
            distanceLabel.text = "\("SCOOTER_global_distance".localized()): \(distance.prettyDistance)"
        } else {
            distanceLabel.text = "\("SCOOTER_global_distance".localized()): -"
        }
    }
    
    func set(charger: ChargingStation, currentLocation: CLLocationCoordinate2D?) {
        mimoImageView.image = "mimo_charger_station".image
        nameLabel.text = charger.destinationName ?? "--"
        qrView.isHidden = true
        batteryView.isHidden = true
        durationLabel.isHidden = true
        
        locationLabel.text = charger.destinationAddress ?? "--"
        
        if let currentLocation {
            let distance = currentLocation.clLocation.distance(from: charger.coordinate.clLocation)
            distanceLabel.text = "\("SCOOTER_global_distance".localized()): \(distance.prettyDistance)"
        } else {
            distanceLabel.text = "\("SCOOTER_global_distance".localized()): -"
        }
    }
    
    func set(evCharger: EVChargingStation, currentLocation: CLLocationCoordinate2D?) {
        mimoImageView.image = "mimo_ev_charger_station".image
        nameLabel.text = evCharger.destinationName
        qrLabel.text = evCharger.id
        qrView.isHidden = false
        batteryView.isHidden = true
        durationLabel.isHidden = true
        
        locationLabel.text = evCharger.destinationAddress
        
        if let currentLocation {
            let distance = currentLocation.clLocation.distance(from: evCharger.coordinate.clLocation)
            distanceLabel.text = "\("MOBILE_global_distance".localized()): \(distance.prettyDistance)"
        } else {
            distanceLabel.text = "\("MOBILE_global_distance".localized()): -"
        }
    }
}
