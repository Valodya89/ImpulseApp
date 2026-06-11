//
//  BikeTripSheetViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.07.23.
//

import UIKit
import Combine
import CoreLocation

class BikeTripSheetViewController: MimoBaseViewController {
    
    private var cancellables = Set<AnyCancellable>()
    
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var qrLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var techCheckUpLabel: UILabel!
    @IBOutlet private weak var techCheckUpTitleLabel: UILabel!
    @IBOutlet private weak var travelTimeLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var priceLabel: UILabel!
    @IBOutlet private weak var endRideButton: UILocalizedButton!
    
    var viewModel: BikeTripViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let viewModel else { return }

        viewModel.$tripData.sink(receiveValue: { [weak self] tripData in
            guard let self else { return }
            
            self.qrLabel.text = tripData.bikeDto?.qr
            self.priceLabel.text = String(format: "%.2f ֏", tripData.data?.amount ?? 0)
            
            if let bikeData = tripData.bikeDto {
                self.techCheckUpLabel.text = HomeMapper.toBikeResults(from: [bikeData]).first?.timePrettyPrinted
            }
            
            self.viewModel?.getBikeAddress()
            
            if let price = priceLabel.text, tripData.action == .TripOutOfZone {
                BikeRouter.shared.showEndRideAlert(self, price: price)
            }
        })
        .store(in: &cancellables)
        
        cancellables.insert(viewModel.$address.assign(to: \.text, on: addressLabel))
        
        Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink(receiveValue: { [weak self] _ in
                guard let start = viewModel.tripData.data?.start else { return }
                
                let _start = Double(start)/1000
                let duration = Date().timeIntervalSince1970 - _start
                
                self?.travelTimeLabel.text = DateComponentsFormatter.hmsFormatter.string(from: TimeInterval(duration))
                BikeRouter.shared.endRideAlertView?.travelTime = self?.travelTimeLabel.text
            })
            .store(in: &cancellables)
        
        techCheckUpTitleLabel.text = String("MOBILE_guest_map_global_tech_check_up".localized().dropLast().dropLast()).trimmingCharacters(in: .whitespacesAndNewlines) + ":"
    }
    
    @IBAction private func openAgainAction() {
        viewModel?.unlockBike()
    }
    
    @IBAction private func endRideAction() {
        if viewModel?.tripData.action == .TripOutOfZone {
            guard let travelTime = travelTimeLabel.text, let price = priceLabel.text else { return }
            BikeRouter.shared.showEndRideAlert(self, travelTime: travelTime, price: price)
        } else {
//            UIAlertController.showError(message: "MOBILE_lock_bike".localized())
            
            var sheetOptions = SheetOptions()
            sheetOptions.pullBarHeight = 10
            sheetOptions.useInlineMode = true
            
            let closeLockSheetVC = BikeCloseLockSheetViewController()
            let sheetViewController = SheetViewController(controller: closeLockSheetVC, sizes: [.fixed((UIApplication.shared.keyWindowInConnectedScenes?.safeAreaBottom ?? 0) + 170)], options: sheetOptions)
            sheetViewController.setupMimoConfigs()
            sheetViewController.dismissOnOverlayTap = true
            sheetViewController.dismissOnPull = true
            sheetViewController.allowPullingPastMinHeight = false
            sheetViewController.gripColor = .clear
            closeLockSheetVC.closeTapped = {
                sheetViewController.attemptDismiss(animated: true)
            }
            
            sheetViewController.animateIn(to: view, in: self)
        }
    }
    
    @IBAction private func mapAction() {
        guard let latitude = viewModel?.tripData.bikeDto?.latitude,
              let longitude = viewModel?.tripData.bikeDto?.longitude else { return }
        
        OpenMapDirections.present(in: self, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
    }
}
