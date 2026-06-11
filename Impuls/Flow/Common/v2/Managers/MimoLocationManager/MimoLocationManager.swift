//
//  MimoLocationManager.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.05.23.
//

import Foundation
import CoreLocation
import Combine

protocol MimoLocationManagerDelegate: AnyObject {
    func locationManager(didUpdateLocation location: CLLocationCoordinate2D?)
    func locationManager(didChangeAuthorizationStatus isAuthorized: Bool)
}

final class MimoLocationManager: NSObject, MimoLocationManagerProtocol {
    
    private var locationManager = CLLocationManager()
    
    var currenntLocation: CLLocation? { locationManager.location }
//    var isAuthorized: Bool { CLLocationManager.authorizationStatus() == .authorizedAlways ||
//                             CLLocationManager.authorizationStatus() == .authorizedWhenInUse }
    
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    private let locationSubject = PassthroughSubject<CLLocationCoordinate2D, Never>()
    private let authorizationStatusSubject = PassthroughSubject<Bool, Never>()
    private var lastLocation: CLLocationCoordinate2D?
    
    var locationPublisher: AnyPublisher<CLLocationCoordinate2D, Never> {
        return locationSubject.eraseToAnyPublisher()
    }
    
    var authorizationStatusPublisher: AnyPublisher<Bool, Never> {
        return authorizationStatusSubject.eraseToAnyPublisher()
    }
    
    override init() {
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        
        start()
    }
    
    func start() {
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.requestAlwaysAuthorization()
                self.locationManager.requestWhenInUseAuthorization()
                self.locationManager.startUpdatingLocation()
            } else {
                DispatchQueue.main.async {
                    UIAlertController.showLocationDeniedAlert()
                }
            }
        }
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
    }
    
    func sendLastLocation() {
        guard let lastLocation else { return }
        locationSubject.send(lastLocation)
    }
}

extension MimoLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let loc = location.coordinate
        locationSubject.send(loc)
        self.lastLocation = loc
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let isAuthorized = manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
        authorizationStatusSubject.send(isAuthorized)
    }
}
