//
//  ThanksForTheRideViewController.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/28/22.
//

import UIKit

final public class ThanksForTheRideViewController: UIViewController, StoryboardInitializable {

    // MARK: Outlets
    @IBOutlet private weak var thanksTitleLabel: UILabel!
    @IBOutlet private weak var totalView: UIView!
    @IBOutlet private weak var totalTitleLabel: UILabel!
    @IBOutlet private weak var totalLabel: UILabel!
    @IBOutlet private weak var durationTitleLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var distanceTitleLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var pauseTitleLabel: UILabel!
    @IBOutlet private weak var pauseLabel: UILabel!
    @IBOutlet private weak var thankYouButton: UIButton!
    
    var scoterSoket = ScooterSocketService.shared
    var scooterScanResponse: ScooterScanResponse?
    var tripEndData: TripScooterSocketDataModel?
    
    var timerManager: TimerManager?
    
    // MARK: Vie Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()

            scoterSoket.connect { result in
                switch result {
                case .success:
                    print("scooter soket connected")
                case .failure(let error):
                    print("scoter coket error = \(error)")
                }
            }
            scoterSoket.scooterTrip = { data in
                print(data)
                if data.state == "TRIP_ENDED" {
                    self.updateUI(data: data)
                }
            }
        self.thankYouButton.layer.cornerRadius = self.thankYouButton.frame.height / 2
        self.perform(#selector(hideLoader), with: nil, afterDelay: 10)
        UserManager.share.isHaveScooterTrip = false
    }
    
    deinit {
        print("deinit - \(String(describing: self))")
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        self.thankYouButton.layer.cornerRadius = self.thankYouButton.frame.height / 2
//        MILoader.show()
    }
    
    @objc func hideLoader() {
        print("==== hideLoader =====")
        MILoader.hide()
    }
    
    func updateUI(data: TripScooterSocketDataModel) {
//        MILoader.hide()
        totalLabel.text = "\(data.data?.amount ?? 0.0) ֏"
        //durationLabel.text = "\(data.data?.start ?? 0)"
        distanceLabel.text = "\(Double(data.data?.distance ?? 0) / 1000) km"
        if let _data = data.data?.start {
//            var stringDate = String(_data / (60  * 60))
//            stringDate.removeLast(3)
            let dataStarted = abs(Date().timeIntervalSince1970 - Double(Int(_data) ) / 1000)
            print("duration = \(dataStarted)")
            setupScanTimer(time: dataStarted, data: data)
        }
        
        timerManager = TimerManager(timerLabel: pauseLabel, duration: getPausedTime(pauses: data.data?.pauses), formaterUnits: [.hour, .minute, .second], timerState: .increment)
        timerManager?.labelFont = UIFont(name: "Roboto-Bold", size: 18)!
        timerManager?.timerDurationColor = .mimoBlack
        timerManager?.delegate = self
        timerManager?.startTimer()
        timerManager?.stopTimer()
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
    
    func setupScanTimer(time: Double, data: TripScooterSocketDataModel) {
        let _time = time - getPausedTime(pauses: data.data?.pauses)
        
        timerManager = TimerManager(timerLabel: durationLabel, duration: _time, formaterUnits: [.hour, .minute, .second], timerState: .increment)
        timerManager?.labelFont = UIFont(name: "Roboto-Bold", size: 18)!
        timerManager?.timerDurationColor = .mimoBlack
        timerManager?.delegate = self
        timerManager?.startTimer()
        timerManager?.stopTimer()
    }
    
    // MARK: Methods
    private func setupViews() {
        totalView.layer.cornerRadius = 8
        totalView.addShadow(color: UIColor.black.withAlphaComponent(0.1))
        thankYouButton.layer.cornerRadius = 24
    }
    
    // MARK: Actions
    @IBAction func thanksYouButtonAction(_ sender: UIButton) {
        goToHomeVC()
    }
    
    private func goToHomeVC() {
//        let homeVC = HomeViewController.initFromStoryboard(name: Constant.Storyboards.home)
//        homeVC.state = .accountDone
//        let navVC = UINavigationController(rootViewController: homeVC)
//        setRootViewController(navVC)
        let messagingService: MessageServiceProtocol = Resolver.resolve()
        messagingService.publish(.scooterTripEnded)
        self.dismiss(animated: true)
    }
}

extension ThanksForTheRideViewController: TimerManagerDelegate {
    func didChanchTimeSeconds(seconds: Double) {
        
    }
    
    func didExpireDuration(timer: TimerManager) {
        
    }
    
}
