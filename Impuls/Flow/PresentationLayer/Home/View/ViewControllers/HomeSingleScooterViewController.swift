//
//  HomeSingleBikeViewController.swift
//  MimoBike
//
//  Created by Vardan on 08.05.21.
//

import UIKit
import CoreLocation

protocol HomeSingleScooterViewControllerDelegate: AnyObject {
    func didSelectBookNow(singleScooter: HomeSingleScooterViewController)
    func didSelectStartRide(singleScooter: HomeSingleScooterViewController)
}

final class HomeSingleScooterViewController: BaseViewController, StoryboardInitializable {

    
    //MARK: - Life outlets
    @IBOutlet weak var addBalanceButton: UIButton!
    @IBOutlet weak var freeMinutesLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    
    @IBOutlet weak var scooterImageView: AnimatedView!
    @IBOutlet weak var scooterNameLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var batteryPercentageImageView: UIImageView!
    @IBOutlet weak var batteryPercentageLabel: UILabel!
    @IBOutlet weak var rangeLabel: UILabel!
    
    @IBOutlet weak var ringButton: UIButton!
    @IBOutlet weak var reportIssueButton: UIButton!
    @IBOutlet weak var bookNowButton: UIButton!
    @IBOutlet weak var startRideButton: UIButton!
    @IBOutlet weak var viewForQR: UIView!
    @IBOutlet weak var qrLabel: UILabel!

    //MARK: - Variables
    private let homeViewModel = HomeViewModel()
    weak var delegate: HomeSingleScooterViewControllerDelegate?
    var scooterResult: ScooterResult?
    var userResult: UserResult?
    var avatarUrlStirng: String?
    var locationManager = MALocation.current
    let viewModel = HomeSingleBikeViewModel()
    var isBooked: Bool!
    var walletNavigationController: UINavigationController?
    var singleScooterResult: SingleScooterResponse?
    
    //MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        
//        getSingleScooterData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(userResult)
    }
    
    //MARK: - Methods
    
    private func configureUI() {
        bookNowButton.isHidden = isBooked
//        bookingOfferLabel.isHidden = isBooked
//        bikeAnimatedView.didPlayRequestedCount = {[weak self] in
//            self?.bikeImageView.isHidden = false
//            self?.bikeImageView.alpha = 0
//            UIView.animate(withDuration: 0.5) {
//                self?.bikeImageView.alpha = 1
//            }
//        }
        self.viewModel.getUser { [weak self] (result) in
            switch result {
            case .success(let user):
                self?.userResult = user
                self?.freeMinutesLabel.text = user.minutes.description
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
        
//        let freeBookingFilterText = "MOBILE_book_free_booking".localized().lowercased()
        
//        let freeBooking = "MOBILE_guest_map_free_booking_minutes".localized().replacingOccurrences(of: "[num]", with: 5.description)
//        bookingOfferLabel.colorString(text: "MOBILE_book_free_booking_offer".localized(), coloredText: [freeBookingFilterText], color: .mimoBlackWith05alpha, font: UIFont(name: "Roboto-Regular", size: 15)!)
        addBalanceButton.layer.cornerRadius = Constant.CornerRadius.cornerRadius19
        bookNowButton.layer.cornerRadius = bookNowButton.frame.height / 2
        bookNowButton.layer.borderColor = UIColor.mimoBlackWith075alpha.cgColor
        bookNowButton.layer.borderWidth = 1
        startRideButton.layer.cornerRadius = startRideButton.frame.height / 2
//        bikeTimeLabel.text = bikeResult?.timePrettyPrinted()
//        scooterResult?.getLocationName(long: true, completed: { [weak self] (location) in
//            self?.locationLabel.text = location
//        })
        self.getDistance()
        updateUI(scoterResult: scooterResult)
    }
    
//    func configureUI() {
//        bokkeButtone.layer.borderColor = UIColor.mimoBlackWith075alpha.cgColor
//        bokkeButtone.layer.borderWidth = 1
//        bokkeButtone.layer.cornerRadius = Constant.CornerRadius.cornerRadius19
//        takeScooterButton.layer.cornerRadius = Constant.CornerRadius.cornerRadius19
//        viewForShadow.addShadow(color: .mimoBlackWith025alpha)
//        contentBGView.layer.cornerRadius = 12
//    }
    
    func updateUI(scoterResult: ScooterResult?) {
        self.scooterResult = scoterResult
//        self.scoterResult?.setLocationName(long: false, in: scooterName)
        self.scooterNameLabel.text = "MAX PLUSE" //scoterResult?.type ?? ""
        let range = Double(scoterResult?.remainingMileage ?? 0) / 1000
        let timeInMinutes = range / 20 * 60 // default speed is 20km/h
        let formattedTime = secondsToHoursMinutes(Int(timeInMinutes))
        self.rangeLabel.text = "≈\(timeInMinutes > 60 ? "\(formattedTime.0)\("SCOOTER_global_hour".localized()) \(formattedTime.1)\("SCOOTER_global_minute".localized())" : "\(formattedTime.1)\("SCOOTER_global_minute".localized())")\n (\(range)\("SCOOTER_global_km_range".localized()))"
        self.batteryPercentageLabel.text = "\(scoterResult?.batteryPercent ?? 0)%"
        
        setImage()
        viewForQR.layer.borderColor = UIColor.mimoYellow500.cgColor
        viewForQR.layer.borderWidth = 2.0
        viewForQR.layer.cornerRadius = viewForQR.frame.height / 2
        qrLabel.text = scooterResult?.qr
    }
    
    private func secondsToHoursMinutes(_ minutes: Int) -> (hours: Int, minutes: Int) {
        return (minutes / 60, minutes % 60)
    }
    
    func setImage() {
        switch scooterResult?.batteryPercent ?? 0 {
        case 0...20:
            self.batteryPercentageImageView.image = UIImage(named: "ic_battery_H_0")
        case 21...40:
            self.batteryPercentageImageView.image = UIImage(named: "ic_battery_H_25")
        case 41...60:
            self.batteryPercentageImageView.image = UIImage(named: "ic_battery_H_50")
        case 61...80:
            self.batteryPercentageImageView.image = UIImage(named: "ic_battery_H_75")
        case 81...100:
            self.batteryPercentageImageView.image = UIImage(named: "ic_battery_H_100")
        default: break
        }
    }
    
    private func getDistance() {
        
        // For use in foreground
        guard let location = locationManager.currentLocation else {
            locationManager.alertLocationAccess()
//            distanceLabel.text = ""
        
            return
        }
//        distanceLabel.text = bikeResult?.getDistancePrettyPrinted(userCoordinate: location.coordinate).1
    }
    
    
    func getSingleScooterData() {
        homeViewModel.getScooterDetails(id: scooterResult?.id ?? "") { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .success(let data):
                self.singleScooterResult = data
                print(data)
            case .failure(let error):
                print(error)
                switch error {
                case .validatorError(let message):
                    UIAlertController.showError(message: message.localized())
                default:
                    UIAlertController.showError(message: "Server error!")
                }
            }
        }
    }
    //MARK: - Actions

    @IBAction func bookNowTapped(_ sender: UIButton) {
        VibrateManager.vibrate()
        delegate?.didSelectBookNow(singleScooter: self)
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
    
    @IBAction func ringButtonAction(_ sender: UIButton) {
        
    }
    
    @IBAction func reportIssueButtonAction(_ sender: UIButton) {
        
    }
    
    @IBAction func startRideButtonAction(_ sender: UIButton) {
        VibrateManager.vibrate()
        self.delegate?.didSelectStartRide(singleScooter: self)
        let scooterPlanView = ScooterPlanViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
        scooterPlanView.modalPresentationStyle = .fullScreen
        scooterPlanView.scooterId = scooterResult?.id ?? ""
        scooterPlanView.singleScooterResult = self.singleScooterResult
        present(scooterPlanView, animated: true)
    }
}


extension HomeSingleScooterViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
//        distanceLabel.text = bikeResult?.getDistancePrettyPrinted(userCoordinate: locValue).1
    }
}
