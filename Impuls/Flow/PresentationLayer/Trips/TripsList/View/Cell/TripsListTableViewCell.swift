//
//  TripsListTableViewCell.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/15/21.
//

import UIKit

final class TripsListTableViewCell: UITableViewCell {
    @IBOutlet weak var fromDestinationLabel: UILabel!
    @IBOutlet weak var toDestinationLabel: UILabel!
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var amountButton: UIButton!
    @IBOutlet weak var qrLbl: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var viewForQR: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        viewForQR.layer.cornerRadius = viewForQR.frame.height / 2
        viewForQR.layer.borderWidth = 1
        viewForQR.layer.borderColor = UIColor.mimoYellow500.cgColor
        baseView.addShadow(color: .mimoBlackWith025alpha)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
//        self.fromDestinationLabel.text = nil
//        self.toDestinationLabel.text = nil
        qrLbl.text = ""
    }
    
    func setup(_ tripModel: TripBikeDataModel) {
        viewForQR.isHidden = true
        let amount = Int(tripModel.payment?.amount ?? 0)
        amountButton.setTitle(amount.description + " " + "MOBILE_global_total_currency".localized(), for: .normal)
        iconImageView.image = UIImage(named: "ic_bicycleTrips")

        amountButton.backgroundColor = tripModel.payment?.status?.backgroundColor ?? .mimoRed500
        amountButton.setTitleColor(tripModel.payment?.status?.fillColor ?? .mimoWhite, for: .normal)
        tripModel.startPosition?.getLocationName(completed: { [weak self] (destination) in
            self?.fromDestinationLabel.text = destination
        })
        qrLbl.text = ""
        tripModel.endPosition?.getLocationName(completed: { [weak self] (destination) in
            self?.toDestinationLabel.text = destination
        })
    }
    
    func setup(_ tripModel: TripScooterDataModel) {
        let amount = Int(tripModel.payment?.amount ?? 0)
        amountButton.setTitle(amount.description + " " + "MOBILE_global_total_currency".localized(), for: .normal)
        iconImageView.image = UIImage(named: "ic_scooter")
        amountButton.backgroundColor = tripModel.payment?.status?.backgroundColor ?? .mimoRed500
        amountButton.setTitleColor(tripModel.payment?.status?.fillColor ?? .mimoWhite, for: .normal)
        tripModel.startPosition?.getLocationName(completed: { [weak self] (destination) in
            self?.fromDestinationLabel.text = destination
        })
        if let scooterQR = tripModel.scooterQr {
            viewForQR.layer.cornerRadius = viewForQR.frame.height / 2
            viewForQR.layer.borderWidth = 1
            viewForQR.layer.borderColor = UIColor.mimoYellow500.cgColor
            qrLbl.text = scooterQR
            viewForQR.isHidden = false
        } else {
            viewForQR.isHidden = true
        }
        tripModel.endPosition?.getLocationName(completed: { [weak self] (destination) in
            self?.toDestinationLabel.text = destination
        })
    }
    
    func setup(data: ChargerRentModel) {
        let amount = String(format: "%.2f", data.payment.amount ?? 0)
        amountButton.setTitle(amount + " " + "MOBILE_global_total_currency".localized(), for: .normal)
        iconImageView.image = UIImage(named: "mimo_charger_station")
        amountButton.backgroundColor = data.payment.status?.backgroundColor ?? .mimoRed500
        amountButton.setTitleColor(data.payment.status?.fillColor ?? .mimoWhite, for: .normal)
        fromDestinationLabel.text = data.startStation
        toDestinationLabel.text = data.endStation
        viewForQR.isHidden = true
    }
}
