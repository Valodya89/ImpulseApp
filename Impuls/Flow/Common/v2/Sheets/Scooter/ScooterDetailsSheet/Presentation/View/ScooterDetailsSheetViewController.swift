//
//  ScooterDetailsSheetViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.05.23.
//

import UIKit
import Combine
import CoreLocation
import MapKit

protocol ScooterDetailsSheetViewControllerDelegate: AnyObject {
    func bookScooter(with id: String)
    func cancelScooterBooking(with id: String)
    func startRide(with scooterId: String)
    func startLeasedScooter(with scooterId: String)
    func stopLeasedScooter(with scooterId: String)
    func openLeasedScooter(with scooterId: String)
    func scooterBookingEnded()
}

class ScooterDetailsSheetViewController: UIViewController {
    
    @IBOutlet private weak var bookedTimerView: UIView!
    @IBOutlet private weak var bookedTimerLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var freeMinutesLabel: UILabel!
    @IBOutlet private weak var scooterNameLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var batteryPercentLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var qrLabel: UILabel!
    
    @IBOutlet private weak var batteryImageView: UIImageView!
    
    @IBOutlet private weak var ringButton: UIButton!
    @IBOutlet private weak var reportButton: UIButton!
    @IBOutlet private weak var bookButton: UIButton!
    @IBOutlet private weak var startRideButton: UIButton!
    @IBOutlet private weak var startLeasedScooterButton: UIButton!
    @IBOutlet private weak var stopLeasedScooterButton: UIButton!
    @IBOutlet private weak var openLeasedScooterButton: UIButton!
    
    var viewModel: ScooterDetailsViewModel?
    weak var delegate: ScooterDetailsSheetViewControllerDelegate?
     
    private var subscriptions = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupData()
        setupBalance()
    }
    
    func setupData() {
        guard let viewModel else { return }
        
        bookedTimerView.isHidden = true
        
        bookButton.isHidden = viewModel.hasLeasedScooters
        startRideButton.isHidden = viewModel.hasLeasedScooters
        startLeasedScooterButton.isHidden = !viewModel.hasLeasedScooters
        stopLeasedScooterButton.isHidden = !viewModel.hasLeasedScooters
        openLeasedScooterButton.isHidden = !viewModel.hasLeasedScooters
        
        if let scooterData = viewModel.scooterData {
            batteryPercentLabel.text = scooterData.batteryPercent.percentPrettyPrinted
            batteryImageView.image = scooterData.batteryPercent.image
            durationLabel.text = scooterData.remainingMileage.prettyPrinted
            qrLabel.text = scooterData.qr
            bookButton.setTitle("MOBILE_map_book_now".localized(), for: .normal)
            ringButton.isUserInteractionEnabled = false
            ringButton.alpha = 0.6
        } else if let scooterState = viewModel.scooterState?.scooter {
            batteryPercentLabel.text = scooterState.batteryPercent?.percentPrettyPrinted
            batteryImageView.image = scooterState.batteryPercent?.image
            durationLabel.text = scooterState.remainingMileage?.prettyPrinted
            qrLabel.text = scooterState.qr
            
            if viewModel.scooterState?.state == .Booking_Started {
                bookedTimerView.isHidden = false
                bookedTimerLabel.text = "\("SCOOTER_global_booked".localized()) 00:00"
                bookButton.setTitle("MOBILE_book_stop".localized(), for: .normal)
                ringButton.isUserInteractionEnabled = true
                ringButton.alpha = 1
                
                let endDate = ((viewModel.scooterState?.data?.start ?? 0) + 300000)/1000
                Timer.publish(every: 1, on: .main, in: .common).autoconnect()
                    .sink { [weak self] _ in
                        let interval = max(0, endDate - Date().timeIntervalSince1970)
                        
                        if let bookingDuration = DateComponentsFormatter.msFormatter.string(from: TimeInterval(interval)) {
                            self?.bookedTimerLabel.text = "\("SCOOTER_global_booked".localized()) \(bookingDuration)"
                        }
                        
                        if interval == 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
                                self?.delegate?.scooterBookingEnded()
                            }
                        }
                    }
                    .store(in: &subscriptions)
            } else {
                bookButton.setTitle("MOBILE_map_book_now".localized(), for: .normal)
            }
        }
        
        subscriptions.insert(viewModel.$address.assign(to: \.text, on: addressLabel))
        scooterNameLabel.text = "MAX PLUSE"
        ringButton.setTitle("  \("SCOOTER_global_signal".localized())  ", for: .normal)
        
        viewModel.getScooterAddress()
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
    
    @IBAction private func bookAction() {
        guard let scooterId = viewModel?.scooterData?.id ?? viewModel?.scooterState?.data?.id else { return }
        
        if viewModel?.scooterState?.state == .Booking_Started {
            delegate?.cancelScooterBooking(with: scooterId)
        } else {
            delegate?.bookScooter(with: scooterId)
        }
    }
    
    @IBAction private func startRideAction() {
        guard let scooterId = viewModel?.scooterData?.id ?? viewModel?.scooterState?.scooter?.id else { return }
        
        delegate?.startRide(with: scooterId)
    }
    
    @IBAction private func startLeasedScooterAction() {
        guard let scooterId = viewModel?.scooterData?.id ?? viewModel?.scooterState?.scooter?.id else { return }
        
        delegate?.startLeasedScooter(with: scooterId)
    }
    
    @IBAction private func stopLeasedScooterAction() {
        guard let scooterId = viewModel?.scooterData?.id ?? viewModel?.scooterState?.scooter?.id else { return }
        
        delegate?.stopLeasedScooter(with: scooterId)
    }
    
    @IBAction private func openLeasedScooterAction() {
        guard let scooterId = viewModel?.scooterData?.id ?? viewModel?.scooterState?.scooter?.id else { return }
        
        delegate?.openLeasedScooter(with: scooterId)
    }
    
    @IBAction private func replenishAction() {
        VibrateManager.vibrate()
        
        openWallet()
    }
    
    @IBAction private func openInMapsAction() {
        guard let latitude = viewModel?.scooterData?.latitude ?? viewModel?.scooterState?.scooter?.located?.latitude,
              let longitude = viewModel?.scooterData?.longitude ?? viewModel?.scooterState?.scooter?.located?.longitude else { return }
        
        OpenMapDirections.present(in: self, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
    }
    
    @IBAction private func beepAction() {
        viewModel?.beepBookedScooter()
            .sink(receiveValue: { _ in
                if let window = UIApplication.shared.keyWindowInConnectedScenes {
                    window.addSubview(BeepView(frame: window.bounds))
                }
            })
            .store(in: &subscriptions)
    }
}
