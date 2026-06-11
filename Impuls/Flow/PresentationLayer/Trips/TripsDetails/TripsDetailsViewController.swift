//
//  TripsDetailsViewController.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/15/21.
//

import UIKit

final class TripsDetailsViewController: UIViewController, StoryboardInitializable {

    @IBOutlet weak var debtLabel: UILabel!
    @IBOutlet weak var startTripLocationLabel: UILabel!
    @IBOutlet weak var amountButton: UIButton!
    @IBOutlet weak var endTripLocationLabel: UILabel!
    @IBOutlet weak var startDateMinLabel: UILabel!
    @IBOutlet weak var rideMinutesLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var endDateMinLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var freeMinutesLabel: UILabel!
    @IBOutlet weak var freeTextLabel: UILabel!
    @IBOutlet weak var carbonLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var vehicleTypeImage: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var debtView: UIView!
    
    @IBOutlet weak var progressImage: UIImageView!
    
    @IBOutlet weak var minutesTitleLabel: UILabel!
    @IBOutlet weak var startTitleLabel: UILabel!
    @IBOutlet weak var endTitleLabel: UILabel!
    @IBOutlet weak var distanceTitleLabel: UILabel!
    @IBOutlet weak var caloriesTitleLabel: UILabel!
    @IBOutlet weak var carbonTitleLabel: UILabel!
    @IBOutlet weak var freeMinutesTitleLabel: UILabel!
    @IBOutlet weak var statusTitleLabel: UILabel!
    
    var bikeTripModel: TripBikeDataModel?
    var scooterTripModel: TripScooterDataModel?
    var chargerModel: ChargerRentModel?
    @IBOutlet weak var viewForQR: UIView!
    
    @IBOutlet weak var qrLbl: UILabel!
    var userResult: UserResult?
    var timerManager: TimerManager?

    
//    var sectionName: String? = "March 16 17:51"
    
    let viewModel = HomeViewModel()
    
    var walletNavigationController: UINavigationController?
    var amount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if bikeTripModel != nil {
            vehicleTypeImage.image = UIImage(named: "ic_bicycleTrips")
            viewForQR.isHidden = true
        } else {
            vehicleTypeImage.image = UIImage(named: "ic_scooter")
            if scooterTripModel?.scooterQr == nil {
                viewForQR.isHidden = true
            } else {
                viewForQR.isHidden = false
                qrLbl.text = scooterTripModel?.scooterQr ?? ""
            }
        }
        
        updateUI()
        // Do any additional setup after loading the view.
        // self.title = sectionName
        
        debtLabel.text = "MOBILE_trips_debt_phone".localized().replacingOccurrences(of: "[phone]", with: "")
        amount = Int((bikeTripModel?.payment?.amount ?? scooterTripModel?.payment?.amount ?? chargerModel?.payment.amount) ?? 0)
        amountButton.setTitle(amount.description + " " + "MOBILE_global_total_currency".localized(), for: .normal)
        amountButton.backgroundColor = bikeTripModel?.payment?.status?.backgroundColor ?? scooterTripModel?.payment?.status?.backgroundColor ?? chargerModel?.payment.status?.backgroundColor
        amountButton.setTitleColor(bikeTripModel?.payment?.status?.fillColor ?? scooterTripModel?.payment?.status?.fillColor ?? chargerModel?.payment.status?.fillColor, for: .normal)
        
        if scooterTripModel != nil {
            let disStart = scooterTripModel?.startMileage
            let disEnd = scooterTripModel?.endMileage
            let dis = Int(disEnd!) - Int(disStart!)
            let floatDistance = CGFloat(dis ?? 0)
            self.distanceLabel.text =  String(format: "%.f", ((floatDistance / 1000.0))) + " " + "MOBILE_global_km".localized()
            self.caloriesLabel.text = String(format: "%.f", ((floatDistance / 1000.0) * 21)) + " " + "MOBILE_global_ccal".localized()
            self.carbonLabel.text = String(format: "%.2f", (CGFloat(floatDistance) / 19000)) + " " + "MOBILE_global_carbon".localized()
        } else if bikeTripModel != nil {
            let floatDistance = CGFloat(bikeTripModel?.distance ?? 0)
            self.distanceLabel.text =  String(format: "%.f", ((floatDistance / 1000.0))) + " " + "MOBILE_global_km".localized()
            self.caloriesLabel.text = String(format: "%.f", ((floatDistance / 1000.0) * 21)) + " " + "MOBILE_global_ccal".localized()
            self.carbonLabel.text = String(format: "%.2f", (CGFloat(floatDistance) / 19000)) + " " + "MOBILE_global_carbon".localized()
        } else if chargerModel != nil {
            self.vehicleTypeImage.image = "mimo_charger_station".image
            self.viewForQR.isHidden = true
            
            self.carbonTitleLabel.isHidden = true
            self.carbonLabel.isHidden = true
            
            self.freeMinutesTitleLabel.isHidden = true
            self.freeMinutesLabel.isHidden = true
            
            self.caloriesTitleLabel.isHidden = true
            self.caloriesLabel.isHidden = true
            
            self.statusTitleLabel.isHidden = true
            self.statusLabel.isHidden = true
            
            self.startTripLocationLabel.text = chargerModel?.startStation
            self.endTripLocationLabel.text = chargerModel?.endStation
            
            self.minutesTitleLabel.text = "MOBILE_guest_map_minutes".localized()
            
            let time = fetchChargerTimeComponent()
            
            let hours = "MOBILE_guest_map_hours".localized()
            rideMinutesLabel.text = "MOBILE_trips_minutes".localized().replacingOccurrences(of: "[minutes]", with: "\(time.hour) \(hours) \(time.minute)")

            if time.hour == 0 {
                rideMinutesLabel.text = "MOBILE_trips_minutes".localized().replacingOccurrences(of: "[minutes]", with: "\(time.minute)")
            }
            
            distanceTitleLabel.text = "MOBILE_trips_status".localized()
            
            var status = ""
            var paymentStatus = chargerModel?.payment.status?.userDescirption
            switch paymentStatus {
            case "Payed":
                status = "MOBILE_global_paid".localized()
            case "Waiting":
                status = "MOBILE_global_waiting".localized()
            case "Failed":
                status = "MOBILE_global_failed".localized()
            default:
                status = "MOBILE_global_waiting".localized()
            }
            distanceLabel.text = status
        }
        
        UserManager.share.getUser { [weak self] (result) in
            guard let unwrapSelf = self else { return }
            
            switch result {
            case .success(let user):
                unwrapSelf.userResult = AccountMapper.toUserResult(from: user)
                

            case .failure(let error):
                break
            }
        }
        if let freeBikeMinute = bikeTripModel?.payment?.sources?.first(where: {$0.type == "MINUTES"}) {
            freeMinutesLabel.text = "MOBILE_trips_minutes".localized().replacingOccurrences(of: "[minutes]", with: freeBikeMinute.minutes.description)
        }

        
        if scooterTripModel != nil {
            freeTextLabel.text = "SCOOTER_global_pause".localized()

        } else {
            freeTextLabel.text = "MOBILE_gloobal_free_minutes".localized()
        }
        
        func updateUI() {
            timerManager = TimerManager(timerLabel: freeMinutesLabel, duration: getPausedTime(pauses: scooterTripModel?.pauses), formaterUnits: [.hour, .minute, .second], timerState: .increment)
            timerManager?.timerDurationColor = .mimoBlack
            timerManager?.labelFont = UIFont(name: "Roboto", size: 18)!
            timerManager?.delegate = self
            timerManager?.startTimer()
            timerManager?.stopTimer()
            
            viewForQR.layer.cornerRadius = viewForQR.frame.height / 2
            viewForQR.layer.borderWidth = 1
            viewForQR.layer.borderColor = UIColor.mimoYellow500.cgColor
        }
        
        func getPausedTime(pauses: [Pause]?) -> Double {
            if let pauses = pauses {
                var pausesTimes: Double = 0.0
                for item in pauses {
                    if let start = item.start, let end = item.end {
                        pausesTimes += Double((end - start))
                    }
                }
                print("all pauses time = \(pausesTimes / 1000)")
                return pausesTimes / 1000
            }
            return 0.0
        }

        bikeTripModel?.startPosition?.getLocationName(completed: { [weak self] (text) in
            self?.startTripLocationLabel.text = text
        })
        
        bikeTripModel?.endPosition?.getLocationName(completed: { [weak self] (text) in
            self?.endTripLocationLabel.text = text
        })
        
        scooterTripModel?.startPosition?.getLocationName(completed: { [weak self] (text) in
            self?.startTripLocationLabel.text = text
        })

        scooterTripModel?.endPosition?.getLocationName(completed: { [weak self] (text) in
            self?.endTripLocationLabel.text = text
        })
        
        if chargerModel == nil {
            let time = fetchTimeComponent()
            
            let hours = "MOBILE_guest_map_hours".localized()
            rideMinutesLabel.text = "MOBILE_trips_minutes".localized().replacingOccurrences(of: "[minutes]", with: "\(time.hour) \(hours) \(time.minute)")
            
            if time.hour == 0 {
                rideMinutesLabel.text = "MOBILE_trips_minutes".localized().replacingOccurrences(of: "[minutes]", with: "\(time.minute)")
            }
        }
        
        phoneNumberLabel.text = StorageManager().fetch(key: .phoneNumber, type: String.self) ?? ""

        
        debtView.isHidden = UserManager.share.debtState?.state == .some(.Success)
        var status = ""
        var paymentStatus = bikeTripModel?.payment?.status?.userDescirption ?? scooterTripModel?.payment?.status?.userDescirption
        switch paymentStatus {
        case "Payed":
            status = "MOBILE_global_paid".localized()
        case "Waiting":
            status = "MOBILE_global_waiting".localized()
        case "Failed":
            status = "MOBILE_global_failed".localized()
        default:
            status = "MOBILE_global_waiting".localized()
        }
        statusLabel.text = status
                
        let startDate = Date(timeIntervalSince1970: TimeInterval((bikeTripModel?.start ?? scooterTripModel?.start ?? chargerModel?.start) ?? 0) / 1000)
        let calendar = Calendar.current // or e.g. Calendar(identifier: .persian)
        let starthour = convertToNormalWay(calendar.component(.hour, from: startDate))
        let startminute = convertToNormalWay(calendar.component(.minute, from: startDate))
        let startyear = calendar.component(.year, from: startDate)
        let startmonth = convertToNormalWay(calendar.component(.month, from: startDate))
        let startday = convertToNormalWay(calendar.component(.day, from: startDate))

        

        startDateMinLabel.text = "\(starthour):\(startminute), \(startyear)/\(startmonth)/\(startday)"

        let endDate = Date(timeIntervalSince1970: TimeInterval((bikeTripModel?.end ?? scooterTripModel?.end ?? chargerModel?.end) ?? 0) / 1000)
        let endhour = convertToNormalWay(calendar.component(.hour, from: endDate))
        let endminute = convertToNormalWay(calendar.component(.minute, from: endDate))
        let endyear = calendar.component(.year, from: endDate)
        let endmonth = convertToNormalWay(calendar.component(.month, from: endDate))
        let endday = convertToNormalWay(calendar.component(.day, from: endDate))

        
        endDateMinLabel.text = "\(endhour):\(endminute), \(endyear)/\(endmonth)/\(endday)"
    }
    
    func convertToNormalWay(_ number: Int) -> String {
        if number < 10 {
            return "0" + number.description
        }
        
        return number.description
    }
    
    func getDate(timestamp: Int) -> (hour: Int, minute: Int, second: Int) {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp)) // save date, so all components use the same date
        let calendar = Calendar.current // or e.g. Calendar(identifier: .persian)

        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let second = calendar.component(.second, from: date)
        
        
        return (hour, minute, second)
    }
    
    func fetchTimeComponent() -> (hour: Int, minute: Int) {
        guard let end = bikeTripModel?.end ?? scooterTripModel?.end,
              let start = bikeTripModel?.start ?? scooterTripModel?.start else {
            return (0, 0)
        }
        
        return fetchTime(minutes: (end - start) / (60 * 1000))
    }
    
    func fetchChargerTimeComponent() -> (hour: Int, minute: Int) {
        guard let end = chargerModel?.end,
              let start = chargerModel?.start else {
            return (0, 0)
        }
        
        return fetchTime(minutes: Int((end - start)) / (60 * 1000))
    }
    
    func fetchTime(minutes: Int) -> (hour: Int, minute: Int) {
        let minutesUnwrapped = (minutes >= 0) ? minutes : 0
        
        let hours: Int = Int(minutesUnwrapped / 60)
        let leftedMinutes: Int = Int(minutesUnwrapped) - (hours * 60)
        
        return (hours, leftedMinutes)
    }
    
    @IBAction func payDebtTapped(_ sender: UIButton) {
        guard let unwrapUserResult = userResult else {
            return UIAlertController.showError(message: "Can not show wallet page")
        }
        self.viewModel.getAvatar { [weak self] (avatarUrlStirng) in
            guard let unwrapSelf = self else { return }
            
            let walletVC = WalletViewController.initFromStoryboard(name: Constant.Storyboards.wallet)
            unwrapSelf.walletNavigationController = UINavigationController(rootViewController: walletVC)
            unwrapSelf.walletNavigationController?.navigationBar.barTintColor = .white
            unwrapSelf.walletNavigationController?.navigationBar.backgroundColor = .white

            
            let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_arrow_left"), style: .plain, target: self, action: #selector(unwrapSelf.backButtonTapped))
            walletVC.navigationItem.leftBarButtonItem = backButton
            walletVC.amount = unwrapSelf.amount
            walletVC.user = unwrapUserResult
            unwrapSelf.viewModel.getAvatar { (avatarUrlStirng) in
                walletVC.avataturURLString = avatarUrlStirng
            }
            
            unwrapSelf.present(unwrapSelf.walletNavigationController!, animated: true, completion: nil)
        }
    }
    
    @objc func backButtonTapped() {
        self.walletNavigationController?.dismiss(animated: true, completion: nil)
    }
}

extension TripsDetailsViewController: TimerManagerDelegate {
    func didChanchTimeSeconds(seconds: Double) {
        
    }
    
    func didExpireDuration(timer: TimerManager) {
        
    }
    
}
