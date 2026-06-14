//
//  ChargerSuccessViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 26.11.23.
//

import UIKit

class ChargerSuccessViewController: MimoBaseViewController {
    
    @IBOutlet private weak var navigationBar: UINavigationBar!
    @IBOutlet private weak var thanksLabel: UILabel!
    @IBOutlet private weak var contentContainerView: UIView!
    @IBOutlet private weak var amountLabel: UILabel!
    @IBOutlet private weak var chargerIDLabel: UILabel!
    @IBOutlet private weak var stationIDLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var planLabel: UILabel!
    
    var rentedCharger: RentedCharger?
    var currency: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        amountLabel.text = String(format: "%.2f \(currency ?? "₽‎")", rentedCharger?.data?.billingDetails?.amount ?? 0)
        stationIDLabel.text = rentedCharger?.data?.startStationQR ?? "-"
        chargerIDLabel.text = rentedCharger?.powerBank?.id
        navigationBar.topItem?.title = "MOBILE_charger_thankYou_navigationTitle".localized()
        planLabel.text = rentedCharger?.data?.billingDetails?.currentTariff?.priceName
        
        let startDate = rentedCharger?.data?.start ?? 0
        let endDate = rentedCharger?.data?.end ?? 0
        let duration = (endDate - startDate)/1000
        
        durationLabel.text = DateComponentsFormatter.hmsFormatter.string(from: TimeInterval(duration))
        
        contentContainerView.addShadow(color: .black.withAlphaComponent(0.3), offset: .init(width: 0, height: 2), shadowRadius: 4)
    }
    
    @IBAction private func thankYouAction() {
        let messagingService: MessageServiceProtocol = Resolver.resolve()
        messagingService.publish(.chargerRentEnded)
        
        self.dismiss(animated: true)
    }
    
    @IBAction private func shareAction() {
        
    }
}
