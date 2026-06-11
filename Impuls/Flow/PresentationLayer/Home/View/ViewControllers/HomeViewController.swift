//
//  HomeViewController.swift
//  MimoBike
//
//  Created by Vardan on 03.05.21.
//

import UIKit
import GoogleMaps
import Lottie
import CoreBluetooth
import CoreLocation

enum HomeViewControllerState {
    
    case smallBottomSheet
    case previewBikes(reloadData: Bool)
    case previewScooters(reloadData: Bool)
    case bookedBike
    case bookedScooter
    case accountDone
    case accountNotComplete
    case scan(bike: TripActionModel)
    case scanScooter(scooter: [ScooterStateModel])
    
}

enum MarkerAction {
    case add
    case update
}

struct BookedDeviceModel {
    var startDate: TimeInterval
    var id: String
    var location: CLLocationCoordinate2D
    var bookedId: String? = nil
}

protocol TestDelegate: AnyObject {
    func updateHomeControllerState(scooter: ScooterStateModel)
}

final class HomeViewController: BaseViewController, StoryboardInitializable {
    
    
    //MARK: - Outlets
    
    @IBOutlet weak var zoneInfoBGView: CircleView!
    @IBOutlet weak var zoneInfoButton: UIButton!
    @IBOutlet weak var locationLabel: UILocalizedLabel!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var caloriesLabel: UILabel!
    @IBOutlet weak var carbonLabel: UILabel!
    @IBOutlet weak var stopRideButton: CircleButton!
    @IBOutlet weak var strartBtn: CircleButton!
    @IBOutlet private weak var tripView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet private weak var userImageView: CircleImageView!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet private weak var bikesContentView: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var viewForBlur: UIView!
    @IBOutlet private weak var completeAccountContentView: UIView!
    @IBOutlet private weak var userProfileImageContentView: UIView!
    @IBOutlet private weak var userProfileImageBgView: UIView!
    @IBOutlet private weak var completeYourAccountBGView: UIView!
    @IBOutlet private weak var completeYourAccountLabel: UILabel!
    @IBOutlet private weak var bookedBikeInfoView: UIView!
    @IBOutlet private weak var onMapButton: UIButton!
    @IBOutlet private weak var stopButton: UIButton!
    @IBOutlet private weak var microphoneButton: UIButton!
    @IBOutlet private weak var bookedPriceInfoLabel: UILabel!
    @IBOutlet private weak var bookedBikeTimeLabel: UILabel!
    @IBOutlet private weak var bikesInfoView: UIView!
    @IBOutlet private weak var findBikesBlurView: UIVisualEffectView!
    @IBOutlet private weak var findBikesContentView: UIView!
    @IBOutlet private weak var findBikesTutorialView: CircleView!
    @IBOutlet private weak var timerStackView: UIStackView!
    
    @IBOutlet private weak var bikesBackView: UIView!
    @IBOutlet private weak var currentLocationContentView: UIView!
    @IBOutlet private weak var currentLocationBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bookedBikeQRLabel: UILabel!
    @IBOutlet weak var bookedBikeAddressLabel: UILabel!
    @IBOutlet weak var demoView: UIView!
    @IBOutlet weak var demoTextView: UITextView!
    
    @IBOutlet weak var scooterBookedTimerView: UIView!
    @IBOutlet weak var bookedScooterTimeLbl: UILabel!
    @IBOutlet weak var bookedScooterAddresLbl: UILabel! // name
    @IBOutlet weak var bookedScooterBatteryPersentLbl: UILabel!
    @IBOutlet weak var bookedScooterBatteryIcon: UIImageView!
    
    @IBOutlet weak var bookedScooterAdr: UILabel!
    @IBOutlet weak var bookedScootertripLenghtLbl: UILabel!
    @IBOutlet weak var bookedScooterRingBtn: UIButton!
    @IBOutlet weak var bookedScooterRepoortBtn: UIButton!
    @IBOutlet weak var bookedScooterStardBtn: UIButton!
    @IBOutlet weak var bookedScooterStopBtn: UIButton!
    @IBOutlet weak var viewForQR: UIView!
    @IBOutlet weak var qrLabel: UILabel!
    
    @IBOutlet weak var multyScooterSStackView: UIStackView!
    @IBOutlet weak var scooter1View: UIView!
    @IBOutlet weak var scooter2View: UIView!
    @IBOutlet weak var scooter3View: UIView!
    @IBOutlet weak var addScoterView: UIView!
    @IBOutlet weak var addView: UIView!
    
    @IBOutlet weak var scooter1Title: UILabel!
    @IBOutlet weak var scooter2Title: UILabel!
    @IBOutlet weak var scooter3Title: UILabel!
    
    @IBOutlet weak var scooter1CoontentView: UIView!
    @IBOutlet weak var scooter2CoontentView: UIView!
    @IBOutlet weak var scooter3CoontentView: UIView!
    
    @IBOutlet weak var multyScoooterStackBottom: NSLayoutConstraint!
    //MARK: - Variables
    
    private let homeViewModel = HomeViewModel()
    private let splashViewModel = SplashViewModel()
    private let locationManager = MALocation.current
    private var bottomSheet: SheetViewController?
    private var bikes = [BikeResult]()
    private var scooters = [ScooterResult]()
    var pauseVC: PauseViewController?
    var changeSpeed: ChangeRideRateViewController?
    var isHaveActiveTrip = false
    let blurEffectView = UIVisualEffectView(effect: nil)
    
    var spentDistance = 0.0
    var timerManager: TimerManager?
    var isListeningStateUpdate = false
    var state: HomeViewControllerState = .smallBottomSheet
    var markers: [String: GMSMarker] = [:]
    var selectedIndex: IndexPath?
    var bookedDevice: BookedDeviceModel?
    var bookedScooterDevice: BookedScooterResult?
    var trip: TripActionModel?
    var tripTime: Double = 1
    var tripCenterCalled = false
    var bikeState: BikeState = .bike
    var currentScooterStateModel: ScooterStateModel?
    var currentScooterStateModelList: [ScooterStateModel]?
    var currentScooterTrip: StartTripViewController?
    var scooterTripList: [StartTripViewController]?
    var scoterSoket = ScooterSocketService.shared
    var currectScuterId = ""
    var tripNavigationController: UINavigationController?
    var showDebtVc: ShowDebtViewController?
    var transferViewModel = TransferViewModel()
    var parkers: [ParkingResponse] = []
    
    private var bottomSheetOpened: Bool = false
    private var isAlreadyOpened = false
    private var singleBikeBookNowTapped = false
    private var singleScooterBookNowTapped = false
    private var mapZone: [Zone]?
    var usertDebt: Double = 0.0
    private var speedTariff: SpeedTariff?
    private var tripId: String = ""
    var scooterPlanMode: String = "MIN_By_MIN"
    var isOpenDebtScreen = true
    var zoneInfoHeight: CGFloat = 480
    var parkingMarkers: [GMSMarker] = []
    
    var  zoneVC: AllZoneInfoViewViewController?
    var isZoneInfoOpened: Bool = false
    var currentZoomLevel: Float = 0.0
    
    var parkingInfo: ParkingDetailsViewController?
    
    var previousMarker: GMSMarker? {
        didSet {
            if let state = (UserDefaults.standard.value(forKey: "BikeState") as? String), state == "scooter" {
                previousMarker?.icon = #imageLiteral(resourceName: "ic_scooter_marker")
            } else {
                previousMarker?.icon = #imageLiteral(resourceName: "ic_bike_marker")
            }
        }
    }
    
    var currentMarker: GMSMarker? {
        didSet {
            if let state = (UserDefaults.standard.value(forKey: "BikeState") as? String), state == "scooter" {
                guard scooters.count > 0 else { return }
                switch scooters[self.selectedIndex?.row ?? 0].batteryPercent {
                case 0...20: currentMarker?.icon = #imageLiteral(resourceName: "ic_scooter_batarey_big_0")
                case 21...40: currentMarker?.icon = #imageLiteral(resourceName: "ic_scooter_batarey_big_25")
                case 41...60: currentMarker?.icon = #imageLiteral(resourceName: "ic_scooter_batarey_big_50")
                case 61...80: currentMarker?.icon = #imageLiteral(resourceName: "ic_scooter_batarey_big_75")
                case 81...100: currentMarker?.icon = #imageLiteral(resourceName: "ic_scooter_batarey_big_100")
                default: break
                }
            } else {
                currentMarker?.icon = #imageLiteral(resourceName: "ic_markerSelected")
            }
        }
    }
    
    var scannedBikeMarker: GMSMarker?
    
    var bookedBikeMarker: GMSMarker?
    var bookedScooterMarker: GMSMarker?
    var groupScooterGroupScrollView = UIScrollView()
    
    //MARK: - Life cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        MALocation.startLocationHeading()
        configureUI()
        view.layoutIfNeeded()
        configureMapView()
        registerCell()
        configureDelegates()
        configCollectionView()
        getBikes()
        getScooters()
        getParkings()
        getAvatar()
        handleApplicationStatus()
        getZone()
        getMapZones()
        self.perform(#selector(getNews), with: nil, afterDelay: 3)
        
        NotificationCenter.default.removeObserver(self)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
        /*
        NotificationCenter.default.addObserver(forName: .init(rawValue: "UpdateHomeControllerState"), object: nil, queue: .main) { [weak self] notification in
            print("UpdateHomeControllerState")
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let data = notification.userInfo?["scooter"] as? ScooterStateModel {
                    if data.state == "TRIP_STARTED" || data.state == "TRIP_SCANNED" {
                        self.updateControllerState(state: .scanScooter(scooter: [data]))
                    } else {
                        self.updateControllerState(state: .smallBottomSheet)
                    }
                } else {
                    self.updateControllerState(state: .smallBottomSheet)
                }
            }
        }
        */
        NotificationCenter.default.addObserver(self, selector: #selector(openNotList), name: NSNotification.Name(rawValue: "openNotList"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUI), name: Constant.Notifications.LanguageUpdate, object: nil)
        //        let button = UIButton(type: .roundedRect)
        //              button.frame = CGRect(x: 20, y: 50, width: 100, height: 30)
        //              button.setTitle("Test Crash", for: [])
        //              button.addTarget(self, action: #selector(self.crashButtonTapped(_:)), for: .touchUpInside)
        //              view.addSubview(button)
        viewForBlur.isHidden = true
        completeAccountContentView.isHidden = true
    }
    
    @objc fileprivate func applicationDidBecomeActive() {
        self.initialStartSockeet()
        self.updateRideState()
//        self.pauseVC?.pausStarted =
    }
    
    @objc func initialStartSockeet() {
        scoterSoket.connect { result in
            switch result {
            case .success:
                print("scooter soket connected")
            case .failure(let error):
                print("scoter coket error = \(error)")
            }
        }
        scoterSoket.scooterTrip = { [weak self] data in
            print(data)
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.currentScooterTrip?.view.backgroundColor = .white
                self.scooterPlanMode = data.data?.billingModeTariff?.mode ?? ""
                if let scooter = data.scooter {
                    self.updateMarker(model: scooter)
                }
//                self.currentScooterTrip = self.scooterTripList?.first(where: { ($0.scooterStateModel?.scooter?.qr ?? "") == (data.scooter?.qr ?? "") })
//                self.currentScooterTrip?.updateUI(data: data)
                
                self.scooterTripList?.first(where: { ($0.scooterStateModel?.scooter?.qr ?? "") == (data.scooter?.qr ?? "") })?.updateUI(data: data)
            }
        }
        
        self.currentScooterTrip?.updateDurationData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        homeViewModel.getAppVersion { result in
//            guard let self = self else { return }
            switch result {
            case .success(let storVersion):
                if let info = Bundle.main.infoDictionary,
                   let currentVersion = info["CFBundleShortVersionString"] as? String,
                   let identifier = info["CFBundleIdentifier"] as? String,
                   let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(identifier)") {
                    print("currentVersion = \(currentVersion)")
                    print("storVersion = \(storVersion.version ?? "")")
                    if storVersion.version ?? "" > currentVersion { //TODO: Need to be >
                        DispatchQueue.main.async {
                            let  vc = ForceUpdateViewController.initFromStoryboard(name: "ScooterPlan")
                            vc.modalPresentationStyle = .fullScreen
                            let navigationController = UINavigationController(rootViewController: vc)

                            UIApplication.shared.windows.first?.rootViewController = navigationController
                            UIApplication.shared.windows.first?.makeKeyAndVisible()
                        }
                    }
                } else {
                    print("invalid app current version")
                }

            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        
        
        //        _ = try? isUpdateAvailable { (update, error) in
        //            if let error = error {
        //                print(error)
        //            } else if let update = update {
        //                print(update)
        //                if update {
        //                    DispatchQueue.main.async {
        //                        let  vc = ForceUpdateViewController.initFromStoryboard(name: "ScooterPlan")
        //                        vc.modalPresentationStyle = .fullScreen
        //                        let navigationController = UINavigationController(rootViewController: vc)
        //
        //                        UIApplication.shared.windows.first?.rootViewController = navigationController
        //                        UIApplication.shared.windows.first?.makeKeyAndVisible()
        //                    }
        //                }
        //            }
        //        }
        
        
        if UserDefaults.standard.bool(forKey: "isopenNotList") {
            self.openNotList()
            UserDefaults.standard.set(false, forKey: "isopenNotList")
        }
        
        splashViewModel.getFinansialState { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let state):
                DispatchQueue.main.async {
                    if state.state != UserManager.share.debtState?.state {
                        UserManager.share.debtState = state
                        NotificationCenter.default.post(name: Constant.Notifications.updateFinansialState, object: nil)
                    } else if state.state == FinancialState.Debt || state.state == FinancialState.DebtOnDevice {
                        if !UserManager.share.isOpenDebtScreen { return }
                        self.showDebtVc = ShowDebtViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
                        self.showDebtVc?.modalPresentationStyle = .fullScreen
                        self.showDebtVc?.view.backgroundColor = .white
                        self.showDebtVc?.updateUI(amount: state.additional ?? 0.0, wallets: state.wallets ?? [])
                        self.showDebtVc?.delegate = self
                        self.usertDebt = state.additional ?? 0.0
                        self.present(self.showDebtVc!, animated: true)
                    }
                }
            case .failure(let error):
                UIAlertController.showError(message: error.message.localized())
            }
        }
        initialStartSockeet()
        updateUI()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.getScooterState()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        mapView.clear()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("===== viewDidDisappear =====")
//        self.mapView.clear()
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
//        mapView.clear()
    }
    
    @objc func openNotList() {
        let notListVC = NotificationListViewController.initFromStoryboard(name: Constant.Storyboards.home)
        let navVC = UINavigationController(rootViewController: notListVC)
        navVC.modalPresentationStyle = .pageSheet
        self.present(navVC, animated: true)
    }
    
    @objc func updateUI() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.setDemoText()
        })
        locationLabel.text = "MOBILE_global_location".localized()
        let freeBooking = "MOBILE_book_free_booking".localized().lowercased()
        bookedPriceInfoLabel.colorString(text: bookedPriceInfoLabel.text, coloredText: [freeBooking], color: .mimoBlackWith05alpha, font: UIFont(name: "Roboto-Regular", size: 15)!)
    }
    
    func setDemoText() {
        let attributedString = NSMutableAttributedString(string: "MOBILE_demo_info".localized())
        attributedString.addAttribute(.link, value: "tg://resolve?domain=MimoReview", range: NSRange(location: attributedString.length - 13, length: 13))
        attributedString.addAttributes([.font : UIFont(name: "Roboto", size: 15)], range: NSRange(location:  0, length: attributedString.length))
        demoTextView.attributedText = attributedString
    }
    
    @IBAction func crashButtonTapped(_ sender: AnyObject) {
        let numbers = [0]
        let _ = numbers[1]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if case .accountNotComplete = state {
            updateControllerState(state: .smallBottomSheet)
        } else {
            updateControllerState(state: state)
        }

        if let currentLocation = locationManager.currentLocation {
            let camera = GMSCameraPosition(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude, zoom: 15)
            mapView.camera = camera
        }
        if bookedDevice != nil, let lat = bookedDevice?.location.latitude, let long = bookedDevice?.location.longitude {
            if bikeState == .bike {
                addBookedBikeMarker(in: CLLocationCoordinate2D(latitude: lat, longitude: long))
                updateControllerState(state: .bookedBike)
            } else {
                addBookedScooterMarker(in: CLLocationCoordinate2D(latitude: lat, longitude: long))
                updateControllerState(state: .bookedScooter)
            }
        }
        if trip != nil {
            setupScanTimer(time: tripTime)
            //addScannedBikeIntoCurrentLocation()
            updateControllerState(state: .scan(bike: trip!))
        }

        if currentScooterStateModelList != nil {
            updateControllerState(state: .scanScooter(scooter: currentScooterStateModelList ?? []))
        }
    }
    
    func handleApplicationStatus() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateRideState), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateUserPicture), name: Constant.Notifications.updateUserPicture, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateBlureVieew), name: Constant.Notifications.updateBlureState, object: nil)
    }
    
    @objc func updateBlureVieew() {
        if !UserDefaults.standard.bool(forKey: "isAlreadyOpen") {
            print("====== 4")
            UserDefaults.standard.setValue(true, forKey: "isAlreadyOpen")
            self.splashViewModel.getFinansialState(completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let state):
                    UserManager.share.debtState = state
                    UserManager.share.debtAmount = state.additional
                    UserManager.share.debtWallets = state.wallets
                    if state.state == .ProfileIncomplete {
                        DispatchQueue.main.async {
                            self.updateControllerState(state: .accountNotComplete)
                        }
                    }
                    NotificationCenter.default.post(name: Constant.Notifications.updateFinansialState, object: nil)
                case .failure(let error):
                    UIAlertController.showError(message: error.message.localized() )
                }
            })
            
            self.showBikeHint()
        }
        
    }
    
    @objc func updateUserPicture() {
        guard let avId = UserDefaults.standard.value(forKey: "avatarId") as? String else {
            return
        }
        print("new img url = \(avId)")
        let node = "dev-repository"
        guard let token = KeychainManager().getAccessToken()  else { return  }
        var avatar = "https://\(node).impulsepower.ru/files?id=\(avId)&token=\(token)"
        print("avatar url = \(avatar)")
        if let ur = URL(string: avatar) {
            self.userImageView.setImage(avatar, defaultImage: #imageLiteral(resourceName: "ic_default_avatar"))
        }
        
        //self.getAvatar()
    }
    
    @objc func updateRideState() {
        
        splashViewModel.getState {[weak self] model in
            guard let self = self else { return }
            UserDefaults.standard.set(false, forKey: "isHaveActiveTrip")
            switch model {
            case .success(let tripModel):
                switch tripModel.action {
                case .TripStarted:
                    guard let bike = tripModel.bikeDto, let id = bike.id, let mac = bike.mac else { return }
                    UserDefaults.standard.set(true, forKey: "isHaveActiveTrip")
                    self.isListeningStateUpdate = false
                    self.listenStateUpdate()
                    self.updateControllerState(state: .scan(bike: tripModel))
                    self.dismiss(animated: true)
                    UserManager.share.isHaveBikeTrip = true
                case .TripEnded:
                    self.stopTrip()
                    UserManager.share.isHaveBikeTrip = false
                case .Booking_Started:
                    guard let bike = tripModel.bikeDto, let id = bike.id, let data = tripModel.data?.start, let lat = bike.latitude, let long = bike.longitude else { return }
                    var stringDate = String(data)
                    stringDate.removeLast(3)
                    let dataStarted = 300 - abs(Date().timeIntervalSince1970 - Double(Int(stringDate) ?? 0))
                    self.stateBookedBike(bikeID: id, reminedTime: dataStarted, location: CLLocationCoordinate2D(latitude: lat, longitude: long))
                    self.setupBookTimer(time: dataStarted)
                    self.bookedBikeQRLabel.text = tripModel.bikeDto?.qr ?? ""
                    
//                    BikeResult.getLocationName(location: CLLocationCoordinate2D(latitude: lat, longitude: long), long: false, completed: {[weak self] value in
//                        self?.bookedBikeAddressLabel.text = value
//                    })
                    self.updateControllerState(state: .bookedBike)
                    self.removeBookedBikeMarker()
                    self.addBookedBikeMarker(in: CLLocationCoordinate2D(latitude: lat, longitude: long))
                case .BookingEnded:
                    self.removeBookedBikeMarker()
                    if case .bookedBike = self.state {
                        self.updateControllerState(state: .smallBottomSheet)
                    }
                case .None:
                    UserManager.share.isHaveBikeTrip = false
                    if case .bookedBike = self.state {
                        self.updateControllerState(state: .smallBottomSheet)
                    }
                    self.splashViewModel.getFinansialState(completion: { [weak self] result in
                        guard let self = self else { return }
                        switch result {
                        case .success(let state):
                            UserManager.share.debtState = state
                            UserManager.share.debtAmount = state.additional
                            if state.state == .ProfileIncomplete {
                                DispatchQueue.main.async {
                                    self.updateControllerState(state: .accountNotComplete)
                                }
                            }
                        case .failure(let error):
                            UIAlertController.showError(message: error.message.localized() ?? "")
                        }
                    })
                case .TripScanned:
                    guard let bike = tripModel.bikeDto, let id = bike.id, let mac = bike.mac else { return }
                    UserDefaults.standard.set(true, forKey: "isHaveActiveTrip")
                    self.isListeningStateUpdate = false
                    self.listenStateUpdate()
                    print("tripModel = \(tripModel)")
                    self.updateControllerState(state: .scan(bike: tripModel))
                    self.dismiss(animated: true)
                    
                    UserManager.share.isHaveBikeTrip = true
                default:
                    break
                }
            case .failure(let error):
                print("error = \(error)")
                //                    UIAlertController.showError(message: error.localizedDescription)
            }
        }
    }
    
    func getScooterState() {
        self.splashViewModel.getScooterState(completion: { [weak self] (result) in
            guard let self = self else { return }
            
            switch result {
            case .success(let model):
                print("Scooter GetState = \(model)")
                self.isHaveActiveTrip = model.count > 0 ? true : false
                self.checkState(model: model)
            case .failure(let error):
                print("Scooter GetState Failedd = \(error)")
                UIAlertController.showError(message: error.message.localized())
            }
        })
    }
    
    func checkState(model: [ScooterStateModel]) {
        var booking_Started_List: [ScooterStateModel] = []
        var booking_Ended_List: [ScooterStateModel] = []
        var trip_Started_List: [ScooterStateModel] = []
        var trip_Ended_List: [ScooterStateModel] = []
        var trip_Paused_List: [ScooterStateModel] = []
        
        for scooterModel in model {
            switch scooterModel.state {
            case .TripStarted:
                trip_Started_List.append(scooterModel)
            case .TripEnded:
                trip_Ended_List.append(scooterModel)
            case .Booking_Started:
                booking_Started_List.append(scooterModel)
            case .BookingEnded:
                booking_Ended_List.append(scooterModel)
            case .TripPaused:
                trip_Paused_List.append(scooterModel)
            default:
                print("Unsupported Trip")
            }
        }
        
        if trip_Started_List.count == 0 {
            self.splashViewModel.getFinansialState(completion: { result in
                switch result {
                case .success(let state):
                    UserManager.share.debtState = state
                    UserManager.share.debtAmount = state.additional
                case .failure(let error):
                    UIAlertController.showError(message: error.message.localized())
                }
            })
            
            switch state {
            case .scan:
                break
            default:
                self.updateControllerState(state: .accountDone)
            }
        } else {
            if let data = trip_Started_List.first?.data?.start {
                var stringDate = String(data)
                stringDate.removeLast(3)
                let dd = Int(data / 1000)
                let dataStarted = abs(Date().timeIntervalSince1970 - Double(dd))
                
                // TODO: change for scooter
                self.stateScanScooter(trips: trip_Started_List, time: dataStarted)
            }
        }
        
        if booking_Started_List.count > 0 {
            if let bookID = booking_Started_List.first?.scooter?.id,
               let latitude = booking_Started_List.first?.scooter?.located?.latitude,
               let longitude = booking_Started_List.first?.scooter?.located?.longitude,
               let data = booking_Started_List.first?.data?.start {
                
                let dataStarted = 300 - abs(Date().timeIntervalSince1970 - Double(Int(data) ?? 0) / 1000)
                // TODO: change for scooter
                self.view.backgroundColor = .white
                self.tripTime = dataStarted
                self.updateControllerState(state: .bookedScooter)
                self.stateBookedBike(bikeID: bookID, reminedTime: dataStarted, location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
        }
        
        if trip_Paused_List.count >  0 {
            
            if let data = trip_Paused_List.first?.data?.start {
                var stringDate = String(data)
                stringDate.removeLast(3)
                let dd = Int(data)
                let dataStarted = abs((Date().timeIntervalSince1970 - Double(dd)) / 1000)
                // TODO: change for scooter
                self.view.backgroundColor = .white
                //TODO: need to chenge time coounting
                self.stateScanScooter(trips: trip_Paused_List, time: dataStarted + self.getPausedTime(pauses: trip_Paused_List.first?.data?.pauses))
            }
        }
        
        // self.playLogoAnimationOnce();
    }
    
    func getPausedTime(pauses: [Pause]?) -> Double {
        if let pauses = pauses {
            var pausesTimes: Double = 0.0
            for item in pauses {
                if let start = item.start, let end = item.end {
                    pausesTimes += Double((end - start))
                }
            }
            print("all pauses time = \(pausesTimes)")
            return pausesTimes
        }
        return 0.0
    }
    
    @objc func didEnterBackground(_ notification: Notification) {
        self.isListeningStateUpdate = false
    }
    
    //MARK: - Methods
    
    func hideAllMarkers() {
        for marker in self.markers.values {
            marker.map = nil
        }
    }
    
    /// configure user interface
    private func configureUI() {
        multyScooterSStackView.isHidden = true
        groupScooterGroupScrollView.frame = CGRect(x: 0, y: view.frame.height - 293, width: view.frame.width, height: 303)
        groupScooterGroupScrollView.alwaysBounceVertical = false
        groupScooterGroupScrollView.alwaysBounceHorizontal = true
        self.view.addSubview(groupScooterGroupScrollView)
        groupScooterGroupScrollView.backgroundColor = .white
        groupScooterGroupScrollView.delegate = self
        groupScooterGroupScrollView.isHidden = true
        groupScooterGroupScrollView.tag = 999
        groupScooterGroupScrollView.isPagingEnabled = true
        zoneInfoBGView.layer.cornerRadius = zoneInfoButton.frame.height / 2
        zoneInfoBGView.layer.borderColor = UIColor.white.cgColor
        zoneInfoBGView.layer.borderWidth = 2
        pauseVC = PauseViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
        pauseVC?.delegate = self
        changeSpeed = ChangeRideRateViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
        changeSpeed?.delegate = self
       
        let attributedString = NSMutableAttributedString(string: "MOBILE_demo_info".localized())
        attributedString.addAttribute(.link, value: "tg://resolve?domain=MimoReview", range: NSRange(location: attributedString.length - 13, length: 13))
        attributedString.addAttributes([.font : UIFont(name: "Roboto", size: 15)], range: NSRange(location:  0, length: attributedString.length))
        demoTextView.attributedText = attributedString
        //demoTextView.delegate = self
        
        locationLabel.text = "MOBILE_global_location".localized()
        
        setupBookTimer(time: bookedDevice?.startDate ?? 300)
        setupScooterTimer(time: tripTime, view: bookedBikeTimeLabel)
        
        completeYourAccountBGView.addShadow(color: .mimoBlackWith025alpha)
        bikesContentView.isHidden = true
        bikesBackView.addShadow(color: .mimoBlackWith025alpha)
        currentLocationContentView.addShadow(color: .mimoBlackWith025alpha)
        currentLocationBottomConstraint.constant = Constant.Constraint.constant184
        completeYourAccountLabel.colorString(text: completeYourAccountLabel.text, coloredText: ["Let's complete your account!"], color: .mimoBlackWith05alpha, font: UIFont(name: "Roboto-Bold", size: 15)!)
        
        let freeBooking = "MOBILE_book_free_booking".localized().lowercased()
        bookedPriceInfoLabel.colorString(text: bookedPriceInfoLabel.text, coloredText: [freeBooking], color: .mimoBlackWith05alpha, font: UIFont(name: "Roboto-Regular", size: 15)!)
        bookedBikeInfoView.addShadow(color: .mimoBlackWith025alpha)
        addBlurEffect()
        completeYourAccountBGView.layer.cornerRadius = Constant.CornerRadius.cornerRadius8
        completeYourAccountLabel.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
        onMapButton.layer.borderWidth = 1
        onMapButton.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
        microphoneButton.layer.borderWidth = 1
        microphoneButton.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
        findBikesContentView.layer.cornerRadius = Constant.CornerRadius.cornerRadius8
        findBikesTutorialView.layer.borderWidth = 1
        findBikesTutorialView.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
        bookedBikeInfoView.layer.cornerRadius = Constant.CornerRadius.cornerRadius12
        fillCalories(distance: 0)
        
        scooterBookedTimerView.addShadow(color: .mimoBlackWith025alpha)
        scooterBookedTimerView.layer.cornerRadius = Constant.CornerRadius.cornerRadius12
        bookedScooterRingBtn.layer.cornerRadius = bookedScooterRingBtn.frame.height / 2
        bookedScooterRepoortBtn.layer.cornerRadius = bookedScooterRepoortBtn.frame.height / 2
        bookedScooterStopBtn.layer.cornerRadius = bookedScooterStopBtn.frame.height / 2
        bookedScooterStopBtn.layer.borderWidth = 1.0
        bookedScooterStopBtn.layer.borderColor = UIColor.mimoBlack.cgColor
        bookedScooterStardBtn.layer.cornerRadius = bookedScooterStardBtn.frame.height / 2
        viewForQR.layer.borderColor = UIColor.mimoYellow500.cgColor
        viewForQR.layer.borderWidth = 2.0
        viewForQR.layer.cornerRadius = viewForQR.frame.height / 2
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false
    }
    
    private func fillCalories(distance: Int) {
        
        let floatDistance = CGFloat(distance)
        self.distanceLabel.text =  String(format: "%.f", ((floatDistance / 1000.0))) + " " + "MOBILE_global_km".localized()
        self.caloriesLabel.text = String(format: "%.f", ((floatDistance / 1000.0) * 21)) + " " + "MOBILE_global_ccal".localized()
        self.carbonLabel.text = String(format: "%.2f", (CGFloat(floatDistance) / 19000))// + " " + "MOBILE_global_carbon".localized()
    }
    
    func setupBookTimer(time: Double) {
        timerManager?.stopTimer()
        timerManager = TimerManager(timerLabel: bookedBikeTimeLabel, duration: time, formaterUnits: [.minute, .second], timerState: .decrement)
        timerManager?.labelFont = UIFont(name: "Roboto-Bold", size: 32)!
        timerManager?.timerDurationColor = .mimoBlack
        timerManager?.delegate = self
    }
    
    func openWalletVC() {
        var walletNavigationController: UINavigationController?
        let walletVC = WalletViewController.initFromStoryboard(name: Constant.Storyboards.wallet)
        walletNavigationController = UINavigationController(rootViewController: walletVC)
        walletNavigationController?.navigationBar.barTintColor = .white
        walletNavigationController?.navigationBar.backgroundColor = .white
        self.present(walletNavigationController!, animated: true, completion: nil)
    }
    
    func setupScooterTimer(time: Double, view: UILabel) {
        
        timerManager?.stopTimer()
        timerManager = TimerManager(timerLabel: view, duration: time == 1 ?  300 : time, formaterUnits: [.minute, .second], timerState: .decrement)
        timerManager?.labelFont = UIFont(name: "Roboto-Bold", size: 32)!
        timerManager?.timerDurationColor = .mimoBlack
        timerManager?.delegate = self
        timerManager?.startTimer()
    }
    
    func setupScanTimer(time: Double) {
        timerManager?.stopTimer()
        timerManager = TimerManager(timerLabel: timerLabel, duration: time, formaterUnits: [.hour, .minute, .second], timerState: .increment)
        timerManager?.labelFont = UIFont(name: "Roboto-Bold", size: 32)!
        timerManager?.timerDurationColor = .mimoBlack
        timerManager?.delegate = self
    }
    
    func addBookedBikeMarker(in location: CLLocationCoordinate2D) {
        self.bookedBikeMarker?.map = nil
        self.bookedBikeMarker = nil
        self.bookedBikeMarker?.isTappable = false
        let marker = GMSMarker()
        marker.map = mapView
        marker.position = location
        marker.icon = UIImage(named: "ic_markerSelected")
        self.bookedBikeMarker = marker
    }
    
    func addBookedScooterMarker(in location: CLLocationCoordinate2D) {
        self.bookedScooterMarker?.map = nil
        self.bookedScooterMarker = nil
        self.bookedScooterMarker?.isTappable = false
        let marker = GMSMarker()
        marker.map = mapView
        marker.position = location
        guard scooters.count > 0 else { return }
        switch scooters[self.selectedIndex?.row ?? 0].batteryPercent {
        case 0...20: marker.icon = #imageLiteral(resourceName: "ic_scooter_batarey_big_0")
        case 21...40: marker.icon = #imageLiteral(resourceName: "ic_scooter_batarey_big_25")
        case 41...60: marker.icon = #imageLiteral(resourceName: "ic_scooter_batarey_big_50")
        case 61...80: marker.icon = #imageLiteral(resourceName: "ic_scooter_batarey_big_75")
        case 81...100: marker.icon = #imageLiteral(resourceName: "ic_scooter_batarey_big_100")
        default: break
        }
        self.bookedScooterMarker = marker
    }
    
    func removeBookedBikeMarker() {
        self.bookedBikeMarker?.map = nil
        self.bookedBikeMarker = nil
    }
    
    func removeBookedScooterMarker() {
        self.bookedScooterMarker?.map = nil
        self.bookedScooterMarker = nil
    }
    
    func addScannedBikeIntoCurrentLocation(coordinate: CLLocationCoordinate2D, for scooter: Scooter? = nil) {
//        self.scannedBikeMarker?.map = nil
//        self.scannedBikeMarker = nil
        self.scannedBikeMarker?.isTappable = false
        let marker = GMSMarker()
        
        marker.position = coordinate
        
        marker.map = mapView
        if let scooter = scooter {
            marker.icon = getSelectedScooterIcon(for: scooter.batteryPercent ?? 0)
        } else {
            marker.icon = UIImage(named: "ic_markerSelected")
        }
        self.scannedBikeMarker = marker
        
        
        let location = CLLocation(latitude: self.scannedBikeMarker!.position.latitude, longitude: self.scannedBikeMarker!.position.longitude)
    }
    
    //    func addScannedScooterIntoCurrentLocation(coordinate: CLLocationCoordinate2D, for scooter: Scooter) {
    //        guard scooters.count > 0 else { return }
    //        self.scannedScooterMarker?.map = nil
    //        self.scannedScooterMarker = nil
    //        self.scannedScooterMarker?.isTappable = false
    //        let marker = GMSMarker()
    //
    //        marker.position = coordinate
    //
    //        marker.map = mapView
    //        marker.icon = getSelectedScooterIcon(for: scooter.batteryPercent ?? 0)
    //
    //        self.scannedScooterMarker = marker
    //    }
    //
    private func getSelectedScooterIcon(for batteryPercent: Int) -> UIImage {
        switch batteryPercent {
        case 0...20: return #imageLiteral(resourceName: "ic_scooter_batarey_big_0")
        case 21...40: return #imageLiteral(resourceName: "ic_scooter_batarey_big_25")
        case 41...60: return #imageLiteral(resourceName: "ic_scooter_batarey_big_50")
        case 61...80: return #imageLiteral(resourceName: "ic_scooter_batarey_big_75")
        case 81...100: return #imageLiteral(resourceName: "ic_scooter_batarey_big_100")
        default: break
        }
        return UIImage()
    }
    
    func removeScannedBike() {
        
        self.scannedBikeMarker?.map = nil
        self.scannedBikeMarker = nil
    }
    
    /// configure map view
    private func configureMapView() {
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        
        //        do {
        //              // Set the map style by passing the URL of the local file.
        //              if let styleURL = Bundle.main.url(forResource: "MapStyle", withExtension: "json") {
        //                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
        //              } else {
        //                NSLog("Unable to find style.json")
        //              }
        //            } catch {
        //              NSLog("One or more of the map styles failed to load. \(error)")
        //            }
        
    }
    
    /// configure user interface
    private func configCollectionView() {
        let floawLayout = UPCarouselFlowLayout()
        floawLayout.itemSize = CGSize(width: Constant.Width.width288, height: Constant.Height.height184)
        floawLayout.scrollDirection = .horizontal
        floawLayout.sideItemScale = 1
        floawLayout.sideItemAlpha = 0.7
        floawLayout.spacingMode = .fixed(spacing: 10.0)
        collectionView.collectionViewLayout = floawLayout
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    /// configure Delegates
    private func configureDelegates() {
        collectionView.delegate = self
        collectionView.dataSource = self
        BLEManager.shareInstance.delegate = self
    }
    
    /// register collectionView cell
    private func registerCell() {
        collectionView.register(UINib(nibName: HomeBikeCollectionViewCell.reuseIdentifier(), bundle: nil), forCellWithReuseIdentifier: HomeBikeCollectionViewCell.reuseIdentifier())
        collectionView.register(UINib(nibName: HomeScooterCollectionViewCell.reuseIdentifier(), bundle: nil), forCellWithReuseIdentifier: HomeScooterCollectionViewCell.reuseIdentifier())
    }
    
    @IBAction func startRiddeBtnAction(_ sender: CircleButton) {
        guard let bookedBikeID = bookedDevice?.id else {
            return
        }
        homeViewModel.cancelBikeBook(bikeID: bookedBikeID) {[weak self] result in
            guard let self = self else { return }
            if case .failure(let message) = result {
                UIAlertController.showError(message: message.localizedDescription)
            } else {
                self.removeBookedBikeMarker()
                self.markers.map { $1 }.forEach { $0.map = self.mapView }
                self.updateControllerState(state: .previewBikes(reloadData: true))
                self.singleBikeBookNowTapped = false
                self.timerManager?.stopTimer()
                self.bookedDevice = nil
                self.presentScanVC()
            }
        }
    }
    
    func getMapZones() {
        homeViewModel.getMapZones { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let zones):
                self.mapZone = zones
                print(zones)
                self.drawMapZones()
            case .failure(let error):
                print(error)
                
            }
        }
    }
    
    func drawMapZones() {
        DispatchQueue.main.async {
            if let state = (UserDefaults.standard.value(forKey: "BikeState") as? String), state == "scooter" {
                DrawPolygone.shared.drawZone(mapZone: self.mapZone ?? [], mapView: self.mapView)
            }
        }
    }
    
    /// Get avatar url and set image
    private func getAvatar() {
        
        UserManager.share.getUser { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let userResult):
                self.userImageView.setImage(userResult.avatar?.getURL()?.absoluteString, defaultImage: #imageLiteral(resourceName: "ic_default_avatar"))
            case .failure(let error):
                print(error)
                MILoader.hide()
//                UIAlertController.showError(message: error.localizedDescription)
            }
        }
        
        UserManager.share.getAccount { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let userResult):
                self.spentDistance = userResult.distance ?? 0.0
                self.fillCalories(distance: Int(self.spentDistance))
            case .failure(let error):
                print(error)
                MILoader.hide()
//                UIAlertController.showError(message: error.localizedDescription)
            }
        }
        
        //        homeViewModel.getAvatar { [weak self] avatarUrlString in
        //            guard let self = self else { return }
        //            self.userImageView.setImage(avatarUrlString, defaultImage: #imageLiteral(resourceName: "ic_user_profile"))
        //        }
    }
    
    func updateControllerState(state: HomeViewControllerState) {
        self.state = state
        switch state {
        case .smallBottomSheet:
            isHaveActiveTrip = false
            stopRideButton.isHidden = UserManager.share.isHaveBikeTrip ? false : true
            tripView.isHidden = UserManager.share.isHaveBikeTrip ? false : true
            demoView.isHidden = !UserManager.share.isHaveBikeTrip ? false : true
            openBottomSheet()
            bikesInfoView.isHidden = true
            scooterBookedTimerView.isHidden = true
            timerStackView.isHidden = true
            completeAccountContentView?.isHidden = false
            bikesContentView.isHidden = true
            findBikesBlurView.isHidden = true
//            scooterTrip?.dismiss(animated: true)
//            scooterTrip?.view.isHidden = true
//            scooterTrip?.view.removeFromSuperview()
//            scooterTrip?.view.isHidden = true
//            scooterTrip = nil
            currentLocationBottomConstraint.constant = Constant.Constraint.constant184
            timerManager?.stopTimer()
        case .bookedBike:
            bikeState = .bike
            stopRideButton.isHidden = true
            tripView.isHidden = true
            demoView.isHidden = false
            completeAccountContentView?.isHidden = false
            currentLocationBottomConstraint.constant = Constant.Constraint.constant184
            timerManager?.startTimer()
            bikesInfoView.isHidden = false
            scooterBookedTimerView.isHidden = true
            timerStackView.isHidden = false
            bikesContentView.isHidden = true
            currentLocationContentView.isHidden = true
            findBikesBlurView.isHidden = true
            bottomSheet?.attemptDismiss(animated: true)
            bottomSheetOpened = false
        case .bookedScooter:
            bikeState = .scooter
            stopRideButton.isHidden = true
            tripView.isHidden = true
            demoView.isHidden = true
            completeAccountContentView?.isHidden = true
            currentLocationBottomConstraint.constant = Constant.Constraint.constant184
            setupScooterTimer(time: tripTime, view: bookedScooterTimeLbl)
            if  let tm = timerManager?.duration,  tm >= 299 {
                timerManager?.startTimer()
            }
            bikesInfoView.isHidden = true
            scooterBookedTimerView.isHidden = false
            timerStackView.isHidden = true
            bikesContentView.isHidden = true
            currentLocationContentView.isHidden = true
            findBikesBlurView.isHidden = true
            bottomSheet?.attemptDismiss(animated: true)
            bottomSheetOpened = false
            //                previewScooter(result: self.scooters[selectedIndex?.row ?? 0])
        case .previewBikes(let reloadState):
            if self.bikeState == .scooter { return }
            timerManager?.stopTimer()
            currentLocationBottomConstraint.constant = Constant.Constraint.constant224
            stopRideButton.isHidden = true
            tripView.isHidden = true
            demoView.isHidden = false
            singleBikeBookNowTapped = false
            bikesInfoView.isHidden = true
            scooterBookedTimerView.isHidden = true
            timerStackView.isHidden = true
            findBikesBlurView.isHidden = true
            currentLocationContentView.isHidden = false
            bikesContentView.isHidden = false
            currentLocationBottomConstraint.constant = Constant.Constraint.constant224
            bottomSheetOpened = false
            
            if reloadState {
                collectionView.reloadData()
                if let selectedIndex = selectedIndex, let currentMarker = currentMarker {
                    guard let cell = self.collectionView.cellForItem(at: selectedIndex) else { return }
                    self.makeSelectedMarker(previousMarker: nil, currentMarker: currentMarker, index: IndexPath(item: 0, section: 0), cell: cell as? HomeBikeCollectionViewCell)
                } else {
                    guard let firstItem = bikes.first else { return }
                    let cell = self.collectionView(collectionView, cellForItemAt: IndexPath(item: 0, section: 0))
                    guard let currentMarker = self.markers[firstItem.id] else { return }
                    self.makeSelectedMarker(previousMarker: nil, currentMarker: currentMarker, index: IndexPath(item: 0, section: 0), cell: cell as? HomeBikeCollectionViewCell)
                }
            }
        case .previewScooters(let reloadState):
            timerManager?.stopTimer()
            currentLocationBottomConstraint.constant = Constant.Constraint.constant224
            stopRideButton.isHidden = true
            tripView.isHidden = true
            demoView.isHidden = false
            singleScooterBookNowTapped = false
            bikesInfoView.isHidden = true
            scooterBookedTimerView.isHidden = true
            timerStackView.isHidden = true
            findBikesBlurView.isHidden = true
            currentLocationContentView.isHidden = false
            bikesContentView.isHidden = false
            currentLocationBottomConstraint.constant = Constant.Constraint.constant224
            bottomSheetOpened = false
            
            if reloadState {
                collectionView.reloadData()
                if let selectedIndex = selectedIndex, let currentMarker = currentMarker {
                    guard let cell = self.collectionView.cellForItem(at: selectedIndex) else { return }
                    self.makeSelectedMarker(previousMarker: nil, currentMarker: currentMarker, index: IndexPath(item: 0, section: 0), cell: cell as? HomeBikeCollectionViewCell)
                } else {
                    guard let firstItem = bikes.first else { return }
                    let cell = self.collectionView(collectionView, cellForItemAt: IndexPath(item: 0, section: 0))
                    guard let currentMarker = self.markers[firstItem.id] else { return }
                    self.makeSelectedMarker(previousMarker: nil, currentMarker: currentMarker, index: IndexPath(item: 0, section: 0), cell: cell as? HomeBikeCollectionViewCell)
                }
            }
        case .scan(let bike):
            UserManager.share.isHaveBikeTrip = true
            if let data = bike.data?.start, let id = bike.bikeDto?.id, let mac = bike.bikeDto?.mac {
                var stringDate = String(data)
                stringDate.removeLast(3)
                let dataStarted = abs(Date().timeIntervalSince1970 - Double(Int(stringDate) ?? 0))
                BLEManager.shareInstance.scan(for: mac, bikeID: id, workOption: BLEOption(afterConnectOption: BLEOption.AfterConnect(unlockDevice: false, updateDeviceState: true)))
                setupScanTimer(time: dataStarted)
                self.timerManager?.startTimer()
            } else {
                return
            }
            stopRideButton.isHidden = false
            tripView.isHidden = false
            demoView.isHidden = true
            bottomSheet?.attemptDismiss(animated: true)
            bikesContentView.isHidden = true
            currentLocationContentView.isHidden = true
            findBikesBlurView.isHidden = true
            //            listenStateUpdate()
            bottomSheetOpened = false
            var lastCoortinates: CLLocationCoordinate2D?
            if let lastUpdateLat = UserDefaults.standard.value(forKey: "lastUpdated.lat") as? Double, let lastUpdateLong = UserDefaults.standard.value(forKey: "lastUpdated.long") as? Double {
                lastCoortinates = CLLocationCoordinate2D(latitude: lastUpdateLat, longitude: lastUpdateLong)
            } else {
                lastCoortinates =  MALocation.current.currentLocation?.coordinate
            }
            hideAllMarkers()
            addScannedBikeIntoCurrentLocation(coordinate: lastCoortinates ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
            self.isListeningStateUpdate = false
            self.listenStateUpdate()
        case .scanScooter(let scooter):
            for item in groupScooterGroupScrollView.subviews {
                item.removeFromSuperview()
            }
            if scooter.count > 0 {
                groupScooterGroupScrollView.isHidden = false
                UserManager.share.isHaveScooterTrip = true
                multyScoooterStackBottom.constant = 293
                currentLocationBottomConstraint.constant = 320
                multyScooterSStackView.isHidden = false
                scooter1CoontentView.layer.borderColor = UIColor.black.cgColor
                scooter1CoontentView.layer.borderWidth = 1.0
            } else {
                groupScooterGroupScrollView.isHidden = true
                multyScoooterStackBottom.constant = -40
                multyScooterSStackView.isHidden = true
            }
            
            switch scooter.count {
            case 0:
                scooter1View.isHidden = true
                scooter2View.isHidden = true
                scooter3View.isHidden = true
                addView.isHidden = true
                addScoterView.isHidden = false
            case 1:
                
                scooter1View.isHidden = false
                scooter2View.isHidden = true
                scooter3View.isHidden = true
                addView.isHidden = false
                addScoterView.isHidden = true
            case 2:
                scooter1View.isHidden = false
                scooter2View.isHidden = false
                scooter3View.isHidden = true
                addView.isHidden = false
                addScoterView.isHidden = true
            case 3:
                scooter1View.isHidden = false
                scooter2View.isHidden = false
                scooter3View.isHidden = false
                addView.isHidden = true
                addScoterView.isHidden = true
            default: break
            }
            print("scooterDto= \(scooter)")
            groupScooterGroupScrollView.contentSize = CGSize(width: CGFloat((scooter.count)) * view.frame.width, height: groupScooterGroupScrollView.frame.height)
            self.currectScuterId = scooter.first?.data?.id ?? ""
            self.scooterTripList = []
            for (index,item) in scooter.enumerated() {
                switch index {
                case 0:
                    self.scooter1Title.text = item.scooter?.qr ?? ""
                case 1:
                    self.scooter2Title.text = item.scooter?.qr ?? ""
                case 2:
                    self.scooter3Title.text = item.scooter?.qr ?? ""
                default:
                    print("Default")
                }
                var scooterTrips: StartTripViewController?
                
                if scooterTrips == nil {
                    scooterTrips = StartTripViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
                    
                }
                scooterTrips!.view.frame = CGRect(x: CGFloat(index) * view.frame.width, y: 0, width: view.frame.width, height: 303)
                scooterTrips?.delegate = self
                if let selectedSpeed = item.data?.speedModeTariff {
                    scooterTrips!.selectedSpeedTariff = SpeedTariff(id: selectedSpeed.id, title: "\(selectedSpeed.speed ?? 0)", price: selectedSpeed.price ?? 0.0, speed: selectedSpeed.speed ?? 0, isSelected: true)
                }
                
                let data = item.data?.start ?? 0
                var stringDate = String(data)
                stringDate.removeLast(3)
                let dd = Int(data / 1000)
                let dataStarted = abs(Date().timeIntervalSince1970 - Double(dd))
                
                scooterTrips!.startTime = dataStarted
//                scooterTrips!.setupScanTimer(time: dataStarted)
//                scooterTrips!.batteryPersentLbl.text = "\(item.scooter?.batteryPercent ?? 0)%"
                scooterTrips!.scooterStateModel = item
                scooterTrips!.scooterQr = item.scooter?.qr ?? ""
                scooterTrips!.getSingleScooterData()
                self.scooterTripList?.append(scooterTrips!)
                groupScooterGroupScrollView.addSubview(scooterTrips!.view)
                
                scooterTrips!.startPrise = item.data?.amount ?? 0.0
                scooterTrips!.startDistance = item.data?.distance ?? 0.0
                scooterTrips!.view.backgroundColor = .white
                scooterTrips!.view.isHidden = false
                
                
                
                scoterSoket.connect { result in
                    switch result {
                    case .success:
                        print("scooter soket connected")
                    case .failure(let error):
                        print("scoter coket error = \(error)")
                    }
                }
//                scoterSoket.scooterTrip = { [weak self] data in
//                    guard let self = self else { return }
//                    print(data)
//                    self.scooterPlanMode = data.data?.billingModeTariff?.mode ?? ""
//                    self.updateMarker(model: data.scooter!)
//                    self.scooterTripList?.first(where: { ($0.scooterStateModel?.scooter?.qr ?? "") == (data.scooter?.qr ?? "") })?.updateUI(data: data)
////                    scooterTrips?.updateUI(data: data)
//                }
                stopRideButton.isHidden = UserManager.share.isHaveBikeTrip ? false : true
                
                tripView.isHidden = UserManager.share.isHaveBikeTrip ? false : true
                demoView.isHidden = !UserManager.share.isHaveBikeTrip ? false : true
                bottomSheet?.didDismiss = nil
                bottomSheet?.attemptDismiss(animated: false)
                bottomSheet = nil
                
                
                bikesContentView.isHidden = true
                currentLocationContentView.isHidden = true
                findBikesBlurView.isHidden = true
                //            listenStateUpdate()
                bottomSheetOpened = false
//                var lastCoortinates: CLLocationCoordinate2D?
//                if let lastUpdateLat = UserDefaults.standard.value(forKey: "lastUpdated.lat") as? Double, let lastUpdateLong = UserDefaults.standard.value(forKey: "lastUpdated.long") as? Double {
//                    lastCoortinates = CLLocationCoordinate2D(latitude: lastUpdateLat, longitude: lastUpdateLong)
//                } else {
//                    lastCoortinates =  MALocation.current.currentLocation?.coordinate
//                }
//                print("item.scooter?.located = \(item.scooter?.located)")
                hideAllMarkers()
                //                DispatchQueue.main.async {
                self.addScannedBikeIntoCurrentLocation(coordinate: CLLocationCoordinate2D(latitude: item.scooter?.located?.latitude ?? 0.0, longitude: item.scooter?.located?.longitude ?? 0.0), for: item.scooter)
                
                self.drawParkings()
                
                //                }
                //                listenStateUpdate()
                
            }
            self.currentScooterTrip = scooterTripList?.first
//            getMapZones()
//            drawMapZones()
        case .accountDone:
            blurEffectView.isHidden =  true
            stopRideButton.isHidden = UserManager.share.isHaveBikeTrip ? false : true
            tripView.isHidden = UserManager.share.isHaveBikeTrip ? false : true
            demoView.isHidden = !UserManager.share.isHaveBikeTrip ? false : true
            if !UserManager.share.isHaveBikeTrip {
                openBottomSheet()
            }
            
            completeAccountContentView?.isHidden = true
            bikesContentView.isHidden = true
            if viewForBlur != nil {
                viewForBlur.isHidden = true
            }
            viewForBlur?.removeFromSuperview()
            
            if UserDefaults.standard.bool(forKey: "isAlreadyOpen") {
                print("====== 1")
                findBikesBlurView.isHidden = true
            } else {
                print("====== 5")
                //                findBikesBlurView.frame = self.view.bounds
                findBikesBlurView.isHidden = false // TODO: need to be false
                UIApplication.shared.windows.first?.addSubviewSizedConstraints(view: findBikesBlurView)
                UserDefaults.standard.setValue(true, forKey: "isAlreadyOpen")
                UIApplication.shared.windows.first?.addSubviewSizedConstraints(view: viewForBlur)
            }
            
            for item in groupScooterGroupScrollView.subviews {
                item.removeFromSuperview()
            }
            
            groupScooterGroupScrollView.isHidden = true
            multyScoooterStackBottom.constant = -40
            multyScooterSStackView.isHidden = true
            
        case .accountNotComplete:
            stopRideButton.isHidden = true
            tripView.isHidden = true
            demoView.isHidden = false
            openBottomSheet()
            
            completeAccountContentView?.isHidden = true
            bikesContentView.isHidden = true
            viewForBlur?.removeFromSuperview()
            if UserDefaults.standard.bool(forKey: "isAlreadyOpen") {
                findBikesBlurView.isHidden = true
                print("====== 2")
            } else {
                print("====== 3")
                //                findBikesBlurView.frame = self.view.bounds
                findBikesBlurView.isHidden = false // TODO: nneed to be false
                UIApplication.shared.windows.first?.addSubviewSizedConstraints(view: findBikesBlurView)
                
                UserManager.share.debtState?.state = .NoMinimalAmount
                NotificationCenter.default.post(name: Constant.Notifications.updateFinansialState, object: nil)
                showCompletePorfileHint()
                
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func showCompletePorfileHint() {
        findBikesBlurView.isHidden = true
        completeAccountContentView?.isHidden = false
        UIApplication.shared.windows.first?.addSubviewSizedConstraints(view: viewForBlur)
    }
    
    private func showBikeHint() {
        
        findBikesBlurView.frame = self.view.bounds
        self.view.layoutIfNeeded()
        self.findBikesBlurView.layoutIfNeeded()
        findBikesBlurView.removeFromSuperview()
        UIApplication.shared.windows.first?.addSubviewSizedConstraints(view: findBikesBlurView)
        findBikesBlurView.isHidden = false // TOODO: need to be false
        completeAccountContentView?.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapFindBike))
        findBikesBlurView.addGestureRecognizer(tapGesture)
    }
    
    @objc func tapFindBike() {
        findBikesBlurView.isHidden = true
    }
    
    private func addBlurEffect() {
        
        viewForBlur.insertSubview(blurEffectView, at: 0)
        blurEffectView.backgroundColor = .mimoBlackWith025alpha
        blurEffectView.alpha = 0.75
        blurEffectView.frame = self.viewForBlur.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        UIView.animate(withDuration: 0.5) {
            self.blurEffectView.effect = UIBlurEffect(style: .dark)
        }
        viewForBlur.removeFromSuperview()
        UIApplication.shared.windows.first?.addSubviewSizedConstraints(view: viewForBlur)
    }
    
    private func openBottomSheet() {
        guard bottomSheetOpened == false else { return }
        
        bikesContentView.isHidden = true
        currentLocationBottomConstraint.constant = Constant.Constraint.constant184
        
        let useInlineMode = view != nil
        
        let controller = HomeScanQrSheetViewController.initFromStoryboard(name: Constant.Storyboards.home)
        controller.delegate = self
        print("UserManager.share.debtAmount = \(UserManager.share.debtAmount)")
        controller.usertDebt = UserManager.share.debtAmount ?? 0.0
        var options = SheetOptions()
        options.pullBarHeight = 10
        
        options.useInlineMode = useInlineMode
        
        bottomSheet?.didDismiss = nil
        bottomSheet = nil
        bottomSheet = SheetViewController(
            controller: controller,
            sizes: [.percent(0.1405), .percent(0.5222)],
            options: options)
        guard let bottomSheet = bottomSheet else {
            return
        }
        
        bottomSheet.sizeChanged = {[weak self] sheet, size, height in
            guard let self = self else { return }
            print("Changed to \(size) with a height of \(height)")
            if size == .percent(0.5222) {
                controller.balanceContentView.alpha = 1
                UIView.animate(withDuration: 0.3) {
                    self.bottomSheet?.dismissOnOverlayTap = true
                    self.bottomSheet?.overlayColor = UIColor.mimoBlackWith03alpha
                }
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.bottomSheet?.dismissOnOverlayTap = false
                    self.bottomSheet?.overlayColor = .clear
                }
                controller.balanceContentView.alpha = 0
                controller.configureUI()
            }
        }
        
        bottomSheet.allowPullingPastMaxHeight = false
        bottomSheet.allowPullingPastMinHeight = false
        bottomSheet.dismissOnPull = false
        bottomSheet.dismissOnOverlayTap = false
        bottomSheet.gripSize.height = 4
        bottomSheet.gripSize.width = 38
        bottomSheet.overlayColor = UIColor.clear
        bottomSheet.gripColor = UIColor.mimoBlackWith025alpha
        bottomSheet.view.addShadow(color: UIColor.mimoBlackWith025alpha)
        bottomSheet.allowGestureThroughOverlay = true
        
        if let view = view {
            bottomSheet.animateIn(to: view, in: self) {
                if case .accountDone = self.state {
                    self.viewForBlur?.isHidden = true
                }
            }
        } else {
            self.present(bottomSheet, animated: true, completion: nil)
        }
        bottomSheetOpened = true
        findBikesBlurView.bringSubviewToFront(bottomSheet.view)
        bottomSheet.view.bringSubviewToFront(findBikesBlurView)
        
        //        let window = UIApplication.shared.windows.last!
        //        window.addSubview(findBikesBlurView)
        
    }
    
    ///preview details bike
    private func previewBike(result: BikeResult) {
        
        let useInlineMode = view != nil
        let controller = HomeSingleBikeViewController.initFromStoryboard(name: Constant.Storyboards.home)
        controller.delegate = self
        controller.bikeResult = result
        if case .bookedBike = self.state {
            controller.isBooked = true
        } else {
            controller.isBooked = false
        }
        var options = SheetOptions()
        options.pullBarHeight = 10
        options.useInlineMode = useInlineMode
        
        bottomSheet?.didDismiss = nil
        bottomSheet?.attemptDismiss(animated: false)
        bottomSheet = nil
        bottomSheet = SheetViewController(
            controller: controller,
            sizes: [.percent(0.576355)],
            options: options)
        guard let bottomSheet = bottomSheet else {
            return
        }
        
        bottomSheet.didDismiss = {[weak self] controller in
            guard controller.childViewController is HomeSingleBikeViewController else {
                return
            }
            
            guard let self = self, self.bikesContentView.isHidden, !self.singleBikeBookNowTapped else { return }
            if case .bookedBike = self.state {
                return
            }
            self.previousMarker = self.currentMarker
            self.openBottomSheet()
        }
        self.bottomSheetOpened = false
        bottomSheet.allowPullingPastMaxHeight = false
        bottomSheet.dismissOnPull = true
        bottomSheet.gripSize.height = 4
        bottomSheet.gripSize.width = 38
        bottomSheet.gripColor = UIColor.mimoBlackWith025alpha
        bottomSheet.overlayColor = UIColor.mimoBlackWith03alpha
        bottomSheet.dismissOnOverlayTap = true
        bottomSheet.view.addShadow(color: UIColor.mimoBlackWith025alpha)
        
        if let view = view {
            bottomSheet.animateIn(to: view, in: self)
        } else {
            self.present(bottomSheet, animated: true, completion: nil)
        }
    }
    
    ///preview details Scooter
    private func previewScooter(result: ScooterResult) {
        
        let useInlineMode = view != nil
        let controller = HomeSingleScooterViewController.initFromStoryboard(name: Constant.Storyboards.home)
        controller.delegate = self
        controller.scooterResult = result
        if case .bookedScooter = self.state {
            controller.isBooked = true
        } else {
            controller.isBooked = false
        }
        var options = SheetOptions()
        options.pullBarHeight = 10
        options.useInlineMode = useInlineMode
        qrLabel.text = result.qr
        bottomSheet?.didDismiss = nil
        bottomSheet?.attemptDismiss(animated: false)
        bottomSheet = nil
        bottomSheet = SheetViewController(
            controller: controller,
            sizes: [.percent(0.576355)],
            options: options)
        guard let bottomSheet = bottomSheet else {
            return
        }
        
        bottomSheet.didDismiss = { [weak self] controller in
            guard controller.childViewController is HomeSingleScooterViewController else {
                return
            }
            
            guard let self = self, self.bikesContentView.isHidden, !self.singleScooterBookNowTapped else { return }
            if case .bookedBike = self.state {
                return
            }
            self.previousMarker = self.currentMarker
            self.openBottomSheet()
        }
        self.bottomSheetOpened = false
        bottomSheet.allowPullingPastMaxHeight = false
        bottomSheet.dismissOnPull = true
        bottomSheet.gripSize.height = 4
        bottomSheet.gripSize.width = 38
        bottomSheet.gripColor = UIColor.mimoBlackWith025alpha
        bottomSheet.overlayColor = UIColor.mimoBlackWith03alpha
        bottomSheet.dismissOnOverlayTap = true
        bottomSheet.view.addShadow(color: UIColor.mimoBlackWith025alpha)
        
        if let view = view {
            bottomSheet.animateIn(to: view, in: self)
        } else {
            self.present(bottomSheet, animated: true, completion: nil)
        }
    }
    
    @objc func getNews() {
        print("==================== getNews ====================")
        homeViewModel.getNews {  [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let newsList):
                print(newsList)
                if let lastDate = UserDefaults.standard.value(forKey: "lastShowDateForNews") {
                    if let lDate = lastDate as? Date {
                        print("lastShowDateForNews = ", Date().timeIntervalSince1970 - lDate.timeIntervalSince1970)
                        if Date().timeIntervalSince1970 - lDate.timeIntervalSince1970 > 86400 {
                            DispatchQueue.main.async {
                                if  newsList.count > 0 {
                                    print("==================== There is  News 1 ====================")
                                    UserDefaults.standard.setValue(Date(), forKey: "lastShowDateForNews")
                                    self.showNewsScreen(newsList: newsList)
                                } else {
                                    print("==================== NO Any  News 1 ====================")
                                }
                            }
                        } else {
                            print("==================== NO more than one hour 1 ====================")
                        }
                    }
                } else {
                    UserDefaults.standard.setValue(Date(), forKey: "lastShowDateForNews")
                    DispatchQueue.main.async {
                        if  newsList.count > 0 {
                            self.showNewsScreen(newsList: newsList)
                        } else {
                            print("==================== There is  News 2 ====================")
                        }
                    }
                }
                
            case .failure(let error):
                print(error)
                switch error {
                case .invalidParse(let message):
                    UIAlertController.showError(message: message.localized())
                case .responseError(let message):
                    UIAlertController.showError(message: message.localized())
                case .validatorError(let message):
                    UIAlertController.showError(message: message.localized())
                default:
                    UIAlertController.showError(message: "Somthing went wrong!")
                    
                }
            }
        }
    }
    
    private func showNewsScreen(newsList: [NewsObject]) {
        let vc = UIStoryboard(name: "ScooterPlan", bundle: .main).instantiateViewController(withIdentifier: "StoriNewsViewController") as? StoriNewsViewController
        vc?.modalPresentationStyle = .fullScreen
        if let news = newsList.first {
            vc?.news = news
        }
        self.present(vc!, animated: true)
    }
    
    private func presentComplateAccountVC() {
        completeAccountContentView?.isHidden = true
        viewForBlur?.isHidden = true
        let complateAccountVC = CompleteProfileViewController.initFromStoryboard(name: Constant.Storyboards.completeAccount)
        let nc = UINavigationController(rootViewController: complateAccountVC)
        nc.modalPresentationStyle = .pageSheet
        nc.isModalInPresentation = true
        
        present(nc, animated: true, completion: nil)
        NotificationCenter.default.addObserver(forName: .init(rawValue: "AccountDidComplete"), object: nil, queue: .main) {[weak self] notification in
            self?.state = .smallBottomSheet
        }
    }
    
    private func presentScanVC() {
        //        let scanVC = ParkingPhotoCameraViewController.initFromStoryboard(name: Constant.Storyboards.parkingPhotoCamera)
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
        
        //        present(UINavigationController(rootViewController: scanVC), animated: true, completion: nil)
        
        let scanVC = ScanViewController.initFromStoryboard(name: Constant.Storyboards.scan)
        scanVC.testDelegate = self
        self.homeViewModel.listenScanBikeChange { [weak self, weak scanVC] result in
            guard let unwrapSelf = self else { return }
            switch result {
            case .success(let trip):
                MILoader.hide()

                if trip.action == .TripEnded {
                    UserManager.share.isHaveBikeTrip = false
                    unwrapSelf.stopTrip()
                    unwrapSelf.tripTime = 1
                    scanVC?.dismiss(animated: true, completion: nil)
                }

                if trip.action == .TripNotStarted {
                    print("Culd not start the trip.")
                    UserManager.share.isHaveBikeTrip = false
                    //                    UIAlertController.showError(message: "Culd not start the trip.")
                    scanVC?.dismiss(animated: true, completion: nil)
                }

                if trip.action == .None {
                    UserManager.share.isHaveBikeTrip = false
                    unwrapSelf.updateControllerState(state: .smallBottomSheet)
                    scanVC?.dismiss(animated: true, completion: nil)
                }

                if trip.action == .TripStarted {

                    UserManager.share.isHaveBikeTrip = true
                    unwrapSelf.trip = trip
                    unwrapSelf.updateControllerState(state: .scan(bike: trip))
                    unwrapSelf.hideAllMarkers()
                    scanVC?.dismiss(animated: true, completion: nil)
                }

            case .failure(let error):
                UIAlertController.showError(message: error.message.localized())
            }
        }
        scanVC.scannedTrip = { [weak self] (trip) in
            guard let unwrapSelf = self else { return }
            unwrapSelf.updateRideState()
        }
        
        present(UINavigationController(rootViewController: scanVC), animated: true, completion: nil)
    }
    
    private func presentAccountVC() {
        let accountVC = AccountViewController.initFromStoryboard(name: Constant.Storyboards.account)
        let nc = UINavigationController(rootViewController: accountVC)
        present(nc, animated: true, completion: nil)
    }
    
    /// Get bikes
    private func getBikes() {
        
        hideAllMarkers()
        homeViewModel.getBikes { [weak self] result in
            
            guard let self = self else { return }
            switch result {
            case .success(let bikeResults):
                
                self.bikes = bikeResults.0
                guard let currentLocation = self.locationManager.currentLocation else {
                    self.updateMarkers(marker: bikeResults.1, for: .bike)
                    return
                }
//                self.bikes = bikeResults.0.sorted(by: { leftBike, rightBike in
//                    return leftBike.getDistancePrettyPrinted(userCoordinate: currentLocation.coordinate).0 < rightBike.getDistancePrettyPrinted(userCoordinate: currentLocation.coordinate).0
//                })
                DispatchQueue.global(qos: .unspecified).async {
                    self.bikes.forEach { bike in
                        
//                        bike.cacheLocation()
                    }
                }
                if let state = (UserDefaults.standard.value(forKey: "BikeState") as? String), state == "bike" {
                    self.updateMarkers(marker: bikeResults.1, for: .bike)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    ///Get Parkings
    
    private func drawParkings() {
        if let state = (UserDefaults.standard.value(forKey: "BikeState") as? String), state != "scooter" {
            return
        }
        
        DispatchQueue.main.async {
            self.parkingMarkers.forEach { marker in
                if self.mapView.isMarkerVisible(onMap: marker) {
                    marker.map = self.mapView
                } else {
                    marker.map = nil
                }
            }
        }
    }
    
    private func getParkings() {
        homeViewModel.getParkings { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(parkers):
//                print(parkers)
                self.parkers = parkers
                parkers.forEach({ self.createParkingMarkers(parking: $0) })
                self.drawParkings()
            case .failure(let error):
                switch error {
                case .responseError(let message):
                    self.showErrorAlertMessage(message)
                case .serverError:
                    self.showErrorAlertMessage("Server Error")
                default: break
                }
            }
        }
    }
    
    /// Get scooters
    private func getScooters() {
        hideAllMarkers()
        homeViewModel.getScooters { [weak self] result in
            
            guard let self = self else { return }
            switch result {
                case .success(let scooterResults):
                    
                    self.scooters = scooterResults.0
                    guard let currentLocation = self.locationManager.currentLocation else {
                        self.updateMarkers(marker: scooterResults.1, for: .scooter)
                        return
                    }
//                    self.scooters = scooterResults.0.sorted(by: { leftScooter, rightScooter in
//                        return leftScooter.getDistancePrettyPrinted(userCoordinate: currentLocation.coordinate).0 < rightScooter.getDistancePrettyPrinted(userCoordinate: currentLocation.coordinate).0
//                    })
//                    DispatchQueue.global(qos: .unspecified).async {
//                        self.scooters.forEach { scooter in
//
//                            scooter.cacheLocation()
//                        }
//                    }
                if let state = (UserDefaults.standard.value(forKey: "BikeState") as? String), state == "scooter" {
                    self.updateMarkers(marker: scooterResults.1, for: .scooter)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func updateMarkers(marker: MarkerAction, for type: HomeScanQrSheetButtonsState) {
        if (UserDefaults.standard.value(forKey: "BikeState") as? String) == "scooter" {
            scooters.forEach { scooter in
                switch marker {
                case .add:
                    self.addMarker(model: scooter)
                case .update:
//                                            self.updateMarker(model: scooter)
                    print("")
                }
            }
        } else {
            bikes.forEach { bike in
                switch marker {
                case .add:
                    self.addMarker(model: bike)
                case .update:
                    self.updateMarker(model: bike)
                }
            }
        }
        if bookedDevice != nil {
            hideAllMarkers()
        }
        if trip != nil {
            hideAllMarkers()
            
        }
    }
    
    private func updateMarker(model: BikeResult, isUpdateBike: Bool = false) {
        if model.updated {
            if self.trip?.action == .TripStarted {
                print("Trip Started: bike qr -  \(model.qr)")
                if isUpdateBike {
                    UserDefaults.standard.set( model.latitude, forKey: "lastUpdated.lat")
                    UserDefaults.standard.set( model.longitude, forKey: "lastUpdated.long")
                    print("Trip Started: lat - \(model.latitude) , long - \(model.longitude)")
                    hideAllMarkers()
                    addScannedBikeIntoCurrentLocation(coordinate: CLLocationCoordinate2D(latitude: model.latitude, longitude: model.longitude))
                }
            } else {
                let marker = markers[model.id]
                marker?.map = nil
                marker?.position = CLLocationCoordinate2D(latitude: model.latitude, longitude: model.longitude)
                marker?.map = mapView
            }
        }
    }
    
    private func addMarker(model: BikeResult) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: model.latitude, longitude: model.longitude)
        marker.icon = #imageLiteral(resourceName: "ic_bike_marker")
        
        marker.map = mapView
        markers[model.id] = marker
        
        if model.id == self.bikes.first?.id {
            let location = CLLocation(latitude: model.latitude, longitude: model.longitude)
            //            self.centerMapOnLocation(location, mapView: mapView)
        }
        
        if model.id == self.bookedDevice?.id {
            currentMarker = marker
            
        }
        if model.id == self.trip?.bikeDto?.id {
            currentMarker = marker
        }
    }
    
    private func addParking(parking: ParkingResponse) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: parking.location?.latitude ?? 0.0, longitude: parking.location?.longitude ?? 0.0)
        marker.icon = #imageLiteral(resourceName: "parking_nim")
        marker.title = "Parking\n\(parking.id ?? "")"
        
//        if mapView.isMarkerVisible(onMap: marker) {
            marker.map = mapView
//        }
        
//        print("added parking to \(parking)")
        
//        self.parkingMarkers.append(marker)
    }
    
    private func createParkingMarkers(parking: ParkingResponse) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: parking.location?.latitude ?? 0.0, longitude: parking.location?.longitude ?? 0.0)
        marker.icon = #imageLiteral(resourceName: "parking_nim")
        marker.title = "Parking\n\(parking.id ?? "")"
        
        self.parkingMarkers.append(marker)
    }
    
    private func addMarker(model: ScooterResult) {
        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: model.latitude, longitude: model.longitude)
        switch model.batteryPercent {
        case 0...20: marker.icon = #imageLiteral(resourceName: "ic_scooter_batarey_0")
        case 21...40: marker.icon = #imageLiteral(resourceName: "ic_scooter_batarey_25")
        case 41...60: marker.icon = #imageLiteral(resourceName: "ic_scooter_batarey_50")
        case 61...80: marker.icon = #imageLiteral(resourceName: "ic_scooter_batarey_75")
        case 81...100: marker.icon = #imageLiteral(resourceName: "ic_scooter_batarey_100")
        default: break
        }
        
        marker.map = mapView
        markers[model.id] = marker
        
        if model.id == self.bikes.first?.id {
            let location = CLLocation(latitude: model.latitude, longitude: model.longitude)
            //            self.centerMapOnLocation(location, mapView: mapView)
        }
        
        if model.id == self.bookedDevice?.id {
            currentMarker = marker
            
        }
        if model.id == self.trip?.bikeDto?.id {
            currentMarker = marker
        }
    }
    
    private func updateMarker(model: IScanedScooter, isUpdateBike: Bool = false) {
        if self.trip?.action == .TripStarted {
            print("Trip Started: bike qr -  \(model.qr)")
            if isUpdateBike {
                UserDefaults.standard.set( model.located?.latitude ?? 0, forKey: "lastUpdated.lat")
                UserDefaults.standard.set( model.located?.longitude ?? 0, forKey: "lastUpdated.long")
                print("Trip Started: lat - \(model.located?.latitude ?? 0 ) , long - \(model.located?.longitude ?? 0)")
                hideAllMarkers()
                addScannedBikeIntoCurrentLocation(coordinate: CLLocationCoordinate2D(latitude: model.located?.latitude ?? 0, longitude: model.located?.longitude ?? 0))
            }
        }
    }
    
    func centerMapOnLocation(_ location: CLLocation, mapView: GMSMapView, zoom: Float = 10, aniamtable: Bool = true) {
        //                mapView.animate(toLocation: location.coordinate)
        //                mapView.animate(toZoom: zoom)
        
        delay(seconds: 0.2) { [weak self] () -> () in
            guard let self = self else { return }
            let zoomOut = GMSCameraUpdate.zoom(to: 16)
            self.mapView.animate(with: zoomOut)
            
            self.delay(seconds: 0.1, closure: { [weak self] () -> () in
                guard let self = self else { return }
                
                let vancouver = location.coordinate
                let vancouverCam = GMSCameraUpdate.setTarget(vancouver)
                self.mapView.animate(with: vancouverCam)
                
                self.delay(seconds: 0.3, closure: { [weak self] () -> () in
                    guard let self = self else { return }
                    
                    let zoomIn = GMSCameraUpdate.zoom(to: zoom)
                    self.mapView.animate(with: zoomIn)
                    
                })
            })
        }
    }
    
    func delay(seconds: Double, closure: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            closure()
        }
    }
    
    func isUpdateAvailable(completion: @escaping (Bool?, Error?) -> Void) throws -> URLSessionDataTask {
        guard let info = Bundle.main.infoDictionary,
              let currentVersion = info["CFBundleShortVersionString"] as? String,
              let identifier = info["CFBundleIdentifier"] as? String,
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(identifier)") else {
            throw VersionError.invalidBundleInfo
        }
        print("currentVersion = \(currentVersion)")
        let task = URLSession.shared.dataTask(with: url) { [weak self] (data, response, error) in
            guard let self = self else { return }
            
            do {
                if let error = error { throw error }
                guard let data = data else { throw VersionError.invalidResponse }
                let json = try JSONSerialization.jsonObject(with: data, options: [.allowFragments]) as? [String: Any]
                guard let result = (json?["results"] as? [Any])?.first as? [String: Any], let version = result["version"] as? String else {
                    throw VersionError.invalidResponse
                }
                print("version = \(version)")
                print("currentVersion = \(currentVersion)")
                completion(version > currentVersion, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
        return task
    }
    
    //MARK: - Actions
    
    
    @IBAction func scooterAction(_ sender: UIButton) {
        self.updateMultypleScoterSelect(currentIndex: sender.tag)
//        groupScooterGroupScrollView.contentOffset.x = CGFloat(sender.tag) * view.frame.width
        currectScuterId = self.currentScooterStateModelList?[sender.tag].data?.id ?? ""
        scrollToPage(page: sender.tag, animated: true)
        DispatchQueue.main.async {
            if let curScooter = self.currentScooterStateModelList?[sender.tag] {
                let zoomOut = GMSCameraUpdate.zoom(to: 16)
                self.mapView.animate(with: zoomOut)
                let vancouver = CLLocationCoordinate2D(latitude: curScooter.scooter?.located?.latitude ?? 0.0, longitude: curScooter.scooter?.located?.longitude ?? 0.0)
                let vancouverCam = GMSCameraUpdate.setTarget(vancouver)
                self.mapView.animate(with: vancouverCam)
            }
        }
        self.currentScooterTrip = self.scooterTripList?[sender.tag]

    }
    
    func scrollToPage(page: Int, animated: Bool) {
        var frame: CGRect = self.groupScooterGroupScrollView.frame
        frame.origin.x = frame.size.width * CGFloat(page)
        frame.origin.y = 0
        self.groupScooterGroupScrollView.scrollRectToVisible(frame, animated: animated)
    }
    
    @IBAction func startRideFromBookAction(_ sender: UIButton) {
        presentScanVC()
    }
    
    @IBAction func addScooterAction(_ sender: UIButton) {
        presentScanVC()
    }
    
    
    @IBAction func bikesTutorialButtonTapped(_ sender: UIButton) {
        
        findBikesBlurView.isHidden = true
    }
    
    @IBAction func avatarTapped(_ sender: UIButton) {
        //        guard trip == nil else {
        //            UIAlertController.showError(message: "You have active trip, finish trip to use application".localized())
        //            return
        //        }
        
        guard bookedDevice == nil else {
            UIAlertController.showError(message: "You are booking a bike, stop booking to use application".localized())
            return
        }
        
        if case .accountNotComplete = state {
            presentComplateAccountVC()
            return
        }
        
        presentAccountVC()
    }
    
    @IBAction func completeAccountTapped(_ sender: UIButton) {
        
        presentComplateAccountVC()
    }
    
    @IBAction func bikeViewBackTapped(_ sender: UIButton) {
        updateControllerState(state: .smallBottomSheet)
        previousMarker = currentMarker
        guard collectionView.cellForItem(at: IndexPath(item: 0, section: 0)) != nil else { return }
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    @IBAction func currentLocationTapped(_ sender: UIButton) {
        if locationManager.isAccessed, let location = locationManager.currentLocation {
            let camera = GMSCameraPosition.camera(withLatitude: (location.coordinate.latitude), longitude: location.coordinate.longitude, zoom: 17.0)
            mapView?.animate(to: camera)
        } else {
            locationManager.alertLocationAccess()
            locationManager.didChangeAuthStatus = {[weak self] state in
                if state {
                    self?.currentLocationTapped(UIButton())
                }
            }
        }
    }
    
    @IBAction func infoTapped(_ sender: Any) {
        let onboardingView = OnboardingViewController.initFromStoryboard(name: "SignIn")
        onboardingView.isPresentedHome = true
        
        navigationController?.pushViewController(onboardingView, animated: true)
    }
    
    @IBAction func stopRideTapped() {
        UIAlertController.showError(message: "MOBILE_lock_bike".localized())
    }
    
    @IBAction func stopBooking(_ sender: CircleButton) {
        guard let bookedBikeID = bookedDevice?.id else {
            return
        }
        homeViewModel.cancelBikeBook(bikeID: bookedBikeID) {[weak self] result in
            guard let self = self else { return }
            if case .failure(let message) = result {
                UIAlertController.showError(message: message.localizedDescription)
            } else {
                self.removeBookedBikeMarker()
                self.markers.map { $1 }.forEach { $0.map = self.mapView }
                self.updateControllerState(state: .previewBikes(reloadData: true))
                self.singleBikeBookNowTapped = false
                self.timerManager?.stopTimer()
                self.timerManager = nil
                self.bookedDevice = nil
            }
        }
    }
    
    @IBAction func bookStopAction(_ sender: UIButton) {
        guard let bookedBikeID = bookedDevice?.id else {
            return
        }
        homeViewModel.cancelScooterBook(bikeID: bookedBikeID) {[weak self] result in
            guard let self = self else { return }
            if case .failure(let message) = result {
                switch message as? NetworkError {
                case .invalidParse(let text):
                    UIAlertController.showError(message: text.localized())
                default:
                    UIAlertController.showError(message: "Server Error")
                }
                
            } else {
                self.removeBookedBikeMarker()
                self.markers.map { $1 }.forEach { $0.map = self.mapView }
                self.updateControllerState(state: .previewScooters(reloadData: true))
                self.singleBikeBookNowTapped = false
                self.timerManager?.stopTimer()
                self.timerManager = nil
                self.bookedDevice = nil
            }
        }
    }
    
    @IBAction func drawNavigation() {
        if let bookedBike = bookedDevice {
            var url = "yandexnavi://build_route_on_map?lat_to=\(bookedBike.location.latitude)&lon_to=\(bookedBike.location.longitude)"
            if UIApplication.shared.canOpenURL(URL(string: url)!) {
                UIApplication.shared.open(URL(string: url)!, options: [:], completionHandler: nil)
            } else {
                url = "https://itunes.apple.com/ru/app/yandex.navigator/id474500851"
                if UIApplication.shared.canOpenURL(URL(string: url)!) {
                    UIApplication.shared.open(URL(string: url)!, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    @IBAction func beepBookedBike(_ sender: Any) {
        homeViewModel.beepBookedBike()
    }
    
    @IBAction func beepBookedScooterAction(_ sender: UIButton) {
        homeViewModel.beepBookedScooter()
    }
    
    @IBAction func showZoneInfoList(_ sender: UIButton) {
        openZoneInfo()
    }
    
    func openZoneInfo(zoneId: String = "") {
        if isZoneInfoOpened {
            self.closeZoneInfo(duration: 0.1)
        } else {
            let zoneInfoStoryboard = UIStoryboard(name: "ZoneInfo", bundle: .main)
            zoneVC = zoneInfoStoryboard.instantiateViewController(withIdentifier: "AllZoneInfoViewViewController") as? AllZoneInfoViewViewController
            zoneInfoHeight = zoneId.count > 0 ? 250 : 480
            zoneVC!.view.frame = CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: self.zoneInfoHeight)
            zoneVC?.clickedZone = zoneId
            zoneVC?.view.addShadow(color: .black)
            zoneVC?.view.layer.cornerRadius = 12
            
            isZoneInfoOpened = true
            self.view.addSubview((zoneVC?.view)!)
            UIView.animate(withDuration: 0.2) {
                self.zoneVC!.view.frame = CGRect(x: 0, y: self.view.frame.height - self.zoneInfoHeight, width: self.view.frame.width, height: self.zoneInfoHeight)
            } completion: { isFinished in
                self.isZoneInfoOpened = true
            }
            
            zoneVC?.delegate = self
        }
    }
    
    func closeZoneInfo(duration: CGFloat) {
        UIView.animate(withDuration: duration) {
            self.zoneVC!.view.frame = CGRect(x: 0, y: self.view.frame.height, width: self.view.frame.width, height: self.zoneInfoHeight)
        } completion: { isFinished in
            self.zoneVC?.removeFromParent()
            self.zoneVC = nil
            self.isZoneInfoOpened = false
        }
    }
}

extension HomeViewController: AllZoneInfoViewViewControllerDelegate {
    func didSelectOkay() {
        self.closeZoneInfo(duration: 0.2)
    }
}
extension HomeViewController: ShowDebtViewControllerDdelegate {
    
    func didSelectTransfer() {
        
    }
    
    func didSelectTransfer(wallet: WalletDebts) {
        isOpenDebtScreen = false
        UserManager.share.isOpenDebtScreen = false
        self.showDebtVc?.dismiss(animated: true)
        MILoader.show()
        self.transferViewModel.isMimoUser(phoneNumber: wallet.walletId ?? "", completed: { [weak self] (mimoCheckStatus) in
            MILoader.hide()
            
            switch mimoCheckStatus {
            case .isMimoUser(let user):
                self?.goToTransferToFriendVC(wallet.walletId ?? "", user, debt: wallet.debtSum)
            case .noSuchUser:
                self?.inviteUser(wallet.walletId ?? "")
            case .error:
                self?.showErrorAlertMessage("Failed to check contact user")
            }
        })
    }
    
    
    func didSelectPayDdebt() {
        self.showDebtVc?.dismiss(animated: true)
        self.openWalletVC()
    }
    
    func goToTransferToFriendVC(_ phoneNumber: String, _ transferUser: ContactsListModel?, debt: Double?) {
        let user = UserResult(userResponse: UserManager.share.userResponse)
        let trancferToFriendVC = TransferToFriendViewController.initiateFromStoryboard(phoneNumber, user: user, avatarUrl: nil, wallet: UserManager.share.walletModel, transferUser: transferUser)
        trancferToFriendVC.debt = debt
        //        trancferToFriendVC.modalPresentationStyle = .fullScreen
        self.present(trancferToFriendVC, animated: true)
        //        navigationController?.pushViewController(trancferToFriendVC, animated: true)
    }
    
    private func inviteUser(_ phoneNumber: String) {
        let inviteLocalized = "MOBILE_transfer_invite".localized()
        
        self.showAlertMessage("\(inviteLocalized) \(phoneNumber)", meassage: "MOBILE_transfer_invite_or_not".localized(), actionText: ["MOBILE_global_cancel".localized(), inviteLocalized]) { [weak self] (action) in
            if action == inviteLocalized {
                self?.transferViewModel.inviteUser(phoneNumber: phoneNumber) { _ in
                    
                }
            }
        }
        
    }
}

extension HomeViewController: PauseViewControllerDelegate {
    func didClosePause() {
        MILoader.show()
        homeViewModel.continueTrip(id: currectScuterId) { [weak self] result in
            guard let self = self else { return }
            MILoader.hide()
            switch result {
            case .success(let ok):
                print("continue is : \(ok)")
//                self.currentScooterTrip?.blureViewe.isHidden = true
                self.scooterTripList?.forEach({ $0.blureViewe.isHidden = true })
                self.pauseVC?.view.isHidden = true
                self.pauseVC?.dismiss(animated: true)
                self.pauseVC?.view.removeFromSuperview()
                self.pauseVC?.view = nil
                self.pauseVC = nil
                self.currentScooterTrip?.tenSecStart()
                
                for i in 0 ..< (self.currentScooterTrip?.currentData?.data?.pauses?.count ?? 0) {
                    if self.currentScooterTrip?.currentData?.data?.pauses?[i].end == nil {
                        self.currentScooterTrip?.currentData?.data?.pauses?[i].end = Int(Date().timeIntervalSince1970) * 1000
                    }
                }
                
                self.currentScooterTrip?.updateDurationData(force: true)
            case .failure(let error):
                switch error {
                case .validatorError(let message):
                    UIAlertController.showError(message: message.localized())
                default: break
                }
            }
        }
    }
}

extension HomeViewController: ChangeRideRateViewControllerDeelegate {
    
    func didChangeTariff(tripId: String?, speedId: String?) {
        MILoader.show()
        homeViewModel.changeSpeed(tarifId: self.tripId, speedId: speedTariff?.id ?? "") { [weak self] result in
            guard let self = self else { return }
            MILoader.hide()
            switch result {
            case .success(let isChanged):
                print("Speed Changed")
                self.changeSpeed?.view.isHidden = true
                self.changeSpeed?.view.removeFromSuperview()
                self.changeSpeed?.view = nil
                self.changeSpeed = nil
            case .failure(let err):
                switch err {
                case .validatorError(let message):
                    UIAlertController.showError(message: message.localized())
                default: break
                    
                }
            }
        }
    }
    
    func didCloseChangeTariff() {
        self.changeSpeed?.view.isHidden = true
        self.changeSpeed?.view.removeFromSuperview()
        self.changeSpeed?.view = nil
        self.changeSpeed = nil
        
    }
}

enum ScooterPlanMode: String {
    case FIXED
    case DO_NOT_SIT
    case MIN_By_MIN
}

extension HomeViewController: StartTripViewControllerDelegate {
    
    func didSelectSpeedTariff(speedTariff: SpeedTariff, tripId: String) {
        VibrateManager.vibrate()
        self.speedTariff = speedTariff
        self.tripId = tripId
        if self.changeSpeed == nil {
            self.changeSpeed = ChangeRideRateViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
            self.changeSpeed?.delegate = self
        }
        self.addChild(self.changeSpeed!)
        self.changeSpeed!.view.frame = self.view.bounds
        self.view.addSubview(self.changeSpeed!.view)
        self.changeSpeed!.didMove(toParent: self)
        self.changeSpeed!.view.backgroundColor = .black.withAlphaComponent(0.3)
        self.changeSpeed!.updateUI(speedTarif: speedTariff, scooterPlanMOed: self.scooterPlanMode)
    }
    
    
    func didPresPause(scooterStateModel: ScooterStateModel) {
        //PauseViewController
        print("Paused scooter QR = \(scooterStateModel.data?.id ?? "")")
        currectScuterId = scooterStateModel.data?.id ?? ""
        print("currectScuterId = \(currectScuterId)")
        MILoader.show()
        homeViewModel.pauseTrip(id: scooterStateModel.data?.id ?? "") { [weak self] result in
            guard let self = self else { return }
            MILoader.hide()
            switch result {
            case .success(let ok):
                self.timerManager?.stopTimer()
                print("ok")
                if self.pauseVC == nil {
                    self.pauseVC = PauseViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
                    self.pauseVC?.delegate = self
                }
                self.addChild(self.pauseVC!)
                self.pauseVC!.view.frame = self.view.bounds
                self.view.addSubview(self.pauseVC!.view)
                self.pauseVC!.didMove(toParent: self)
                self.pauseVC!.view.backgroundColor = .black.withAlphaComponent(0.3)
                self.pauseVC?.pausStarted = 0.0
                self.pauseVC!.updateTime()
                self.currentScooterTrip?.blureViewe.isHidden = false
                
                if ok {
                    self.currentScooterTrip?.timerManager?.pauseTimer()
                } else {
                    self.currentScooterTrip?.timerManager?.startTimer()
                }
            case .failure(let error):
                print(error)
                switch error as? NetworkError {
                case .validatorError(let message):
                    UIAlertController.showError(message: message.localized())
                default: break
                }
            }
            
        }
        
    }
}

//MARK: - collection view delegate and dataSource

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.bikeState == .bike ? self.bikes.count : self.scooters.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.bikeState == .bike {
            let cell = HomeBikeCollectionViewCell.reuseIdentifire(from: collectionView, indexPath: indexPath)
            
            cell.updateUI(bikeResult: bikes[optional: indexPath.item])
            
            if indexPath.item == 0 && !isAlreadyOpened {
                isAlreadyOpened = true
                cell.buttonContentView.backgroundColor = .mimoYellow500
            }
            
            if self.selectedIndex == indexPath {
                cell.buttonContentView.backgroundColor = .mimoYellow500
            }
            
            cell.delegate = self
            return cell
        } else {
            let cell = HomeScooterCollectionViewCell.reuseIdentifire(from: collectionView, indexPath: indexPath)
            cell.updateUI(scoterResult: scooters[optional: indexPath.item], isBooked: bookedDevice != nil)
            cell.takeScooterButton.backgroundColor = .mimoYellow500
            //            if indexPath.item == 0 && !isAlreadyOpened {
            //                isAlreadyOpened = true
            //                //                cell.buttonContentView.backgroundColor = .mimoYellow500
            //            }
            //
            //            if self.selectedIndex == indexPath {
            //                //                cell.buttonContentView.backgroundColor = .mimoYellow500
            //            }
            
            cell.delegate = self
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: Constant.Width.width288, height: Constant.Height.height184)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return UIEdgeInsets(top: 0, left: Constant.Width.width15, bottom: 0, right: Constant.Width.width15)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        VibrateManager.vibrate()
        if self.bikeState == .bike {
            previewBike(result: self.bikes[indexPath.item])
        } else {
            previewScooter(result: self.scooters[indexPath.item])
        }
    }
    
    func makeSelectedMarker(previousMarker: GMSMarker?, currentMarker: GMSMarker, index: IndexPath? = nil, cell: HomeBikeCollectionViewCell? = nil, scooterCell: HomeScooterCollectionViewCell? = nil) {
        
        
        self.selectedIndex = index
        self.previousMarker = previousMarker
        self.currentMarker = currentMarker
        
        
        centerMapOnLocation(CLLocation(latitude: currentMarker.position.latitude, longitude: currentMarker.position.longitude), mapView: mapView, zoom: 18)
        
        if let cell = cell {
            
            for visibleCell in collectionView.visibleCells {
                let vCell = visibleCell as! HomeBikeCollectionViewCell
                if vCell == cell {
                    vCell.buttonContentView.backgroundColor = .mimoYellow500
                } else {
                    vCell.buttonContentView.backgroundColor = .mimoBlackWith025alpha
                }
            }
        } else if scooterCell == scooterCell {
            for visibleCell in collectionView.visibleCells {
                //                let vCell = visibleCell as! HomeScooterCollectionViewCell
                //                if vCell == cell {
                //                    vCell.buttonContentView.backgroundColor = .mimoYellow500
                //                } else {
                //                    vCell.buttonContentView.backgroundColor = .mimoBlackWith025alpha
                //                }
            }
        }
    }
    
    func updateMultypleScoterSelect(currentIndex: Int) {
        switch currentIndex {
        case 0:
            scooter1CoontentView.layer.borderColor = UIColor.black.cgColor
            scooter1CoontentView.layer.borderWidth = 1.0
            scooter2CoontentView.layer.borderColor = UIColor.black.cgColor
            scooter2CoontentView.layer.borderWidth = 0.0
            scooter3CoontentView.layer.borderColor = UIColor.black.cgColor
            scooter3CoontentView.layer.borderWidth = 0.0
        case 1:
            scooter1CoontentView.layer.borderColor = UIColor.black.cgColor
            scooter1CoontentView.layer.borderWidth = 0.0
            scooter2CoontentView.layer.borderColor = UIColor.black.cgColor
            scooter2CoontentView.layer.borderWidth = 1.0
            scooter3CoontentView.layer.borderColor = UIColor.black.cgColor
            scooter3CoontentView.layer.borderWidth = 0.0
        case 2:
            scooter1CoontentView.layer.borderColor = UIColor.black.cgColor
            scooter1CoontentView.layer.borderWidth = 0.0
            scooter2CoontentView.layer.borderColor = UIColor.black.cgColor
            scooter2CoontentView.layer.borderWidth = 0.0
            scooter3CoontentView.layer.borderColor = UIColor.black.cgColor
            scooter3CoontentView.layer.borderWidth = 1.0
        default: break
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let currentIndex = Int(scrollView.contentOffset.x / view.frame.width)
        print("currentIndex =  \(currentIndex)")
        if scrollView.tag == 999 {
            print("groupScooterGroupScrollView scrolled")
            currectScuterId = self.currentScooterStateModelList?[currentIndex].data?.id ?? ""
            self.updateMultypleScoterSelect(currentIndex: currentIndex)
            DispatchQueue.main.async {
                if let curScooter = self.currentScooterStateModelList?[currentIndex] {
                    let zoomOut = GMSCameraUpdate.zoom(to: 16)
                    self.mapView.animate(with: zoomOut)
                    let vancouver = CLLocationCoordinate2D(latitude: curScooter.scooter?.located?.latitude ?? 0.0, longitude: curScooter.scooter?.located?.longitude ?? 0.0)
                    let vancouverCam = GMSCameraUpdate.setTarget(vancouver)
                    self.mapView.animate(with: vancouverCam)
                }
            }
            
            self.currentScooterTrip = self.scooterTripList?[currentIndex]
            
            return
        }
        let visibleIndexPath = collectionView.getCurrentVisibleCellIndexPath()
        if self.bikeState == .bike {
            let cell = collectionView.cellForItem(at: visibleIndexPath) as!
            HomeBikeCollectionViewCell
            guard let markerId = cell.bikeResult?.id,
                  let marker = markers[markerId]
            else { return }
            
            self.makeSelectedMarker(previousMarker: self.currentMarker, currentMarker: marker, index: visibleIndexPath, cell: cell)
        } else {
            let cell = collectionView.cellForItem(at: visibleIndexPath) as!
            HomeScooterCollectionViewCell
            guard let markerId = cell.scoterResult?.id,
                  let marker = markers[markerId]
            else { return }
            
            self.makeSelectedMarker(previousMarker: self.currentMarker, currentMarker: marker, index: visibleIndexPath, cell: nil)
        }
        
    }
}

enum VersionError: Error {
    case invalidResponse, invalidBundleInfo
}

// MARK: - HomeScanQrSheetViewController Delegate

extension HomeViewController: HomeScanQrSheetViewControllerDelegate {
    
    func openShowDebt(amount: Double, wallets: [WalletDebts]) {
        self.showDebtVc = ShowDebtViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
        self.showDebtVc?.modalPresentationStyle = .fullScreen
        self.showDebtVc?.view.backgroundColor = .white
        self.showDebtVc?.updateUI(amount: amount, wallets: wallets)
        self.showDebtVc?.delegate = self
        self.present(self.showDebtVc!, animated: true)
    }
    
    
    func closedWalletPage() {
        print("home screen HomeScanQrSheetViewControllerDelegate closed")
    }
    
    func didSelectCollection(state: HomeScanQrSheetViewController.CollectionModel) {
        VibrateManager.vibrate()
        switch state {
            case .rates:
                
                let planController = MIPlansViewController.initFromStoryboard(name: "MIPlan")
                let navigation = UINavigationController(rootViewController: planController)
                
                let backButton = UIBarButtonItem(image: UIImage(named: "ic_back"), style: .done, target: navigation, action: #selector(dismiss(animated:completion:)))
                navigation.navigationItem.leftBarButtonItem = backButton
                present(navigation, animated: true, completion: nil)
                
            case .support:
                let supportController = SupportNavigationViewController.initFromStoryboard(name: Constant.Storyboards.accountCover)
                present(supportController, animated: true, completion: nil)
            case .trips:
                let tripsListViewController = TripsNavigationController.initFromStoryboard(name: Constant.Storyboards.wallet)
//                self.tripNavigationController = UINavigationController(rootViewController: tripsListViewController)
//
//                if #available(iOS 13, *) {
//                    self.tripNavigationController?.navigationBar.standardAppearance = UINavigationBarAppearance()
//                    self.tripNavigationController?.navigationBar.standardAppearance.configureWithDefaultBackground()
//                    self.tripNavigationController?.navigationBar.barTintColor = .white
//                }
//                else {
//                    self.tripNavigationController?.navigationBar.barTintColor = .white
//                }
//                let backButton = UIBarButtonItem(image: #imageLiteral(resourceName: "ic_arrow_left"), style: .plain, target: self, action: #selector(backButtonTapped))
//                tripsListViewController.navigationItem.leftBarButtonItem = backButton
                self.present(tripsListViewController, animated: true, completion: nil)
        }
    }
    
    @objc func backButtonTapped() {
        self.tripNavigationController?.dismiss(animated: true, completion: nil)
    }
    
    func didTappedButton(state: HomeScanQrSheetButtonsState, isShowList isShowlist: Bool = false) {
        switch state {
        case .scanQR:
            var statusMessage = ""
            BLEManager.shareInstance.checkBluetoothConnectionState = { [weak self] state in
                guard let self = self else { return }
                switch state {
                case .poweredOn:
                    statusMessage = "Bluetooth Status: Turned On"
                    self.presentScanVC()
                case .poweredOff:
                    statusMessage = "Bluetooth Status: Turned Off"
                    self.openAppOrSystemSettingsAlert(title: "MimoBike would like to use Bluetooth for new conection", message: "You can allow connection in Settings")
                case .resetting:
                    statusMessage = "Bluetooth Status: Resetting"
                    self.openAppOrSystemSettingsAlert(title: "MimoBike would like to use Bluetooth for new conection", message: "You can allow connection in Settings")
                case .unauthorized:
                    statusMessage = "Bluetooth Status: Not Authorized"
                    self.openAppOrSystemSettingsAlert(title: "MimoBike would like to use Bluetooth for new conection", message: "You can allow connection in Settings")
                case .unsupported:
                    statusMessage = "Bluetooth Status: Not Supported"
                    self.openAppOrSystemSettingsAlert(title: "MimoBike would like to use Bluetooth for new conection", message: "You can allow connection in Settings")
                case .unknown:
                    statusMessage = "Bluetooth Status: Unknown"
                    self.openAppOrSystemSettingsAlert(title: "MimoBike would like to use Bluetooth for new conection", message: "You can allow connection in Settings")
                }
                
                print(statusMessage)
                
                if state == .poweredOff {
                    //TODO: Update this property in an App Manager class
                    
                }
            }
            BLEManager.shareInstance.configBLE()
            
        case .bike:
            
            self.bikeState = .bike
            self.mapView.clear()
            self.getBikes()
            if !isShowlist {
                bottomSheet?.attemptDismiss(animated: true)
                updateControllerState(state: .previewBikes(reloadData: true))
            }
            //            if let mapZone = self.mapZone {
            //                DrawPolygone.shared.drawZone(mapZone: mapZone, mapView: self.mapView)
            //            }
        case .scooter:
            self.bikeState = .scooter
            self.mapView.clear()
            self.getScooters()
            self.drawParkings()
            if !isShowlist {
                bottomSheet?.attemptDismiss(animated: true)
                updateControllerState(state: .previewScooters(reloadData: true))
            }
            if let mapZone = self.mapZone {
                DrawPolygone.shared.drawZone(mapZone: mapZone, mapView: self.mapView)
            }
        }
    }
    
    func openAppOrSystemSettingsAlert(title: String, message: String) {
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}


// MARK: - HomeSingleBikeViewController Delegate

extension HomeViewController: HomeSingleBikeViewControllerDelegate {
    func didSelectBookNow(singleBike: HomeSingleBikeViewController) {
        VibrateManager.vibrate()
        guard let bookId = singleBike.bikeResult?.id,
              let latitude = singleBike.bikeResult?.latitude,
              let longitude = singleBike.bikeResult?.longitude else { return }
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        bookBike(bookID: bookId, location: location, qr: singleBike.bikeResult?.qr ?? "") {[weak self] result in
            if case .success = result {
                self?.singleBikeBookNowTapped = true
            }
        }
    }
    
    
    func bookBike(bookID: String, location: CLLocationCoordinate2D, qr: String, completion: ((Result<(),Error>)->())? = nil) {
        self.homeViewModel.bookBike(bookId: bookID,
                                    location: location) { [weak self] (result) in
            guard let unwrapSelf = self else { return }
            switch result {
            case .success:
                completion?(.success(()))
                unwrapSelf.bookedDevice = BookedDeviceModel(startDate: 300, id: bookID, location: location)
                unwrapSelf.listenStateUpdate()
                unwrapSelf.updateControllerState(state: .bookedBike)
                unwrapSelf.setupBookTimer(time: unwrapSelf.bookedDevice!.startDate)
                unwrapSelf.timerManager?.startTimer()
                unwrapSelf.bookedBikeQRLabel?.text = qr
//                BikeResult.getLocationName(location: location, long: false, completed: { value in
//                    unwrapSelf.bookedBikeAddressLabel?.text = value
//                })
                
                unwrapSelf.markers.map { $1 }.forEach { (marker) in
                    if marker != unwrapSelf.currentMarker {
                        marker.map = nil
                    } else {
                        marker.map = unwrapSelf.mapView
                    }
                }
            case .failure(let error):
                completion?(.failure(error))
                UIAlertController.showError(message: error.message.localized())
            }
        }
    }
    
    func listenStateUpdate() {
        if isListeningStateUpdate {
            return
        }
        
        guard let phoneNumber = StorageManager().fetch(key: .phoneNumber, type: String.self) else {
            return
        }
        
        isListeningStateUpdate = true
        SocketService.shared.listenTripUpdate(phoneNumber: phoneNumber) {[weak self] (result) in
            switch result {
            case .success(let result):
                guard let self = self, !self.bottomSheetOpened else { return }
                switch result.action {
                case .TripEnded:
                    UserManager.share.isHaveBikeTrip = false
                    self.removeScannedBike()
                    self.stopTrip()
                case .TripStarted:
                    UserManager.share.isHaveBikeTrip = true
                    let bike = BikeResult(id: result.bikeDto?.id ?? "", qr: result.bikeDto?.qr ?? "", mac: result.bikeDto?.mac ?? "", voltage: result.bikeDto?.voltage ?? 0, longitude: result.bikeDto?.longitude ?? 0, latitude: result.bikeDto?.latitude ?? 0, updated: true)
                    self.updateMarker(model: bike, isUpdateBike: true)
                    self.updateControllerState(state: .scan(bike: result))
                default:
                    break
                }
                break
                
            case .failure(let error):
                print("error = \(error)")
//                UIAlertController.showError(message: error.localizedDescription)
            }
        }
    }
    
    func stateBookedBike(bikeID: String, reminedTime: TimeInterval, location: CLLocationCoordinate2D) {
        bookedDevice = BookedDeviceModel(startDate: reminedTime, id: bikeID, location: location)
    }
    
    func stateScanBike(trip: TripActionModel, time: Double) {
        self.tripTime = time
        self.trip = trip
    }
    
    func stateScanScooter(trips: [ScooterStateModel], time: Double) {
        self.currentScooterStateModelList = trips
        for trip in trips {
            let data = trip.data?.start ?? 0
            var stringDate = String(data)
            stringDate.removeLast(3)
            let dd = Int(data / 1000)
            let dataStarted = abs(Date().timeIntervalSince1970 - Double(dd))
            
            self.tripTime = time
            self.currentScooterStateModel = trip
            if trip.state == .TripPaused {
                if self.pauseVC == nil {
                    self.viewForBlur.isHidden = false
                    self.pauseVC = PauseViewController.initFromStoryboard(name: Constant.Storyboards.scooterPlan)
                }
                self.pauseVC?.delegate = self
                self.addChild(self.pauseVC!)
                guard let startTime = trip.data?.pauses?.first(where: {$0.end == nil}) else { return }
                let dd = Int(startTime.start ?? 0) ?? 0
                let dataStarted = abs(Date().timeIntervalSince1970 - Double(dd) / 1000)
                self.pauseVC?.pausStarted = dataStarted
                
                self.pauseVC!.view.frame = self.view.bounds
                self.view.addSubview(self.pauseVC!.view)
                self.pauseVC!.didMove(toParent: self)
                self.pauseVC!.view.backgroundColor = .black.withAlphaComponent(0.3)
                self.pauseVC?.pausStarted = dataStarted
                self.pauseVC!.updateTime()
                self.currentScooterTrip?.view.backgroundColor = .white
                self.currentScooterTrip?.blureViewe.backgroundColor = .black.withAlphaComponent(0.1)
                self.currentScooterTrip?.blureViewe.isHidden = false
                self.currentScooterTrip?.updateDurationData()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            if self.multyScooterSStackView != nil {
                self.updateControllerState(state: .scanScooter(scooter: trips))
            }
        })
    }
}

// MARK: - HomeSingleScooterViewController Delegate

extension HomeViewController: HomeSingleScooterViewControllerDelegate {
    func didSelectStartRide(singleScooter: HomeSingleScooterViewController) {
        VibrateManager.vibrate()
        updateControllerState(state: .previewScooters(reloadData: true))
    }
    
    func didSelectBookNow(singleScooter: HomeSingleScooterViewController) {
        VibrateManager.vibrate()
        guard let bookId = singleScooter.scooterResult?.id,
              let latitude = singleScooter.scooterResult?.latitude,
              let longitude = singleScooter.scooterResult?.longitude else { return }
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        bookScooter(bookID: bookId, location: location, qr: singleScooter.scooterResult?.qr ?? "") {[weak self] result in
            guard let  self = self else { return }
            if case .success = result {
                self.singleScooterBookNowTapped = true
                self.scooterBookedTimerView.isHidden = false
                self.bookedScooterAddresLbl.text = "MAX PLUSE"
                
//                singleScooter.scooterResult?.getLocationName(long: true, completed: { [weak self] location in
//                    guard let  self = self else { return }
//                    self.bookedScooterAdr.text = location
//                })
                
                let range = Double(singleScooter.scooterResult?.remainingMileage ?? 0) / 1000
                let timeInMinutes = range / 20 * 60 // default speed is 20km/h
                let formattedTime = self.secondsToHoursMinutes(Int(timeInMinutes))
                self.bookedScootertripLenghtLbl.text = "≈\(timeInMinutes > 60 ? "\(formattedTime.0)h \(formattedTime.1)min" : "\(formattedTime.1)min") (\(range)km range)"
                self.bookedScooterBatteryPersentLbl.text = "\(singleScooter.scooterResult?.batteryPercent ?? 0)%"
                self.setupScooterTimer(time: 0, view: (self.bookedScooterTimeLbl)!)
                self.setImage(batteryPercent: Double(singleScooter.scooterResult?.batteryPercent ?? 0))
            }
        }
    }
    
    private func secondsToHoursMinutes(_ minutes: Int) -> (hours: Int, minutes: Int) {
        return (minutes / 60, minutes % 60)
    }
    
    func setImage(batteryPercent: Double) {
        switch batteryPercent  {
        case 0...20:
            self.bookedScooterBatteryIcon.image = UIImage(named: "ic_battery_H_0")
        case 21...40:
            self.bookedScooterBatteryIcon.image = UIImage(named: "ic_battery_H_25")
        case 41...60:
            self.bookedScooterBatteryIcon.image = UIImage(named: "ic_battery_H_50")
        case 61...80:
            self.bookedScooterBatteryIcon.image = UIImage(named: "ic_battery_H_75")
        case 81...100:
            self.bookedScooterBatteryIcon.image = UIImage(named: "ic_battery_H_100")
        default: break
        }
    }
    
    /*
     
     
     self.scooterNameLabel.text = "MAX PLUSE" //scoterResult?.type ?? ""
     let range = Double(scoterResult?.remainingMileage ?? 0) / 1000
     let timeInMinutes = range / 20 * 60 // default speed is 20km/h
     let formattedTime = secondsToHoursMinutes(Int(timeInMinutes))
     self.rangeLabel.text = "≈\(timeInMinutes > 60 ? "\(formattedTime.0)h \(formattedTime.1)min" : "\(formattedTime.1)min") (\(range)km range)"
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
     */
    func bookScooter(bookID: String, location: CLLocationCoordinate2D, qr: String, completion: ((Result<(),Error>)->())? = nil) {
        self.homeViewModel.bookScooter(bookId: bookID,
                                       location: location) { [weak self] (result) in
            guard let unwrapSelf = self else { return }
            switch result {
            case .success(let bookedScooterResult):
                completion?(.success(()))
                var bookedDevice = BookedDeviceModel(startDate: 300, id: bookID, location: location)
                bookedDevice.bookedId = bookedScooterResult.id
                unwrapSelf.bookedDevice = bookedDevice
                unwrapSelf.listenStateUpdate()
                unwrapSelf.updateControllerState(state: .bookedScooter)
                unwrapSelf.setupScooterTimer(time: unwrapSelf.bookedDevice!.startDate, view: unwrapSelf.bookedBikeTimeLabel)
                unwrapSelf.timerManager?.startTimer()
                unwrapSelf.bookedBikeQRLabel?.text = qr
//                BikeResult.getLocationName(location: location, long: false, completed: { value in
//                    unwrapSelf.bookedBikeAddressLabel?.text = value
//                })
                unwrapSelf.collectionView.reloadData()
                unwrapSelf.markers.map { $1 }.forEach { (marker) in
                    if marker != unwrapSelf.currentMarker {
                        marker.map = nil
                    } else {
                        marker.map = unwrapSelf.mapView
                    }
                }
            case .failure(let error):
                completion?(.failure(error))
                UIAlertController.showError(message: error.message.localized())
            }
        }
    }
    
    //    func listenStateUpdate() {
    //        if isListeningStateUpdate {
    //            return
    //        }
    //
    //        guard let phoneNumber = StorageManager().fetch(key: .phoneNumber, type: String.self) else {
    //            return
    //        }
    //
    //        isListeningStateUpdate = true
    //        SocketService.shared.listenTripUpdate(phoneNumber: phoneNumber) {[weak self] (result) in
    //            switch result {
    //            case .success(let result):
    //                guard let self = self, !self.bottomSheetOpened else { return }
    //                switch result.action {
    //                case .TripEnded:
    //                    self.removeScannedBike()
    //                    self.stopTrip()
    //                case .TripStarted:
    //                    self.updateMarker(model: BikeResult(id: result.bikeDto?.id ?? "", qr: result.bikeDto?.qr ?? "", mac: result.bikeDto?.mac ?? "", voltage: result.bikeDto?.voltage ?? 0, longitude: result.bikeDto?.longitude ?? 0, latitude: result.bikeDto?.latitude ?? 0, updated: true), isUpdateBike: true)
    //                default:
    //                    break
    //                }
    //                break
    //
    //            case .failure(let error):
    //                UIAlertController.showError(message: error.localizedDescription)
    //            }
    //        }
    //    }
    //
    //    func stateBookedBike(bikeID: String, reminedTime: TimeInterval, location: CLLocationCoordinate2D) {
    //        bookedBike = BookedBikeModel(startDate: reminedTime, bikeID: bikeID, location: location)
    //    }
    //
    //    func stateScanBike(trip: TripActionModel, time: Double) {
    //        self.tripTime = time
    //        self.trip = trip
    //    }
}


// MARK: - HomeBikeCollectionViewCell Delegate

extension HomeViewController: HomeBikeCollectionViewCellDelegate {
    func didJoinButtonTapped(cell: HomeBikeCollectionViewCell) {
        
        guard let bookId = cell.bikeResult?.id,
              let latitude = cell.bikeResult?.latitude,
              let longitude = cell.bikeResult?.longitude else { return }
        
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        self.bookBike(bookID: bookId, location: location, qr: cell.bikeResult?.qr ?? "")
    }
}

// MARK: - HomeScooterCollectionViewCell Delegate

extension HomeViewController: HomeScooterCollectionViewCellDelegate {
    
    func didBookNowButtonTapped(cell: HomeScooterCollectionViewCell) {
        if bookedDevice != nil {
            guard let bookedScooterID = bookedDevice?.bookedId else {
                return
            }
            homeViewModel.cancelScooterBook(bikeID: bookedScooterID) {[weak self] result in
                guard let self = self else { return }
                if case .failure(let message) = result {
                    UIAlertController.showError(message: message.localizedDescription)
                } else {
                    self.removeBookedScooterMarker()
                    self.markers.map { $1 }.forEach { $0.map = self.mapView }
                    self.updateControllerState(state: .previewScooters(reloadData: true))
                    self.singleScooterBookNowTapped = false
                    self.timerManager?.stopTimer()
                    self.bookedDevice = nil
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        } else {
            guard let bookId = cell.scoterResult?.id,
                  let latitude = cell.scoterResult?.latitude,
                  let longitude = cell.scoterResult?.longitude else { return }
            
            let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            self.bookScooter(bookID: bookId, location: location, qr: cell.scoterResult?.qr ?? "")
        }
    }
    
    func didTakeScooterButtonTapped(cell: HomeScooterCollectionViewCell) {
        
    }
}



// MARK: - -

extension HomeViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didChange cameraPosition: GMSCameraPosition) {
        let newZoomLevel = cameraPosition.zoom
        if currentZoomLevel != newZoomLevel {
            currentZoomLevel = newZoomLevel
            // Perform actions based on the new zoom level here
            //            print("currentZoomLevel = \(currentZoomLevel)")
            //            DispatchQueue.main.async {
            //                for item in self.parkingMarkers {
            //                    switch self.currentZoomLevel {
            //                    case 0...19:
            //                        item.icon = UIImage(named: "parking_nim")
            //                    case 19...:
            //                        item.icon = UIImage(named: "parking")
            //                    default:
            //                        item.icon = nil
            //                    }
            //                }
            //            }
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("tappedcooordinate = \(coordinate)")
        
        let clickedZone = DrawPolygone.shared.whichZoneClicked(coordinate: coordinate)
        switch clickedZone {
        case "RIDE":
            self.openZoneInfo(zoneId: "RIDE")
        case "FORBIDDEN":
            self.openZoneInfo(zoneId: "FORBIDDEN")
        case "RESTRICTED":
            self.openZoneInfo(zoneId: "RESTRICTED")
        case "OUT":
            self.openZoneInfo(zoneId: "FORBIDDEN")
        default: break
        }
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        drawParkings()
    }
    
    func openParkingInfo() {
        parkingInfo = self.storyboard?.instantiateViewController(withIdentifier: "ParkingDetailsViewController") as? ParkingDetailsViewController
        parkingInfo?.view.backgroundColor = .black.withAlphaComponent(0.3)
        parkingInfo?.view.frame = self.view.bounds
        
//        parkingInfo?.delegate = self
        self.view.addSubview((parkingInfo?.view)!)
    }
    
    func clseParkingInfo() {
        parkingInfo?.view.removeFromSuperview()
        parkingInfo = nil
    }
    
    func didTapOK() {
        clseParkingInfo()
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if ((marker.title?.hasPrefix("Parking")) != nil)
        {
            print("Parking clicked")
            openParkingInfo()
            return false
        }
        guard marker != self.scannedBikeMarker else { return false }
        if isHaveActiveTrip { return false}
        if bikesContentView.isHidden {
            
            
            //            markers.map { $1 }.filter { $0 != marker }.forEach { $0.map = nil }
            if self.bikeState == .bike {
                let cellIndex = bikes.firstIndex(where: { $0.latitude == marker.position.latitude && $0.longitude == marker.position.longitude }) ?? 0
                
                makeSelectedMarker(previousMarker: currentMarker, currentMarker: marker, index: IndexPath(item: cellIndex, section: 0))
                previewBike(result: self.bikes[cellIndex])
            } else {
                let cellIndex = scooters.firstIndex(where: { $0.latitude == marker.position.latitude && $0.longitude == marker.position.longitude }) ?? 0
                
                makeSelectedMarker(previousMarker: currentMarker, currentMarker: marker, index: IndexPath(item: cellIndex, section: 0))
                previewScooter(result: self.scooters[cellIndex])
            }
            
            centerMapOnLocation(CLLocation(latitude: marker.position.latitude, longitude: marker.position.longitude), mapView: mapView, zoom: 15)
        } else {
            if self.bikeState == .bike {
                let cellIndex = bikes.firstIndex(where: { $0.latitude == marker.position.latitude && $0.longitude == marker.position.longitude }) ?? 0
                let cellIndexPath = IndexPath(item: cellIndex, section: 0)
                
                self.collectionView.scrollToItem(at: cellIndexPath, at: .centeredHorizontally, animated: true)
                let cell = self.collectionView(collectionView, cellForItemAt: cellIndexPath) as! HomeBikeCollectionViewCell
                
                self.makeSelectedMarker(previousMarker: self.currentMarker, currentMarker: marker, index: cellIndexPath, cell: cell)
                previewBike(result: self.bikes[cellIndex])
            } else {
                let cellIndex = scooters.firstIndex(where: { $0.latitude == marker.position.latitude && $0.longitude == marker.position.longitude }) ?? 0
                let cellIndexPath = IndexPath(item: cellIndex, section: 0)
                
                self.collectionView.scrollToItem(at: cellIndexPath, at: .centeredHorizontally, animated: true)
                let cell = self.collectionView(collectionView, cellForItemAt: cellIndexPath) as! HomeScooterCollectionViewCell
                
                self.makeSelectedMarker(previousMarker: self.currentMarker, currentMarker: marker, index: cellIndexPath, cell: nil, scooterCell: cell)
                previewScooter(result: self.scooters[cellIndex])
            }
        }
        
        return true
    }
    
    private func stopTrip() {
        splashViewModel.getFinansialState { result in
            switch result {
            case .success(let state):
                if state.state != UserManager.share.debtState?.state {
                    UserManager.share.debtState = state
                    NotificationCenter.default.post(name: Constant.Notifications.updateFinansialState, object: nil)
                }
            case .failure(let error):
                UIAlertController.showError(message: error.message.localized())
            }
        }
        
        if self.presentedViewController is UIAlertController {
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        self.removeScannedBike()
        self.markers.map { $1 }.forEach { $0.map = self.mapView }
        self.updateControllerState(state: .smallBottomSheet)
        self.timerManager?.stopTimer()
        self.trip = nil
    }
    
    private func changeLockState(state: Bool) {
        guard let bikeId = self.trip?.bikeDto?.id else {
            debugPrint("Bike id is nil")
            return
        }
        self.homeViewModel.changeBlockState(state: state, bikeId: bikeId) { [weak self] (result) in
            guard let self = self else { return }
            self.dismiss(animated: true)
            self.updateRideState()
        }
    }
}


// MARK: - BLEManagerDelegate -

extension HomeViewController: BLEManagerDelegate {
    
    func changeBleState(bleState: BleDeviceState) {
        switch bleState {
        case .locked:
            //self.stopTrip()
            print("GET STATE FROM LOCK BIKE BLE")
            self.perform(#selector(updateRideState), with: nil, afterDelay: 3)
            BLEManager.shareInstance.dinsconnect()
        case .unLocked:
            print("GET STATE FROM UNLOCK BIKE BLE")
            self.perform(#selector(updateRideState), with: nil, afterDelay: 3)
            
            break
        case .connectionLost:
            if case .scan = self.state {
                sendNotification()
            }
        }
        self.perform(#selector(updateRideState), with: nil, afterDelay: 3)
    }
    
    private func sendNotification() {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Mimo"
        notificationContent.body = "Test body"
        notificationContent.sound = UNNotificationSound.defaultCritical
        
        if let url = Bundle.main.url(forResource: "dune", withExtension: "png") {
            if let attachment = try? UNNotificationAttachment(identifier: "dune", url: url) {
                notificationContent.attachments = [attachment]
            }
        }
        let request = UNNotificationRequest(identifier: "testNotification", content: notificationContent, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

extension HomeViewController: TimerManagerDelegate {
    func didChanchTimeSeconds(seconds: Double) {
        
    }
    
    
    func didExpireDuration(timer: TimerManager) {
        
        if timer === timerManager {
            self.markers.map { $1 }.forEach { $0.map = self.mapView }
            self.updateControllerState(state: .previewBikes(reloadData: true))
            self.singleBikeBookNowTapped = false
            self.timerManager?.stopTimer()
            self.bookedDevice = nil
        }
        
    }
}

extension HomeViewController: TestDelegate {
    func updateHomeControllerState(scooter: ScooterStateModel) {
        if scooter.state == .TripStarted || scooter.state == .TripScanned {
            self.updateControllerState(state: .scanScooter(scooter: [scooter]))
        } else {
            self.updateControllerState(state: .smallBottomSheet)
        }
    }
}
