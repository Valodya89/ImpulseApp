//
//  MimoLocationManagerProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.05.23.
//

import Foundation
import CoreLocation
import Combine

protocol MimoLocationManagerProtocol {
    
    var currenntLocation: CLLocation? { get }
//    var isAuthorized: Bool { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    
    var locationPublisher: AnyPublisher<CLLocationCoordinate2D, Never> { get }
    var authorizationStatusPublisher: AnyPublisher<Bool, Never> { get }
    /// Replays the current `CLAuthorizationStatus` to a new subscriber and then
    /// every change, so a screen that opens after the system prompt was answered
    /// still knows where it stands (`authorizationStatusPublisher` only emits
    /// changes).
    var authorizationStatusValuePublisher: AnyPublisher<CLAuthorizationStatus, Never> { get }

    func start()
    func stop()
    func sendLastLocation()
    /// Asks for "when in use" only; shows the system prompt while the status is
    /// `.notDetermined` and is a no-op otherwise.
    func requestWhenInUseAuthorization()
}
