//
//  StartTripViewController.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 28.07.22.
//

import UIKit
import CoreLocation

protocol StartTripViewControllerDelegate: AnyObject {
    func didPresPause(scooterStateModel: ScooterStateModel)
    func didSelectSpeedTariff(speedTariff: SpeedTariff, tripId: String)
}

class StartTripViewController: UIViewController, StoryboardInitializable {

    @IBOutlet private weak var batteryImageView: UIImageView!
    @IBOutlet weak var batteryPersentLbl: UILabel!
    @IBOutlet private weak var timeLbl: UILabel!
    @IBOutlet private weak var kmLbl: UILabel!
    @IBOutlet private weak var priceLbl: UILabel!
    @IBOutlet private weak var pauseLbl: UIButton!
    @IBOutlet private weak var endLbl: UIButton!
    @IBOutlet private weak var mapLbl: UIButton!
    @IBOutlet weak var viewForQr: UIView!
    @IBOutlet weak var scooterQrLabel: UILabel!
    @IBOutlet weak var tenSecLabel: UILabel!
    
    @IBOutlet weak var blureViewe: UIView!
    @IBOutlet weak var spedTariffCollectionView: UICollectionView!
    weak var delegate: StartTripViewControllerDelegate?
    
    var startTime: Double = 0.0
    var scooterStateModel: ScooterStateModel? {
        didSet {
            self.setupScanTimer()
            self.setupBattery()
        }
    }
    var currentData: TripScooterSocketDataModel?
    var timerManager: TimerManager?
    var timerManager1:  TimerManager?
    var homeViewModel = HomeViewModel()
    var speedTariffs: [SpeedTariff] = []
    var selectedSpeedTariff: SpeedTariff?
    var speedTariffsId = ""
    let locationManager = CLLocationManager()
    var userLocation: CLLocationCoordinate2D?
    
    var startPrise: Double = 0.0 {
        didSet {
            priceLbl.text = "\(startPrise)֏"
        }
    }
    
    var scooterQr: String = "" {
        didSet {
            scooterQrLabel.text = "\(scooterQr)"
        }
    }
    
    var startDistance: Double = 0.0 {
        didSet {
            kmLbl.text = "\(Double(startDistance / 1000))km"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        setImage()
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        DispatchQueue.global(qos: .default).async { [weak self] in
            if CLLocationManager.locationServicesEnabled() {
                self?.locationManager.delegate = self
                self?.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                self?.locationManager.startUpdatingLocation()
            }
            DispatchQueue.main.sync {
                self?.configureUI()
            }
        }
        tenSecStart()
        self.scooterQrLabel.text = scooterStateModel?.scooter?.qr ?? ""
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if self.speedTariffs.count > 0 {
            spedTariffCollectionView.register(SpeedChargeCollectionViewCell.cellNibName, forCellWithReuseIdentifier: SpeedChargeCollectionViewCell.cellIdentifier)
            spedTariffCollectionView.delegate = self
            spedTariffCollectionView.dataSource = self
        }
    }
    
    private func setupScanTimer() {
        guard let data = scooterStateModel else { return }
        
        DispatchQueue.main.async {
            if let startDate = data.data?.start, ((data.data?.pauses?.filter({ $0.end == nil }).isEmpty ?? false)) {
                let pauses = data.data?.pauses?.filter({ $0.end != nil })
                var pausesSum: Int = 0
                
                pauses?.forEach({ pause in
                    pausesSum += ((pause.end ?? 0) - (pause.start ?? 0))
                })
                
                let currentDate = Date().timeIntervalSince1970
                
                let xxx = (currentDate - Double(startDate/1000)) - Double(pausesSum/1000)
                
                self.setupScanTimer(time: xxx.rounded(), startTimer: true)
            } else if let startDate = data.data?.start {
                let pauses = data.data?.pauses?.filter({ $0.end != nil })
                var pausesSum: Int = 0
                
                pauses?.forEach({ pause in
                    pausesSum += ((pause.end ?? 0) - (pause.start ?? 0))
                })
                
                let currentDate = Double(data.data?.pauses?.first(where: { $0.end == nil })?.start ?? 0)

                let xxx = currentDate/1000 - Double(startDate/1000) - Double(pausesSum/1000)

                self.setupScanTimer(time: xxx.rounded(), startTimer: false)
            }
        }
    }
    
    func getSingleScooterData() {
        homeViewModel.getScooterDetails(id: scooterQr) { result in
            switch result {
            case .success(let data):
                MILoader.hide()
                QRStore.sharedInstance.speedTariffs = data.speedTariffs ?? []
                self.speedTariffs = QRStore.sharedInstance.speedTariffs
                DispatchQueue.main.async {
                    
                    for (index,item) in self.speedTariffs.enumerated() where item.id == self.selectedSpeedTariff?.id {
                        self.speedTariffs[index].isSelected = true
                    }
                    self.spedTariffCollectionView.register(SpeedChargeCollectionViewCell.cellNibName, forCellWithReuseIdentifier: SpeedChargeCollectionViewCell.cellIdentifier)
                    self.spedTariffCollectionView.delegate = self
                    self.spedTariffCollectionView.dataSource = self
                    self.spedTariffCollectionView.reloadData()
                }
                print(data)
            case .failure(let error):
                MILoader.hide()
                switch error {
                case .validatorError(let message):
                    UIAlertController.showError(message: message.localized())
                default:
                    UIAlertController.showError(message: "Server error!")
                }
                print(error)
            }
        }
    }
    
    func tenSecStart()  {
        self.pauseLbl.isEnabled = false
        self.pauseLbl.isUserInteractionEnabled = false
        timerManager1 = TimerManager(timerLabel: tenSecLabel, duration: 11, formaterUnits: [.second], timerState: .decrement)
        timerManager1?.labelFont = UIFont(name: "Roboto-Bold", size: 20)!
        timerManager1?.timerDurationColor = .mimoBlack
        timerManager1?.delegate = self
        timerManager1?.startTimer()
    }
    
    func setImage() {
        switch scooterStateModel?.scooter?.batteryPercent ?? 0 {
        case 0...20:
            self.batteryImageView.image = UIImage(named: "ic_battery_H_0")
        case 21...40:
            self.batteryImageView.image = UIImage(named: "ic_battery_H_25")
        case 41...60:
            self.batteryImageView.image = UIImage(named: "ic_battery_H_50")
        case 61...80:
            self.batteryImageView.image = UIImage(named: "ic_battery_H_75")
        case 81...100:
            self.batteryImageView.image = UIImage(named: "ic_battery_H_100")
        default: break
        }
    }
    
    func configureUI() {
        self.speedTariffs = QRStore.sharedInstance.speedTariffs
        for (i, item) in self.speedTariffs.enumerated() where item.id == self.scooterStateModel?.data?.speedModeTariff?.id {
            self.speedTariffs[i].isSelected = true
            self.selectedSpeedTariff = item
            self.speedTariffsId = item.id ?? ""
        }
//        selectedSpeedTariff = self.speedTariffs.first(where: {$0.id == self.scooterStateModel?.data?.speedModeTariff?.id})
//        selectedTariff?.isSelected = true
        speedTariffsId = selectedSpeedTariff?.id ?? ""
        viewForQr.layer.borderColor = UIColor.mimoYellow500.cgColor
        viewForQr.layer.borderWidth = 2.0
        viewForQr.layer.cornerRadius = viewForQr.frame.height / 2
        pauseLbl.layer.cornerRadius = pauseLbl.frame.height / 2
        endLbl.layer.cornerRadius = endLbl.frame.height / 2
    }
    
    func updateDurationData(force: Bool = false) {
        guard let data = currentData else { return }
        
        DispatchQueue.main.async {
            if let startDate = data.data?.start, ((data.data?.pauses?.filter({ $0.end == nil }).isEmpty ?? false) || force) {
                let pauses = data.data?.pauses?.filter({ $0.end != nil })
                var pausesSum: Int = 0
                
                pauses?.forEach({ pause in
                    pausesSum += ((pause.end ?? 0) - (pause.start ?? 0))
                })
                
                let currentDate = Date().timeIntervalSince1970
                
                let xxx = (currentDate - Double(startDate/1000)) - Double(pausesSum/1000)
                
                self.setupScanTimer(time: xxx.rounded(), startTimer: true)
            } else if let startDate = data.data?.start {
                let pauses = data.data?.pauses?.filter({ $0.end != nil })
                var pausesSum: Int = 0
                
                pauses?.forEach({ pause in
                    pausesSum += ((pause.end ?? 0) - (pause.start ?? 0))
                })
                
                let currentDate = Double(data.data?.pauses?.first(where: { $0.end == nil })?.start ?? 0)

                let xxx = currentDate/1000 - Double(startDate/1000) - Double(pausesSum/1000)
                
                self.setupScanTimer(time: xxx.rounded(), startTimer: false)
            }
        }
    }
    
    func updateUI(data: TripScooterSocketDataModel) {
        self.currentData = data
        updateDurationData()
        
        if data.state ?? "" == "TRIP_STARTED" {
            DispatchQueue.main.async {
                self.scooterQrLabel.text = data.scooter?.qr ?? ""
                if let dist = data.data?.distance {
                    let val: Double = Double(dist / 1000)
                    self.kmLbl.text = "\(val)km"
                    print("kmLbl.text = \(val) km")
                }
                
                if let dist = data.data?.amount {
                    let amount = Double(round(100 * dist) / 100)
                    self.priceLbl.text = "\(amount)֏"
                    print("priceLbl.text = \(amount) ֏")
                }
            }
        }
        
        setupBattery()
    }
    
    private func setupBattery() {
        self.batteryPersentLbl.text = "\(scooterStateModel?.scooter?.batteryPercent ?? 0)%"
        self.setImage()
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
            return pausesTimes
        }
        return 0.0
    }
    
    func setupScanTimer(time: Double, startTimer: Bool = true) {
        timerManager?.stopTimer()
        timerManager = TimerManager(timerLabel: timeLbl, duration: time, formaterUnits: [.hour, .minute, .second], timerState: .increment)
        timerManager?.labelFont = UIFont(name: "Roboto-Bold", size: 18)!
        timerManager?.timerDurationColor = .mimoBlack
        timerManager?.delegate = self
        timerManager?.startTimer()
        if !startTimer {
            timerManager?.stopTimer()
        }
    }
    
    @IBAction private func endRideButtonAction(_ sender: UIButton) {
//        /// For test
//        
//        var redPoint = CLLocationCoordinate2D(latitude: 40.186406, longitude: 44.487524)
//        var greenPoint = CLLocationCoordinate2D(latitude: 40.184523, longitude: 44.503092)
//        var yellowPoint = CLLocationCoordinate2D(latitude: 40.184923, longitude: 44.515350)
//        var outPoint = CLLocationCoordinate2D(latitude: 39.783294, longitude: 44.325328)
//         //real: locationManager.location!.coordinate
//        
//        guard DrawPolygone.shared.isCanFinish(coordinate: locationManager.location!.coordinate) else {
//            print("in location")
//            self.showErrorAlertMessage("SCOOTER_out_of_zone".localized())
//            return
//        }
//        
        let scanVC = ParkingPhotoCameraViewController.initFromStoryboard(name: Constant.Storyboards.parkingPhotoCamera)
        scanVC.view.backgroundColor = .white
        scanVC.tripIdForFinish = self.scooterStateModel?.data?.id ?? ""
//        scanVC.scooterIdForFinish = self.scooterStateModel?.scooter?.qr ?? ""
//        self.homeViewModel.listenScanBikeChange {[weak self] result in
//            guard let unwrapSelf = self else { return }
//            switch result {
//                case .success(let trip):
//                    MILoader.hide()
//
//                    if trip.action == .TripEnded {
//                        unwrapSelf.stopTrip()
//                        unwrapSelf.tripTime = 1
//                        scanVC.dismiss(animated: true, completion: nil)
//                    }
//
//                    if trip.action == .TripNotStarted {
//
//                        UIAlertController.showError(message: "Culd not start the trip.")
//                        scanVC.dismiss(animated: true, completion: nil)
//                    }
//
//                    if trip.action == .None {
//                        unwrapSelf.updateControllerState(state: .smallBottomSheet)
//                        scanVC.dismiss(animated: true, completion: nil)
//                    }
//
//                    if trip.action == .TripStarted {
//                        unwrapSelf.trip = trip
//                        unwrapSelf.updateControllerState(state: .scan(bike: trip))
//                        unwrapSelf.hideAllMarkers()
//                        scanVC.dismiss(animated: true, completion: nil)
//                    }
//
//                case .failure(let error):
//                    UIAlertController.showError(message: error.message.localized())
//            }
//        }
        
        present(UINavigationController(rootViewController: scanVC), animated: true, completion: nil)
    }
    
    @IBAction private func pauseButtonAction(_ sender: UIButton) {
        if let scooterStateModel = self.scooterStateModel {
            delegate?.didPresPause(scooterStateModel: scooterStateModel)
        }
    }

}

extension StartTripViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        userLocation = locValue
    }
}

extension StartTripViewController: TimerManagerDelegate {
    func didChanchTimeSeconds(seconds: Double) {
        if seconds >= 12 || seconds <= 0 {
//            print("pause second = \(seconds)")
            self.tenSecLabel.isHidden = true
            self.tenSecLabel.text = ""
            self.pauseLbl.isEnabled = true
            self.pauseLbl.isUserInteractionEnabled = true
        } else {
            self.tenSecLabel.isHidden = false
            self.tenSecLabel.text = "\(Int(seconds))"
            self.pauseLbl.isEnabled = false
            self.pauseLbl.isUserInteractionEnabled = false
        }
    }
    
    
    func didExpireDuration(timer: TimerManager) {
        
        if timer === timerManager {
//            self.markers.map { $1 }.forEach { $0.map = self.mapView }
//            self.updateControllerState(state: .previewBikes(reloadData: true))
//            self.singleBikeBookNowTapped = false
            self.timerManager?.stopTimer()
//            self.bookedDevice = nil
        }
        
    }
}

extension StartTripViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.speedTariffs.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SpeedChargeCollectionViewCell.cellIdentifier, for: indexPath) as? SpeedChargeCollectionViewCell else { return UICollectionViewCell() }
            cell.setData(speedTariff: self.speedTariffs[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: self.view.frame.width / 3, height: self.spedTariffCollectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedSpeedTariff = speedTariffs[indexPath.row]
        self.speedTariffs.enumerated().forEach({ (index, speedTarif) in
            VibrateManager.vibrate()
            if index == indexPath.row {
                self.speedTariffsId = speedTarif.id ?? ""
                self.speedTariffs[index].isSelected = true
                self.delegate?.didSelectSpeedTariff(speedTariff: self.speedTariffs[index], tripId: self.scooterStateModel?.data?.id ?? "")
            } else {
                self.speedTariffs[index].isSelected = false
            }
        })
        DispatchQueue.main.async {
            self.spedTariffCollectionView.reloadData()
        }
    }
}
