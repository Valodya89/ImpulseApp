//
//  RentedChargerCollectionViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 18.03.24.
//

import UIKit
import Combine

class RentedChargerCollectionViewCell: BaseCollectionViewCell {
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var powerBankNumberLabel: UILabel!
    @IBOutlet private weak var currentPlanLabel: UILabel!
    @IBOutlet private weak var nextPlanPlanLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    
    @IBOutlet private weak var onePlanTitleLabel: UILabel!
    @IBOutlet private weak var onePlanSubtitleLabel: UILabel!
    
    @IBOutlet private weak var plansContainerView: UIView!
    @IBOutlet private weak var onePlanContainerView: UIView!
    
    private var timer: AnyCancellable?
    
    func set(rentedCharger: RentedCharger, currency: String) {
        nameLabel.text = rentedCharger.data?.startStationQR
        powerBankNumberLabel.text = rentedCharger.data?.powerBank
        priceLabel.text = String(format: "%.2f \(currency)", rentedCharger.data?.billingDetails?.amount ?? 0)
        plansContainerView.isHidden = true
        onePlanContainerView.isHidden = true
        
        if let activePackage = rentedCharger.data?.activePackage, rentedCharger.data?.activePackageValid ?? false {
            onePlanContainerView.isHidden = false
            onePlanTitleLabel.text = "MOBILE_charger_package_\(activePackage.name)".localized()
            let startDate = Date(timeIntervalSince1970: TimeInterval(activePackage.start)/1000)
            let endDate = Date(timeIntervalSince1970: TimeInterval(activePackage.end)/1000)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm, dd-MM-yyyy"
            
            let startDateString = dateFormatter.string(from: startDate)
            let endDateString = dateFormatter.string(from: endDate)
            
            onePlanSubtitleLabel.text = "\(startDateString) - \(endDateString)"
        } else if let billingDetails = rentedCharger.data?.billingDetails {
            plansContainerView.isHidden = false
            
            self.onePlanTitleLabel.text = "MOBILE_charger_currentPlan".localized()
            self.currentPlanLabel.text = billingDetails.currentTariff?.priceName
            self.onePlanSubtitleLabel.text = billingDetails.currentTariff?.priceName
            
            if let nextTariff = billingDetails.nextTariff {
                self.nextPlanPlanLabel.text = nextTariff.priceName
            } else {
                onePlanContainerView.isHidden = false
                plansContainerView.isHidden = true
            }
        }
        
        let start = (rentedCharger.data?.start ?? 0)/1000
        let duration = Date().timeIntervalSince1970 - start
        self.durationLabel.text = DateComponentsFormatter.hmsFormatter.string(from: TimeInterval(duration))
        
        if self.timer == nil {
            timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                .sink(receiveValue: { _ in
                    let start = (rentedCharger.data?.start ?? 0)/1000
                    let duration = Date().timeIntervalSince1970 - start
                    self.durationLabel.text = DateComponentsFormatter.hmsFormatter.string(from: TimeInterval(duration))
                })
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.timer = nil
    }

}
