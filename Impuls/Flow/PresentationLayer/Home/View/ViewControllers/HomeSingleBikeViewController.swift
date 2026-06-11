//
//  HomeSingleBikeViewController.swift
//  MimoBike
//
//  Created by Vardan on 08.05.21.
//

import UIKit
import CoreLocation

protocol HomeSingleBikeViewControllerDelegate: AnyObject {
    func didSelectBookNow(singleBike: HomeSingleBikeViewController)
}

final class HomeSingleBikeViewController: BaseViewController, StoryboardInitializable {

    
    //MARK: - Life outlets
    @IBOutlet weak var bikeImageView: AnimatedView!
    
    @IBOutlet weak var bikeAnimatedView: AnimatedView!
    @IBOutlet weak var addBalanceButton: UIButton!
    @IBOutlet weak var bookingOfferLabel: UILabel!
    @IBOutlet weak var bookNowButton: UIButton!
    @IBOutlet weak var freeMinutesLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var bikeTimeLabel: UILabel!
    
    
    //MARK: - Variables

    weak var delegate: HomeSingleBikeViewControllerDelegate?
    var bikeResult: BikeResult?
    var userResult: UserResult?
    var avatarUrlStirng: String?
    var locationManager = MALocation.current
    let viewModel = HomeSingleBikeViewModel()
    var isBooked: Bool!
    var walletNavigationController: UINavigationController?
    
    //MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        print(userResult)
    }
    
    //MARK: - Methods
    
    private func configureUI() {
        bookNowButton.isHidden = isBooked
        bookingOfferLabel.isHidden = isBooked
        bikeAnimatedView.didPlayRequestedCount = {[weak self] in
            self?.bikeImageView.isHidden = false
            self?.bikeImageView.alpha = 0
            UIView.animate(withDuration: 0.5) {
                self?.bikeImageView.alpha = 1
            }
        }
        self.viewModel.getUser { [weak self] (result) in
            switch result {
            case .success(let user):
                self?.userResult = user
                if (UserDefaults.standard.value(forKey: "BikeState") as? String) == "bike" {
                    self?.freeMinutesLabel.text = user.minutes.description
                } else {
                    self?.freeMinutesLabel.text = "0"
                }
                
            case .failure: break
            }
        }
        
        self.viewModel.walletInfo { [weak self] (result) in
            switch result {
            case .success(let wallet):
                self?.balanceLabel.text = wallet.balance.description
            case .failure: break
            }
        }
        
        self.viewModel.getAvatar { [weak self] (avatarUrlStirng) in
            self?.avatarUrlStirng = avatarUrlStirng
        }
        
        let freeBookingFilterText = "MOBILE_book_free_booking".localized().lowercased()
        
        let freeBooking = "MOBILE_guest_map_free_booking_minutes".localized().replacingOccurrences(of: "[num]", with: 5.description)
        bookingOfferLabel.colorString(text: "MOBILE_book_free_booking_offer".localized(), coloredText: [freeBookingFilterText], color: .mimoBlackWith05alpha, font: UIFont(name: "Roboto-Regular", size: 15)!)
        addBalanceButton.layer.cornerRadius = Constant.CornerRadius.cornerRadius19
        bookNowButton.layer.cornerRadius = Constant.CornerRadius.cornerRadius24
//        bikeTimeLabel.text = bikeResult?.timePrettyPrinted()
//        bikeResult?.getLocationName(long: true, completed: { [weak self] (location) in
//            self?.locationLabel.text = location
//        })
        self.getDistance()
    }
    
    private func getDistance() {
        
        // For use in foreground
        guard let location = locationManager.currentLocation else {
            locationManager.alertLocationAccess()
            distanceLabel.text = ""
        
            return
        }
//        distanceLabel.text = bikeResult?.getDistancePrettyPrinted(userCoordinate: location.coordinate).1
    }
    
    //MARK: - Actions

    @IBAction func bookNowTapped(_ sender: UIButton) {
        VibrateManager.vibrate()
        delegate?.didSelectBookNow(singleBike: self)
    }
    
    @IBAction func addBalanceTapped(_ sender: Any) {
        VibrateManager.vibrate()
        let walletVC = WalletViewController.initFromStoryboard(name: Constant.Storyboards.wallet)
        self.walletNavigationController = UINavigationController(rootViewController: walletVC)
        
        let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_arrow_left"), style: .plain, target: self, action: #selector(backButtonTapped))
        walletVC.navigationItem.leftBarButtonItem = backButton
        
        walletVC.user = userResult
        walletVC.avataturURLString = avatarUrlStirng
        
        self.present(walletNavigationController!, animated: true, completion: nil)
    }
    
    @objc func backButtonTapped() {
        VibrateManager.vibrate()
        self.walletNavigationController?.dismiss(animated: true, completion: nil)
    }
}


extension HomeSingleBikeViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
//        distanceLabel.text = bikeResult?.getDistancePrettyPrinted(userCoordinate: locValue).1
    }
}
