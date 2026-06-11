//
//  BikeDetailsSheetViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.07.23.
//

import UIKit
import Combine

protocol BikeDetailsSheetViewControllerDelegate: AnyObject {
    func bookAction(id: String)
    func cancelBooking(id: String)
    func tariffsAction()
}

class BikeDetailsSheetViewController: MimoBaseViewController {
    
    @IBOutlet private weak var bikeAnimatedView: AnimatedView!
    @IBOutlet private weak var bikeImageView: UIImageView!
    @IBOutlet private weak var freeMinutesLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var techCheckUpMinutesLabel: UILabel!
    @IBOutlet private weak var freeBookingLabel: UILabel!
    @IBOutlet private weak var bookButton: UIButton!
    @IBOutlet private weak var bookingView: UIView!
    @IBOutlet private weak var bookingTimerLabel: UILabel!
    @IBOutlet private weak var qrLabel: UILabel!
    
    private var subscriptions = Set<AnyCancellable>()
    private var timerSubscription: AnyCancellable?
    
    var viewModel: BikeDetailsViewModel?
    weak var delegate: BikeDetailsSheetViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupBalance()
        setupData()
        
        viewModel?.getBikeAddress()
    }
    
    private func setupUI() {
        bikeAnimatedView.didPlayRequestedCount = { [weak self] in
            self?.bikeImageView.isHidden = false
            self?.bikeImageView.alpha = 0
            UIView.animate(withDuration: 0.5) {
                self?.bikeImageView.alpha = 1
            }
        }
    }
    
    private func setupBalance() {
        guard let walletInfo = viewModel?.walletInfo, let financialState = viewModel?.financialState else { return }
        
        if walletInfo.balance - (financialState.additional ?? 0) < 0 {
            balanceLabel.textColor = .red
        } else {
            balanceLabel.textColor = .mimoBlackWith075alpha
        }
        
        let balance = (walletInfo.balance - (financialState.additional ?? 0)).rounded()
        balanceLabel.text = String(format: "%.2f", balance)
        
        freeMinutesLabel.text = String(format: "%.2f", viewModel?.user?.minutes ?? 0)
    }
    
    private func setupData() {
        guard let viewModel else { return }
        subscriptions.insert(viewModel.$address.assign(to: \.text, on: addressLabel))
        
        techCheckUpMinutesLabel.text = viewModel.bikeData?.timePrettyPrinted
        qrLabel.text = viewModel.bikeData?.qr
        
        viewModel.$currentLocation.sink { [weak self] currentLocation in
            guard let self, let currentLocation, let bikeCoordinate = viewModel.bikeData?.coordinate else { return }
            
            let distance = currentLocation.distance(to: bikeCoordinate)
            self.distanceLabel.text = distance.prettyDistance
        }
        .store(in: &subscriptions)
        
        viewModel.$bikeState.sink { [weak self] state in
            guard let self else { return }
            
            if state?.action == .Booking_Started {
                self.bookingView.isHidden = false
                self.bookButton.setTitle("MOBILE_book_stop".localized(), for: .normal)
                
                guard self.timerSubscription == nil else { return }
                let _startDate = Double(viewModel.bikeState?.data?.start ?? 0)/1000
                timerSubscription = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                    .sink { [weak self] _ in
                        let duration = Date().timeIntervalSince1970 - _startDate
                        if let bookingDuration = DateComponentsFormatter.msFormatter.string(from: TimeInterval(duration)) {
                            self?.bookingTimerLabel.text = "\("SCOOTER_global_booked".localized()) \(bookingDuration)"
                        }
                    }
            } else {
                self.bookingView.isHidden = true
                self.bookingTimerLabel.text = "\("SCOOTER_global_booked".localized()) 00:00"
                self.bookButton.setTitle("MOBILE_map_book_now".localized(), for: .normal)
                timerSubscription?.cancel()
                timerSubscription = nil
            }
        }
        .store(in: &subscriptions)
    }
    
    @IBAction private func bookAction() {
        guard let id = viewModel?.bikeData?.id else { return }
        
        if viewModel?.bikeState?.action == .Booking_Started {
            delegate?.cancelBooking(id: id)
        } else {
            delegate?.bookAction(id: id)
        }
    }
    
    @IBAction private func tariffsAction() {
        delegate?.tariffsAction()
    }
    
    @IBAction private func balanceAction() {
        VibrateManager.vibrate()
        openWallet()
    }
}
