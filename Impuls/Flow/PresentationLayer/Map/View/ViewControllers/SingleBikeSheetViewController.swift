//
//  SingleBikeSheetViewController.swift
//  MimoBike
//
//  Created by Vardan on 21.04.21.
//

import UIKit
import CoreLocation

protocol SingleBikeSheetViewControllerDelegate: AnyObject {
    func didTappedJoinAndBook()
}

final class SingleBikeSheetViewController: UIViewController, StoryboardInitializable {

    
    //MARK: - Outlets
    @IBOutlet weak var bikeImageView: AnimatedView!
    
    @IBOutlet weak var bikeAnimatedView: AnimatedView!
    
    @IBOutlet weak var joinAndBookContentView: UIView!
    @IBOutlet weak var bookingOfferLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    
    let viewModel = MapViewModel()
    
    
    //MARK: Variables
    weak var delegate: SingleBikeSheetViewControllerDelegate?
    var locationManager = CLLocationManager()
    
    var bikeResult: BikeResult?
    
    //MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    
    //MARK: - Methods
    
    private func configureUI() {
        
        bikeAnimatedView.didPlayRequestedCount = {[weak self] in
            self?.bikeImageView.isHidden = false
            self?.bikeImageView.alpha = 0
            UIView.animate(withDuration: 0.5) {
                self?.bikeImageView.alpha = 1
            }
        }
        
//        bikeResult?.getLocationName(long: true, completed: { [weak self] (name) in
//            self?.locationLabel.text = name
//        })
//        timeLabel.text = bikeResult?.timePrettyPrinted()
        bookingOfferLabel.colorString(text: "MOBILE_book_free_booking_offer".localized(), coloredText: ["free booking"], color: .mimoBlackWith05alpha, font: UIFont(name: "Roboto-Regular", size: 15)!)
        joinAndBookContentView.layer.cornerRadius = Constant.CornerRadius.cornerRadius24
        
        self.getDistance()
    }
    
    private func getDistance() {

        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            guard let location = locationManager.location else {
                return
            }
//            distanceLabel.text = bikeResult?.getDistancePrettyPrinted(userCoordinate: location.coordinate).1
        }
    }
    
    
    
    //MARK: - Actions

    @IBAction func joinAndBookTapped(_ sender: UIButton) {
        delegate?.didTappedJoinAndBook()
    }
}


extension SingleBikeSheetViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
//        distanceLabel.text = bikeResult?.getDistancePrettyPrinted(userCoordinate: locValue).1
    }
}
