//
//  ZoneStatusView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.08.23.
//

import Foundation
import UIKit

class ZoneStatusView: UIView {
    
    private var textLabel: UILabel!
    
    var isInParkingZone: Bool = false {
        didSet {
            if isInParkingZone {
                self.backgroundColor = .zoneGreen.withAlphaComponent(0.4)
                self.textLabel.text = "MOBILE_global_parking_zone".localized()
            } else {
                self.backgroundColor = .zoneRed.withAlphaComponent(0.4)
                self.textLabel.text = "MOBILE_global_non_parking_zone".localized()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        setupUI()
    }
    
    private func setupUI() {
        textLabel = UILabel()
        textLabel.font = .systemFont(ofSize: 14, weight: .medium)
        textLabel.textColor = .black
        textLabel.text = "Parking zone"
        textLabel.textAlignment = .center
        addSubview(textLabel)
        
        isInParkingZone = false
        
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        let horizontalConstraint = NSLayoutConstraint(item: textLabel!, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        let verticalConstraint = NSLayoutConstraint(item: textLabel!, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
        let widthConstraint = NSLayoutConstraint(item: textLabel!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: textLabel!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1, constant: 0)
        self.addConstraints([horizontalConstraint, verticalConstraint, widthConstraint, heightConstraint])
    }
}
