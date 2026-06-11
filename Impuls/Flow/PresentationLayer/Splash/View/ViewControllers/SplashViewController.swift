//
//  SplashViewController.swift
//  MimoBike
//
//  Created by Vardan on 15.04.21.
//

import UIKit
import Lottie
import CoreLocation
import libPhoneNumber_iOS

final class SplashViewController: UIViewController, StoryboardInitializable {
    
    @IBOutlet weak var viewForGradient: UIView!
    //MARK: - IBOutlets

    
    @IBOutlet weak var logoLottieView: LottieAnimationView!
    
    //MARK: - Variables
    
    private let splashViewModel = SplashViewModel()
    private var languages = [LanguageResult]()
    private var isUserSignIn = false
    private var isAccountComplete = true
    
    var isTranslationsGot = false
    
    lazy var homeViewController: HomeViewController = {
        let homeVC = HomeViewController.initFromStoryboard(name: Constant.Storyboards.home)
        homeVC.state = self.isAccountComplete ? .accountDone : .accountNotComplete
        return homeVC
    }()
    
    //MARK: - life cycles
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIsUserSignIn()
        configureUI()
        checkIsAccountComplete()
        NotificationCenter.default.addObserver(self , selector: #selector(navigateToLogin), name: NSNotification.Name(rawValue: "navigateToLoginScreen"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(translationsGot), name: NSNotification.Name(rawValue: "translationsGot"), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.addGradientAnimation(viewForGradient)
    }
    
    @objc func navigateToLogin() {
        if isTranslationsGot {
            self.goToWelcomeToMimoVC()
        }
    }
    
    @objc func translationsGot() {
        isTranslationsGot = true
    }
    
    private func getTranslation() {
        
    }
    
    //MARK: - Methods
    
    /// Configure screen UI
    @objc private func configureUI() {
        logoLottieView.animation = .named(Constant.Lottie.logo)
        logoLottieView.loopMode = .loop
        self.playLogoAnimation()
        getTranslation()

        guard isUserSignIn else {
            splashViewModel.getTranslations { [weak self] _ in
                guard let self = self else { return }
                
            }
            self.perform(#selector(self.goToNextScreen), with: nil, afterDelay: 5)
            // Commented because logout stuck in this page
//            self.splashViewModel.socketConnected { [weak self] (result) in
//                self?.splashViewModel.getGlobalSettings(completion: { result in
//                    switch result {
//                    case .success:
//                        self?.playLogoAnimationOnce()
//                    case .failure(let error):
//                        UIAlertController.showError(message: error.message)
//                    }
//                })
//            }
            
            return
        }
        
        self.splashViewModel.getTranslations { [weak self] (result) in
            switch result {
            case .success:
//                self?.splashViewModel.socketConnected { [weak self] (result) in
//
//                }
                
                self?.splashViewModel.getLanguages(completion: { _ in
                    
                })
                self?.splashViewModel.getGlobalSettings { status in
                    switch status {
                    case .success:
                        self?.splashViewModel.getFinansialState(completion: { (result) in
                            switch result {
                                case .success(let state):
                                    UserManager.share.debtState = state
                                    UserManager.share.debtAmount = state.additional
                                    UserManager.share.debtWallets = state.wallets
                                if let state = (UserDefaults.standard.value(forKey: "BikeState") as? String), state == "scooter" {
                                    self?.getScooterState()
                                } else {
                                    self?.getBikeState()
                                }
                                case .failure(let error):
                                    print(error)
                            }
                        })
                    case .failure(let error):
                        UIAlertController.showError(message: error.message.localized())
                    }
                }
            case .failure:
                return
            }
        }
    }
    
    func getScooterState()  {
        
        self.splashViewModel.getScooterState(completion: { [weak self] (result) in
            guard let self = self else { return }
            
            switch result {
            case .success(let model):
                
                print("Scooter GetState = \(model)")
                self.playLogoAnimationOnce()
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
        } else {
            
            if let data = trip_Started_List.first?.data?.start {
                var stringDate = String(data)
                stringDate.removeLast(3)
                let dd = Int(data / 1000)
                let dataStarted = abs(Date().timeIntervalSince1970 - Double(dd))
                
                // TODO: change for scooter
                self.homeViewController.stateScanScooter(trips: trip_Started_List, time: dataStarted)
            }
        }
        
        if booking_Started_List.count > 0 {
            if let bookID = booking_Started_List.first?.scooter?.id,
               let latitude = booking_Started_List.first?.scooter?.located?.latitude,
               let longitude = booking_Started_List.first?.scooter?.located?.longitude,
               let data = booking_Started_List.first?.data?.start {
                
                let dataStarted = 300 - abs(Date().timeIntervalSince1970 - Double(Int(data) ?? 0) / 1000)
                // TODO: change for scooter
                self.homeViewController.view.backgroundColor = .white
                self.homeViewController.tripTime = dataStarted
                self.homeViewController.updateControllerState(state: .bookedScooter)
                self.homeViewController.stateBookedBike(bikeID: bookID, reminedTime: dataStarted, location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
            }
        }
        
        if trip_Paused_List.count >  0 {
            
            if let data = trip_Paused_List.first?.data?.start {
                var stringDate = String(data)
                stringDate.removeLast(3)
                let dd = Int(data)
                let dataStarted = abs((Date().timeIntervalSince1970 - Double(dd)) / 1000)
                // TODO: change for scooter
                self.homeViewController.view.backgroundColor = .white
                //TODO: need to chenge time coounting
                self.homeViewController.stateScanScooter(trips: trip_Paused_List, time: dataStarted + self.getPausedTime(pauses: trip_Paused_List.first?.data?.pauses))
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
    
    func getBikeState()  {
        self.splashViewModel.getState(completion: { (result) in
           
            switch result {
            case .success(let model):
                
                print("Bike State  = \(model)")
                if model.action != .TripStarted {
//                    self.splashViewModel.getFinansialState(completion: { result in
//                        self.playLogoAnimationOnce()
//
//                        switch result {
//                        case .success(let state):
//                            UserManager.share.debtState = state
//                            UserManager.share.debtAmount = state.additional
//                        case .failure(let error):
//                            UIAlertController.showError(message: error.message.localized())
//                        }
//                    })
                }
                switch model.action {
                case .Booking_Started:
                    if let bookID = model.bikeDto?.id, let latitude = model.bikeDto?.latitude, let longitude = model.bikeDto?.longitude, let data = model.data?.start {
                        var stringDate = String(data)
                        stringDate.removeLast(3)
                        let dataStarted = 300 - abs(Date().timeIntervalSince1970 - Double(Int(stringDate) ?? 0))
                        self.homeViewController.stateBookedBike(bikeID: bookID, reminedTime: dataStarted, location: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
                    }
                case .BookingEnded:
                    print("BookingEnded")
                case .TripStarted:
                    self.playLogoAnimationOnce()

                    if let data = model.data?.start, let id = model.bikeDto?.id, let mac = model.bikeDto?.mac {
                        var stringDate = String(data)
                        stringDate.removeLast(3)
                        let dataStarted = abs(Date().timeIntervalSince1970 - Double(Int(stringDate) ?? 0))
                        BLEManager.shareInstance.scan(for: mac, bikeID: id, workOption: BLEOption(afterConnectOption: BLEOption.AfterConnect(unlockDevice: false, updateDeviceState: true)))
                        self.homeViewController.stateScanBike(trip: model, time: dataStarted)
                    }
                case .TripEnded:
                    print("TripEnded")
                    self.playLogoAnimationOnce()
                default:
                    print("Dont have active trip")
                    self.playLogoAnimationOnce()
                }
            
            case .failure(let error):
                print("Bike State failed = \(error)")
                UIAlertController.showError(message: error.message.localized())
                
            }
            return
        })
    }
    private func playLogoAnimation() {
        self.logoLottieView.play(fromProgress: self.logoLottieView.currentProgress, toProgress: 1, loopMode: .loop)
    }
    
    private func playLogoAnimationOnce() {
        print("==== start playLogoAnimationOnce")
            self.logoLottieView.play(fromProgress: self.logoLottieView.currentProgress, toProgress: 1, loopMode: .playOnce) { [weak self] (_) in
                guard let self = self else { return }
                print("== playLogoAnimationOnce ==")
                
            }
        self.perform(#selector(self.goToNextScreen), with: nil, afterDelay: 5)
    }
    
    /// Check and go next screen
    @objc func goToNextScreen() {
        DispatchQueue.main.async {
            if self.isUserSignIn {
                self.goToHomeVC()
            } else {
                self.goToWelcomeToMimoVC()
            }
        }
    }
    
    /// Open home screen
    private func goToHomeVC() {
//        let navVC = UINavigationController(rootViewController: homeViewController)
//        self.setRootViewController(navVC)
        
//        HomeRouter.shared.showHomeViewController()
    }
    
    /// Open welcome to mimo screen
    private func goToWelcomeToMimoVC() {
        let welcomeToMimo = WelcomeToMimoViewController.initFromStoryboard(name: Constant.Storyboards.signIn)
        welcomeToMimo.languages = languages
        let navVC = UINavigationController(rootViewController: welcomeToMimo)
        goToNextVC(navVC)
    }
    
    /// Check user is loged in or not, and get languages if loged in
    private func checkIsUserSignIn() {
        self.isUserSignIn = splashViewModel.isUserSignIn()
        if !self.isUserSignIn {
            self.getLanguages()
        }
    }
    
    /// Check user is loged in or not, and get languages if loged in
    private func checkIsAccountComplete() {
        splashViewModel.isAccountComplete { [weak self] isAccountComplete in
            guard let self = self else { return }
            self.isAccountComplete = isAccountComplete
        }
    }
    
    /// Get languages for app
    private func getLanguages() {
        splashViewModel.getLanguages { [weak self] (result) in
            guard let self = self else { return }
            switch result {
            case .success(let languageResults):
                self.languages = languageResults
            case .failure(let error):
                print(error)
            }
        }
    }
}

extension String {

    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    func toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }

}

struct Country: Codable {
    var name : String = ""
    var dial_code: String = ""
    var code: String = ""
 }

extension String {

    func parseJSONStringToCountresList() -> [Country] {

        if let data = self.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            let decoder = JSONDecoder()
            let parsedData = try! decoder.decode([Country].self, from: data)
            return parsedData
        }
        return []
    }
}
