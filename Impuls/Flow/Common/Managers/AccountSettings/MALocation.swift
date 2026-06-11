//
//  MALocation.swift
//  Management App
//
//  Created by Dose on 9/24/20.
//  Copyright © 2020 Doseh. All rights reserved.
//

import CoreLocation

final class MALocation: NSObject {
    
    static var current: MALocation = MALocation()
    
    var locationManager: CLLocationManager = CLLocationManager()
   
    var currentLocation: CLLocation? {
//        let location = CLLocation(latitude: 40.13698583519184, longitude: 44.489489279668774) // Pahest
//        let location = CLLocation(latitude: 40.18384, longitude: 44.50114666666666) // Dvin
//        let testScooter = CLLocation(latitude: 40.187570000000001, longitude: 44.507300000000001)
        return  locationManager.location
    }
    
    var isAccessed: Bool {
        return CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse
    }
    
    var currentStatus: CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }
    
    var didChangeAuthStatus: ((Bool)->())?
    var didUpdateLocation: ((CLLocationCoordinate2D?)->())?    
    var didReceiveLocationOnce: ((CLLocationCoordinate2D?)->())?
    
    private override init() {
        super.init()
        requestAndStartLocationHandle()
    }

    private func requestAndStartLocationHandle() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        requestAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func alertLocationAccess() {
        if currentStatus == .notDetermined {
            requestAuthorization()
        } else if currentStatus == .denied {
            UIAlertController.showLocationDeniedAlert()
        }
    }
    
    func requestAuthorization() {
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
    }
}

extension MALocation: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//       if let firstLocation = locations.first {
////           didUpdateLocation?(firstLocation.coordinate)
////           didReceiveLocationOnce?(firstLocation.coordinate)
//           didReceiveLocationOnce = nil 
//       } else {
//           didUpdateLocation?(nil)
//       }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        didChangeAuthStatus?(status == .authorizedWhenInUse || status == .authorizedAlways)
    }
}

extension MALocation {
    
    @discardableResult
    class func startLocationHeading() -> MALocation {
        return MALocation.current
    }
}
