//
//  PauseViewController.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/28/22.
//

import UIKit

protocol PauseViewControllerDelegate: AnyObject {
    func didClosePause()
}

public final class PauseViewController: UIViewController, StoryboardInitializable {

    // MARK: Outlets
    @IBOutlet private weak var alertView: UIView!
    @IBOutlet private weak var pauseTitleLabel: UILabel!
    @IBOutlet private weak var pausePriceLabel: UILabel!
    @IBOutlet private weak var pauseTimeTitleLabel: UILabel!
    @IBOutlet private weak var pauseTimeLabel: UILabel!
    @IBOutlet private weak var priceTitleLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var continueButton: UIButton!
    @IBOutlet weak var tenSecLbl: UILabel!
    
    weak var delegate: PauseViewControllerDelegate?
    var timerManager: TimerManager?
    var timerManager1: TimerManager?
    var countedPrice: Int = 0
    var pausStarted: Double = 0
    
    // MARK: View Lfecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.continueButton.isEnabled = false
        self.continueButton.isUserInteractionEnabled = false
        setupView()
        timerManager1 = TimerManager(timerLabel: tenSecLbl, duration: 11, formaterUnits: [.second], timerState: .decrement)
        timerManager1?.labelFont = UIFont(name: "Roboto-Bold", size: 18)!
        timerManager1?.timerDurationColor = .mimoBlack
        timerManager1?.delegate = self
        timerManager1?.startTimer()

    }
    
    
    func updateTime() {
        setupScanTimer(time: pausStarted)
        countedPrice = Int(Int(pausStarted) / 60) * 5
        priceLabel.text = "\(countedPrice) ֏"
    }
    
    // MARK: Methods
    private func setupView() {
        alertView.layer.cornerRadius = 12
        continueButton.layer.cornerRadius = 24
    }
    
    func setupScanTimer(time: Double) {
        
        timerManager = TimerManager(timerLabel: pauseTimeLabel, duration: time, formaterUnits: [.hour, .minute, .second], timerState: .increment)
        timerManager?.labelFont = UIFont(name: "Roboto-Bold", size: 20)!
        timerManager?.timerDurationColor = .mimoBlack
        timerManager?.delegate = self
        timerManager?.startTimer()
    }
    // MARK: Actions
    @IBAction private func continueButtonAction(_ sender: UIButton) {
        self.timerManager?.stopTimer()
        delegate?.didClosePause()
    }
    
}

extension PauseViewController: TimerManagerDelegate {
    
    func didChanchTimeSeconds(seconds: Double) {
        if self.tenSecLbl == nil {
            print("self is nill")
            return
        }
        if seconds >= 11 || seconds <= 0 {
            self.tenSecLbl.text = ""
            self.continueButton.isEnabled = true
            self.continueButton.isUserInteractionEnabled = true
        }
        
        countedPrice = Int(Int(seconds) / 60) * 5
        priceLabel.text = "\(countedPrice) ֏"
    }
    
    func didExpireDuration(timer: TimerManager) {
        
        if timer === timerManager {
//            self.markers.map { $1 }.forEach { $0.map = self.mapView }
//            self.updateControllerState(state: .previewBikes(reloadData: true))
//            self.singleBikeBookNowTapped = false
//            self.timerManager?.stopTimer()
//            self.bookedDevice = nil
        }
        
    }
}
