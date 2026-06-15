//
//  TripActionModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/21/21.
//

import CoreLocation
import UIKit

enum TripAction: String, Codable {
    case None = "NONE"
    case Booking_Started = "BOOKING_STARTED"
    case BookingEnded = "BOOKING_ENDED"
    case TripScanned = "TRIP_SCANNED"
    case TripStarted = "TRIP_STARTED"
    case TripNotStarted = "TRIP_NOT_STARTED"
    case TripEnded = "TRIP_ENDED"
    case TripPaused = "TRIP_PAUSED"
    case TripOutOfZone = "TRIP_OUT_OF_ZONE"
}

struct TripBikeDataModel: Decodable {
    let id: String
    let scan: Int?
    let start: Int?
    let end: Int?
    let user: String?
    let bike: String?
    let distance: Int?
    let amount: Double?
    let payment: PaymentModel?
    let startPosition: TripPositionModel?
    let endPosition: TripPositionModel?
    
    struct PaymentModel: Decodable {
        let amount: Double?
        let status: PaymentProgress?
        let sources: [TripSources]?
    }

    struct TripSources: Decodable {
        let type: String
        let minutes: Int
        let date: Int
    }
    
    struct TripPositionModel: Decodable {
        let longitude: Double
        let latitude: Double
        let timestamp: Int
        
        let geocoder: MimoGeocoder = MimoGeocoder()
        
        enum CodingKeys: CodingKey {
            case longitude
            case latitude
            case timestamp
        }
                
        func getLocationName(completed: @escaping (String) -> ()) {
            let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
            
            geocoder.reverseGeocodeCoordinate(coordinate) { (result, error) in
                guard let response = result?.firstResult() else { return }

                let thoroughfare = response.thoroughfare ?? "---"
                print(thoroughfare)
            }
            
            if let coordinateLocation = BikeLocationCaching.cache.object(forKey: BikeLocationCaching.getSafeLocationCoordinate(location: coordinate) as AnyObject), let stringValue = coordinateLocation as? String {
                return completed(stringValue)
            }
            
            geocoder.reverseGeocodeCoordinate(coordinate) { (result, error) in
                guard let response = result?.firstResult() else { return }

                let thoroughfare = response.thoroughfare ?? "---"
                BikeLocationCaching.cache.setObject(thoroughfare as AnyObject, forKey: BikeLocationCaching.getSafeLocationCoordinate(location: coordinate) as AnyObject)
                
                return completed(thoroughfare)
            }
        }
        
        func setLocationName(long: Bool, in label: UILabel) {
            let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
            if let coordinateLocation = BikeLocationCaching.cache.object(forKey: BikeLocationCaching.getSafeLocationCoordinate(location: coordinate) as AnyObject), let stringValue = coordinateLocation as? String {
                label.text = stringValue
                return
            }

            geocoder.reverseGeocodeCoordinate(coordinate) {[weak label] (result, error) in
                guard let response = result?.firstResult() else { return }
                let lines = response.lines?.first ?? "---"
                let thoroughfare = response.thoroughfare ?? "---"
                label?.text = (long) ? lines : thoroughfare
                BikeLocationCaching.cache.setObject(thoroughfare as AnyObject, forKey: BikeLocationCaching.getSafeLocationCoordinate(location: coordinate) as AnyObject)
            }
        }
        
        func cacheLocation()  {
            let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
            if BikeLocationCaching.cache.object(forKey: BikeLocationCaching.getSafeLocationCoordinate(location: coordinate) as AnyObject) != nil {
                return
            }

            geocoder.reverseGeocodeCoordinate(coordinate) { (result, error) in
                guard let response = result?.firstResult() else { return }
                let thoroughfare = response.thoroughfare ?? "---"
                BikeLocationCaching.cache.setObject(thoroughfare as AnyObject, forKey: BikeLocationCaching.getSafeLocationCoordinate(location: coordinate) as AnyObject)
            }
        }
    }
}

enum PaymentProgress: String, Decodable {
    case success = "SUCCESS"
    case waiting = "WAITING"
    case error = "FAILED"
    
    var backgroundColor: UIColor {
        switch self {
        case .error:
            return .mimoRed500
        case .waiting:
            return .mimoYellow500
        case .success:
            return .mimoGreenLight
        }
    }
    
    var fillColor: UIColor {
        switch self {
        case .success:
            return .mimoWhite
        case .waiting:
            return .mimoBlack
        case .error:
            return .mimoWhite
        }
    }
    
    var userDescirption: String {
        switch self {
        case .success:
            return "Payed"
        case .waiting:
            return "Waiting"
        case .error:
            return "Failed"
        }
    }
}

struct TripActionModel: Decodable {
    let action: TripAction
    let bikeDto: BikeResponse?
    let data: TripBikeDataModel?
}
