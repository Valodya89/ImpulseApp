//
//  MimoPauseViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 04.06.23.
//

import UIKit
import Combine

protocol MimoPauseViewControllerDelegate: AnyObject {
    func continuePausedTrip()
}

class MimoPauseViewController: BaseViewController {
    
    private var cancelables = Set<AnyCancellable>()
    
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var priceTitleLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var continueButton: UIButton!
    
    public var lastPause: Double = 0
    public var pauseSum: Double = 0
    public weak var delegate: MimoPauseViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        continueButton.setTitle("SCOOTER_global_continue".localized(), for: .normal)
        priceTitleLabel.text = "\("SCOOTER_pause_price".localized())֏/\("SCOOTER_global_minute".localized().capitalized)"

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self, isViewLoaded else { return }
            let interval = Date().timeIntervalSince1970 - lastPause + pauseSum
            self.durationLabel.text = DateComponentsFormatter.hmsFormatter.string(from: TimeInterval(interval))
            self.updatePrice(duration: Int(interval))
        }
    }
    
    private func updatePrice(duration: Int) {
        let priceAmount = Int("SCOOTER_pause_price".localized()) ?? 5
        let price = Int(duration/60) * priceAmount
        priceLabel.text = "\(price)֏"
    }
    
    @IBAction private func continueAction() {
        delegate?.continuePausedTrip()
    }

}
