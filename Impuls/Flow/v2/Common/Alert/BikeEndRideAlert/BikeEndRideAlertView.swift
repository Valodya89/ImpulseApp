//
//  BikeEndRideAlertView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.10.23.
//

import UIKit

class BikeEndRideAlertView: UIViewController {
    
    @IBOutlet private weak var travelTimeLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    
    var travelTime: String? {
        didSet {
            if isViewLoaded {
                travelTimeLabel.text = travelTime
            }
        }
    }
    
    var price: String? {
        didSet {
            if isViewLoaded {
                priceLabel.text = price
            }
        }
    }
    
    var completion: (() -> Void)?
  
    init() {
        super.init(nibName: "BikeEndRideAlertView", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        travelTimeLabel.text = travelTime
        priceLabel.text = price
    }
    
    @IBAction private func closeAction() {
        self.dismiss(animated: true, completion: completion)
    }

}
