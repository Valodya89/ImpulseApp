//
//  ActiveTripCollectionViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 11.10.23.
//

import UIKit
import SwiftUI
import CoreLocation

class ActiveTripCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var qrView: UIView!
    @IBOutlet weak var qrLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var percentLabel: UILabel!

    private let strokeLayer = CAShapeLayer()
    private var strokeColor = UIColor.mimoYellow500.cgColor
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.clipsToBounds = false
        contentView.backgroundColor = .white
        contentView.cornerRadius = 8
        contentView.addShadow(color: .black.withAlphaComponent(0.25), offset: .init(width: 0, height: 0), shadowRadius: 5)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if !(layer.sublayers?.contains(where: { $0.name == "strokeAnimation" }) ?? false) {
            let path = UIBezierPath(roundedRectFromCenter: self.bounds, cornerRadius: 8)
            
            strokeLayer.path = path.cgPath
            strokeLayer.fillColor = UIColor.clear.cgColor
            strokeLayer.strokeColor = strokeColor
            strokeLayer.strokeStart = 0
            strokeLayer.strokeEnd = 0
            strokeLayer.lineWidth = 2
            strokeLayer.lineJoin = .round
            strokeLayer.name = "strokeAnimation"
            self.contentView.layer.addSublayer(strokeLayer)
            
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = 0
            animation.toValue = 1
            animation.duration = 6
            animation.repeatCount = .infinity
            animation.autoreverses = false
            animation.isRemovedOnCompletion = false
            animation.fillMode = .forwards
            strokeLayer.add(animation, forKey: "strokeEnd")
        }
    }

    func set(scooterState: ScooterStateModel) {
        nameLabel.text = "MAX PLUSE"
        qrLabel.text = scooterState.scooter?.qr
        iconImageView.image = UIImage(named: "Mimo_scooter_New")
        strokeColor = UIColor.mimoYellow500.cgColor
        qrView.borderColor = UIColor.mimoYellow500
        
        guard let latitude = scooterState.scooter?.located?.latitude, let longitude = scooterState.scooter?.located?.longitude else { return }
        Task {
            let address = try await AddressHelper().getAddress(for: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), fullAddress: false)
            self.addressLabel.text = address
        }
    }
    
    func set(bikeState: TripActionModel) {
        nameLabel.text = "BIKE"
        qrLabel.text = bikeState.bikeDto?.qr
        iconImageView.image = UIImage(named: "Mimo_bike_New")
        strokeColor = UIColor.mimoYellow500.cgColor
        qrView.borderColor = UIColor.mimoYellow500
        
        guard let latitude = bikeState.bikeDto?.latitude, let longitude = bikeState.bikeDto?.longitude else { return }
        Task {
            let address = try await AddressHelper().getAddress(for: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), fullAddress: false)
            self.addressLabel.text = address
        }
    }
    
    func set(charger: RentedCharger) {
        nameLabel.text = "MOBILE_charger_title".localized()
        qrLabel.text = charger.data?.powerBank
        iconImageView.image = "mimo_charger_station".image
        strokeColor = UIColor.mimoYellow500.cgColor
        qrView.borderColor = UIColor.mimoYellow500
        
        addressLabel.text = "\("MOBILE_charger_currentPlan".localized()): \(charger.data?.billingDetails?.currentTariff?.priceName ?? "-")"
    }
    
    func set(evCharger: EVStateMessagedDTO) {
        nameLabel.text = evCharger.station.connectors?.first(where: { $0.connectorId == evCharger.data.connectorId })?.type?.title
        qrLabel.text = String(evCharger.data.stationId)
        iconImageView.image = "mimo_ev_charger_station".image
        
        addressLabel.text = "Charging In Progress" // evCharger.station.destinationAddress
        strokeColor = UIColor(Color.evbrandCyan80).cgColor
        qrView.borderColor = UIColor(Color.evbrandCyan80)
        
        percentLabel.text = "\(evCharger.data.percent)%"
        percentLabel.isHidden = evCharger.data.percent == 0
    }
}

private extension UIBezierPath {

    convenience init(roundedRectFromCenter frame: CGRect, cornerRadius: CGFloat) {
        self.init()

        move(to: CGPoint(x: 5, y: 0))
        addLine(to: CGPoint(x: frame.width - cornerRadius, y: 0))
        addArc(
            withCenter: CGPoint(x: frame.width - cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )
        addLine(to: CGPoint(x: frame.width, y: frame.height - cornerRadius))
        addArc(
            withCenter: CGPoint(x: frame.width - cornerRadius, y: frame.height - cornerRadius),
            radius: cornerRadius,
            startAngle: 0,
            endAngle: .pi / 2,
            clockwise: true
        )
        addLine(to: CGPoint(x: cornerRadius, y: frame.height))
        addArc(
            withCenter: CGPoint(x: cornerRadius, y: frame.height - cornerRadius),
            radius: cornerRadius,
            startAngle: .pi / 2,
            endAngle: .pi,
            clockwise: true
        )
        addLine(to: CGPoint(x: 0, y: cornerRadius))
        addArc(
            withCenter: CGPoint(x: cornerRadius, y: cornerRadius),
            radius: cornerRadius,
            startAngle: .pi,
            endAngle: .pi * 3 / 2,
            clockwise: true
        )

        close()
        apply(CGAffineTransform(
            translationX: frame.origin.x,
            y: frame.origin.y
        ))
    }

}
