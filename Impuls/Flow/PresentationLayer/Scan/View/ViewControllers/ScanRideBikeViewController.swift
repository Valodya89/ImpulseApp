//
//  ScanRideBikeViewController.swift
//  MimoBike
//
//  Created by Vardan on 13.05.21.
//

import UIKit
import GoogleMaps

final class ScanRideBikeViewController: BaseViewController, StoryboardInitializable {

    
    //MARK: - Outlets
    @IBOutlet private weak var timerLabel: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var gradientBlurView: GradientView!
    
    
    //MARK: - Variables
    
    private var locationManager = CLLocationManager()
    var timerManager: TimerManager!
    
    
    //MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    private func configureUI() {
        setupTimer()
        configureDelegates()
        configureMapView()
    }
    
    /// configure Delegates
    private func configureDelegates() {

        locationManager.delegate = self
        locationManager.startUpdatingLocation()
    }
    
    // setup timer configurations
    private func setupTimer() {
        timerManager = TimerManager(timerLabel: timerLabel, duration: 1, formaterUnits: [.hour, .minute, .second], timerState: .increment)
        timerManager.labelFont = timerLabel.font
        timerManager.timerDurationColor = timerLabel.textColor
        timerManager.startTimer()
    }
    
    /// configure map view
    private func configureMapView() {
        mapView.isMyLocationEnabled = true
    }
    
    
    //MARK: - Actions

    @IBAction func stopRideTapped(_ sender: UIButton) {
        timerManager.stopTimer()
    }
}

extension ScanRideBikeViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        let location = locations.last

        let camera = GMSCameraPosition.camera(withLatitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!, zoom: 17.0)

        self.mapView?.animate(to: camera)

        //Finally stop updating location otherwise it will come again and again in this delegate
        locationManager.stopUpdatingLocation()

    }
}
