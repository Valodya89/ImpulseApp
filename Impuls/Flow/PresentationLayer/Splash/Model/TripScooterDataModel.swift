//
//  TripScooterDataModel.swift
//  MimoScooter
//
//  Created by Karen Galoyan on 7/29/22.
//

import UIKit
import GoogleMaps
/*
{
            "id": "62e3e32c86679b2c2eff0b02",
            "scan": 1659101996778,
            "start": 1659102001448,
            "end": 1659107409486,
            "speedModeTariff": {
                "id": "62d69822c8afb263e44f4b50",
                "price": 28.0,
                "speedMode": "slow",
                "speed": 0
            },
            "billingModeTariff": {
                "id": "62d69611ebafd01090cc3fd7",
                "mode": "MINUTE_BY_MINUTE",
                "minutes": 0,
                "price": 0.0
            },
            "user": "+37477788605",
            "scooter": "862869031679918",
            "startPosition": {
                "longitude": 44.501483893043854,
                "latitude": 40.185054385643994,
                "timestamp": 1659101996778
            },
            "endPosition": {
                "longitude": 44.502608333333335,
                "latitude": 40.185165,
                "timestamp": 1659107401635
            },
            "startMileage": 36664,
            "endMileage": 36664,
            "pauses": [],
            "payment": {
                "amount": 2523.73,
                "status": "WAITING",
                "sources": null
            }
        }
*/
// MARK: - TripScooterDataModel
 struct TripScooterDataModel: Codable {
     let billingModeTariff: BillingModeTariff?
     let end: Int?
     let endMileage: Int?
     let endPosition: Position?
     let id: String?
     let scooterQr: String?
     let pauses: [Pause]?
     let payment: Payment?
     let scan: Int?
     let scooter: String?
     let speedModeTariff: SpeedModeTariff?
     let start: Int?
     let startMileage: Int?
     let startPosition: Position?
     let user: String?
     let distance: Int?


    enum CodingKeys: String, CodingKey {
        case billingModeTariff = "billingModeTariff"
        case end = "end"
        case endMileage = "endMileage"
        case endPosition = "endPosition"
        case id = "id"
        case scooterQr = "scooterQr"
        case pauses = "pauses"
        case payment = "payment"
        case scan = "scan"
        case scooter = "scooter"
        case speedModeTariff = "speedModeTariff"
        case start = "start"
        case startMileage = "startMileage"
        case startPosition = "startPosition"
        case user = "user"
        case distance = "distance"
    }

     init(billingModeTariff: BillingModeTariff?, end: Int?, endMileage: Int?, endPosition: Position?, id: String?, pauses: [Pause]?, payment: Payment?, scan: Int?, scooter: String?, speedModeTariff: SpeedModeTariff?, start: Int?, startMileage: Int?, startPosition: Position?, user: String?, distance: Int?, scooterQr: String?) {
        self.billingModeTariff = billingModeTariff
        self.end = end
        self.endMileage = endMileage
        self.endPosition = endPosition
        self.id = id
        self.scooterQr = scooterQr
        self.pauses = pauses
        self.payment = payment
        self.scan = scan
        self.scooter = scooter
        self.speedModeTariff = speedModeTariff
        self.start = start
        self.startMileage = startMileage
        self.startPosition = startPosition
        self.user = user
        self.distance = distance
    }
}

//// MARK: - BillingModeTariff
// struct BillingModeTariff: Codable {
//     let id: String?
//     let minutes: Int?
//     let mode: String?
//     let price: Int?
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case minutes = "minutes"
//        case mode = "mode"
//        case price = "price"
//    }
//
//     init(id: String?, minutes: Int?, mode: String?, price: Int?) {
//        self.id = id
//        self.minutes = minutes
//        self.mode = mode
//        self.price = price
//    }
//}

// MARK: - Position
 struct Position: Codable {
     let latitude: Double
     let longitude: Double
     let timestamp: Int

     let geocoder: GMSGeocoder = GMSGeocoder()

    enum CodingKeys: String, CodingKey {
        case latitude = "latitude"
        case longitude = "longitude"
        case timestamp = "timestamp"
    }

                 
         func getLocationName(completed: @escaping (String) -> ()) {
             let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
             
             geocoder.reverseGeocodeCoordinate(coordinate) { (result, error) in
                 guard let response = result?.firstResult() else { return }

                 let thoroughfare = response.thoroughfare ?? "---"
                 print(thoroughfare)
             }
             
             if let coordinateLocation = ScooterLocationCaching.cache.object(forKey: ScooterLocationCaching.getSafeLocationCoordinate(location: coordinate) as AnyObject), let stringValue = coordinateLocation as? String {
                 return completed(stringValue)
             }
             
             geocoder.reverseGeocodeCoordinate(coordinate) { (result, error) in
                 guard let response = result?.firstResult() else { return }

                 let thoroughfare = response.thoroughfare ?? "---"
                 ScooterLocationCaching.cache.setObject(thoroughfare as AnyObject, forKey: ScooterLocationCaching.getSafeLocationCoordinate(location: coordinate) as AnyObject)
                 
                 return completed(thoroughfare)
             }
         }
         
         func setLocationName(long: Bool, in label: UILabel) {
             let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
             if let coordinateLocation = ScooterLocationCaching.cache.object(forKey: ScooterLocationCaching.getSafeLocationCoordinate(location: coordinate) as AnyObject), let stringValue = coordinateLocation as? String {
                 label.text = stringValue
                 return
             }

             geocoder.reverseGeocodeCoordinate(coordinate) {[weak label] (result, error) in
                 guard let response = result?.firstResult() else { return }
                 let lines = response.lines?.first ?? "---"
                 let thoroughfare = response.thoroughfare ?? "---"
                 label?.text = (long) ? lines : thoroughfare
                 ScooterLocationCaching.cache.setObject(thoroughfare as AnyObject, forKey: ScooterLocationCaching.getSafeLocationCoordinate(location: coordinate) as AnyObject)
             }

         }
         
         func cacheLocation()  {
             let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
             if ScooterLocationCaching.cache.object(forKey: ScooterLocationCaching.getSafeLocationCoordinate(location: coordinate) as AnyObject) != nil {
                 return
             }

             geocoder.reverseGeocodeCoordinate(coordinate) { (result, error) in
                 guard let response = result?.firstResult() else { return }
                 let thoroughfare = response.thoroughfare ?? "---"
                 ScooterLocationCaching.cache.setObject(thoroughfare as AnyObject, forKey: ScooterLocationCaching.getSafeLocationCoordinate(location: coordinate) as AnyObject)
             }
         }
     }

// MARK: - Pause
 struct Pause: Codable {
     var end: Int?
     let start: Int?

    enum CodingKeys: String, CodingKey {
        case end = "end"
        case start = "start"
    }

     init(end: Int?, start: Int?) {
        self.end = end
        self.start = start
    }
}

// MARK: - Payment
struct Payment: Codable {
    let amount: Double?
    let sources: [Source]?
    let status: ScooterPaymentProgress?

    enum CodingKeys: String, CodingKey {
        case amount = "amount"
        case sources = "sources"
        case status = "status"
    }

     init(amount: Double?, sources: [Source]?, status: ScooterPaymentProgress?) {
        self.amount = amount
        self.sources = sources
        self.status = status
    }
}

// MARK: - Source
 struct Source: Codable {
     let date: Int?
     let minutes: Int?
     let type: String?

    enum CodingKeys: String, CodingKey {
        case date = "date"
        case minutes = "minutes"
        case type = "type"
    }

     init(date: Int?, minutes: Int?, type: String?) {
        self.date = date
        self.minutes = minutes
        self.type = type
    }
}

enum ScooterPaymentProgress: String, Codable {
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

//// MARK: - SpeedModeTariff
// struct SpeedModeTariff: Codable {
//     let id: String?
//     let price: Int?
//
//    enum CodingKeys: String, CodingKey {
//        case id = "id"
//        case price = "price"
//    }
//
//     init(id: String?, price: Int?) {
//        self.id = id
//        self.price = price
//    }
//}
