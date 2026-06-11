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
    
    func start()
    func stop()
    func sendLastLocation()
}
