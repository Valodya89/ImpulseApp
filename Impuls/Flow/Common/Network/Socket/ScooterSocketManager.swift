//
//  SocketManager.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/1/21.
//

import SwiftStomp

protocol ScooterSocketServiceProtocol {
    func listenToBikeShare(result: @escaping ([BikeResult]) -> ())
    func listenToBookNowSuccess(phoneNumber: String, result: @escaping (Result<TripActionModel, Error>) -> ())
}

class ScooterSocketService/*: SocketServiceProtocol */{
    
//    let socketManager: SwiftStomp
//    let socket: SocketIOClient
    
    var completions: [String: ((Data) -> ())?] = [:]
    var connected: ((Result<Void, Error>) -> ())?
    var scooterTrip: ((_ scooterData: TripScooterSocketDataModel) -> Void)?
    
//    var connectionType: StompConnectType?
    
    static var shared: ScooterSocketService = ScooterSocketService()
    
    lazy var connect: () = {
//        self.socketManager.connect()
    }()
    
    private init() {
//        self.socketManager = SwiftStomp(host: URL(string: MimoBaseURLs.scooterSoket.rawValue)!)
        //wss://prod1-sharing.mimobike.com/ws  new
        // ws://62.171.157.66:8040/ws   old
//        self.socketManager.autoReconnect = true
//        self.socketManager.delegate = self
    }
    
    func connect(completion: ((Result<Void, Error>) -> ())?) {
//        if !self.socketManager.isConnected {
//            self.socketManager.connect()
//        }
//       
//        self.connected = completion
//        
//        _ = self.connect
    }
    
//    func listenToBikeShare(result: @escaping ([BikeResult]) -> ()) {
//        completions["bikes"] = { (data) in
//            do {
//                guard let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: [String: Any]] else { return }
//                let model = dict.mapValues {
//                    return BikeResult(dict: $0)
//                }
//
//                result(model.map { $0.value })
//            } catch {
//
//            }
//        }
//
//        subscribe(name: "bikes")
//    }
//
//    func listenToBookNowSuccess(phoneNumber: String, result: @escaping (Result<TripActionModel, Error>) -> ()) {
//        let isSubribeCalled = completions[phoneNumber] == nil
//
//        completions[phoneNumber] = { (data) in
//            do {
//                let tripPhoneModel = try JSONDecoder().decode(TripActionModel.self, from: data)
//
//                result(.success(tripPhoneModel))
//            } catch {
//                result(.failure(error))
//            }
//        }
//
//        if isSubribeCalled {
//            subscribe(name: phoneNumber)
//        }
//    }
    
//    func listenTripUpdate(phoneNumber: String, result: @escaping (Result<TripActionModel, Error>) -> ()) {
//        let _ = completions[phoneNumber] == nil
//
//        completions[phoneNumber] = { (data) in
//            do {
//                let tripPhoneModel = try JSONDecoder().decode(TripActionModel.self, from: data)
//
//                print("Trip model in listenTripUpdate(): \(tripPhoneModel)")
//                result(.success(tripPhoneModel))
//            } catch {
//                result(.failure(error))
//            }
//        }
//
//        subscribe(name: phoneNumber)
//
//    }
    
//    func listenToScanSuccess(phoneNumber: String, result: @escaping (Result<TripActionModel, Error>) -> ()) {
//        let _ = completions[phoneNumber] == nil
//        print("Socket receive" )
//        completions[phoneNumber] = { (data) in
//            do {
//                let tripPhoneModel = try JSONDecoder().decode(TripActionModel.self, from: data)
//                result(.success(tripPhoneModel))
//                print("Trip model in listenToScanSuccess(): \(tripPhoneModel)")
//                print("Socket data: \(data)")
//
//            } catch {
//                result(.failure(error))
//            }
//        }
//
//        subscribe(name: phoneNumber)
//    }
    
    func subscribe(name: String) {
//        print("Did subCscripe to event named: \(name)")
//        self.socketManager.subscribe(to: name)
    }
    
    func setupInitialSubscribers() {
//        guard let phoneNumber = StorageManager().fetch(key: .phoneNumber, type: String.self) else {
//            return
//        }
//        
//        self.socketManager.subscribe(to: phoneNumber)
    }
}

//extension ScooterSocketService: SwiftStompDelegate {
//    
//    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers: [String : String]) {
////        print("Did receive message \(message)")
////        guard let mess = message as? String else {
////            return
////        }
////        let jsonData = Data(mess.utf8)
////        do {
////            let socketScanDto = try JSONDecoder().decode(TripScooterSocketDataModel.self, from: jsonData)
////            print("Socket data: \(socketScanDto)")
////            
////            if socketScanDto.state == "TRIP_ENDED" {
////                print("TRIP_ENDED = \(socketScanDto)")
////            }
////            scooterTrip?(socketScanDto)
////            
////        } catch let error {
////            print("err = \(error)")
////        }
////        
////        guard let message = message as? String else {
////            return
////        }
////        
////        let data = Data(message.utf8)
////        guard let completion = completions[destination] else { return }
////        print("Did send message to completion \(destination)")
////        completion?(data)
//    }
//    
//    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
////        connectionType = connectType
////
////        switch connectType {
////        case .toStomp:
////            print("did connect to socket type: Stomp")
////            self.setupInitialSubscribers()
////            self.connected?(.success(()))
////        case .toSocketEndpoint:
////            print("did connect to socket type: EndPoint")
////        }
//    }
//    
//    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
////        self.connected?(.failure(NetworkError.responseError("MOBILE__global_attention".localized())))
////        print("Did disconnect from socket type \(disconnectType)")
//    }
//    
//    func onSocketEvent(eventName: String, description: String) {
//        print("Did receive event \(eventName)")
//
//    }
//    
//    func onReceipt(swiftStomp: SwiftStomp, receiptId: String) {
//        print("On receipt from stop \(swiftStomp)")
//    }
//    
//    func onError(swiftStomp: SwiftStomp, briefDescription: String, fullDescription: String?, receiptId: String?, type: StompErrorType) {
//        print("On error stop \(swiftStomp)")
//
//    }
//}


struct TripScooterSocketDataModel: Decodable {
    let state: String?
    let scooter: IScanedScooter?
    var data: SocketData?
}
    
public struct ISpeedModeTariff: Decodable {
    let id: String?
    let price: Double?
    let speedMode: String?
    let speed: Int?
}

public struct IBillingModeTariff: Decodable {
    let id: String?
    let mode: String?
    let minutes: Int?
    let price: Double?
    
}

struct IScooterPosition: Decodable {
    let longitude: Double?
    let latitude: Double?
    let timestamp: Double?
}

struct IScooterPath: Decodable {
    let longitude: Double?
    let latitude: Double?
    let timestamp: Double?
}

struct IScanedScooter: Decodable {
    let id: String?
    let qr: String?
    let type:  String?
    let located: LocatedData?
    let batteryPercent: Int?
    let remainingMileage:  Int?
    let speed: Int?
}

struct SocketScanDto: Decodable {
    let state: String?
    let scooter: IScanedScooter?
    let data: TripScooterSocketDataModel?
}

struct SocketData: Decodable {
    let billingModeTariff: IBillingModeTariff?
    let end: Int?
    let endMileage: Int?
    let endPosition: IScooterPosition?
    let id: String?
    var pauses: [Pause]?
    let scan: Int?
    
    let speedModeTariff: ISpeedModeTariff?
    let start: Int?
    let startMileage: Int?
    let startPosition: IScooterPosition?
    let user: String?
    let distance: Int?
    let amount: Double?
}


// Pause
/*
 
 "content": {
         "state": "TRIP_PAUSED",
         "scooter": {
             "id": "862869031598670",
             "qr": "10010328",
             "type": "NINEBOT_ZK601",
             "located": {
                 "longitude": 43.82171833333334,
                 "latitude": 40.804183333333334,
                 "timestamp": 1659600402938
             },
             "batteryPercent": 69,
             "remainingMileage": 28150,
             "speed": 0
         },
         "data": {
             "id": "62eb7d7659beeb0e664108bf",
             "state": "TRIP_PAUSED",
             "scan": 1659600246965,
             "start": 1659600251029,
             "end": null,
             "speedModeTariff": {
                 "id": "62d69822c8afb263e44f4b51",
                 "price": 35.0,
                 "speedMode": "normal",
                 "speed": 0
             },
             "billingModeTariff": {
                 "id": "62d69611ebafd01090cc3fd7",
                 "mode": "MINUTE_BY_MINUTE",
                 "minutes": 0,
                 "price": 0.0
             },
             "user": "+37477788605",
             "scooter": "862869031598670",
             "startPosition": {
                 "longitude": 43.8217428583094,
                 "latitude": 40.804054392452784,
                 "timestamp": 1659600246965
             },
             "endPosition": null,
             "startMileage": 8791,
             "endMileage": 0,
             "distance": 0,
             "amount": 30.5,
             "pauses": [
                 {
                     "start": 1659600255736,
                     "end": 1659600389755
                 },
                 {
                     "start": 1659600409292,
                     "end": null
                 }
             ],
             "speedChanges": [
                 {
                     "start": 1659600251029,
                     "end": 1659600255736,
                     "speedModeTariffDetails": {
                         "id": "62d69822c8afb263e44f4b51",
                         "price": 35.0,
                         "speedMode": "normal",
                         "speed": 0
                     }
                 },
                 {
                     "start": 1659600389755,
                     "end": 1659600409292,
                     "speedModeTariffDetails": {
                         "id": "62d69822c8afb263e44f4b51",
                         "price": 35.0,
                         "speedMode": "normal",
                         "speed": 0
                     }
                 }
             ],
             "photo": null
         }
     }
 
 */

// continue

/*
 "content": {
         "state": "TRIP_STARTED",
         "scooter": {
             "id": "862869031598670",
             "qr": "10010328",
             "type": "NINEBOT_ZK601",
             "located": {
                 "longitude": 43.82171833333334,
                 "latitude": 40.804183333333334,
                 "timestamp": 1659600402938
             },
             "batteryPercent": 69,
             "remainingMileage": 28150,
             "speed": 0
         },
         "data": {
             "id": "62eb7d7659beeb0e664108bf",
             "state": "TRIP_STARTED",
             "scan": 1659600246965,
             "start": 1659600251029,
             "end": null,
             "speedModeTariff": {
                 "id": "62d69822c8afb263e44f4b51",
                 "price": 35.0,
                 "speedMode": "normal",
                 "speed": 0
             },
             "billingModeTariff": {
                 "id": "62d69611ebafd01090cc3fd7",
                 "mode": "MINUTE_BY_MINUTE",
                 "minutes": 0,
                 "price": 0.0
             },
             "user": "+37477788605",
             "scooter": "862869031598670",
             "startPosition": {
                 "longitude": 43.8217428583094,
                 "latitude": 40.804054392452784,
                 "timestamp": 1659600246965
             },
             "endPosition": null,
             "startMileage": 8791,
             "endMileage": 0,
             "distance": 0,
             "amount": 30.5,
             "pauses": [
                 {
                     "start": 1659600255736,
                     "end": 1659600389755
                 },
                 {
                     "start": 1659600409292,
                     "end": 1659600652998
                 }
             ],
             "speedChanges": [
                 {
                     "start": 1659600251029,
                     "end": 1659600255736,
                     "speedModeTariffDetails": {
                         "id": "62d69822c8afb263e44f4b51",
                         "price": 35.0,
                         "speedMode": "normal",
                         "speed": 0
                     }
                 },
                 {
                     "start": 1659600389755,
                     "end": 1659600409292,
                     "speedModeTariffDetails": {
                         "id": "62d69822c8afb263e44f4b51",
                         "price": 35.0,
                         "speedMode": "normal",
                         "speed": 0
                     }
                 },
                 {
                     "start": 1659600652998,
                     "end": null,
                     "speedModeTariffDetails": {
                         "id": "62d69822c8afb263e44f4b51",
                         "price": 35.0,
                         "speedMode": "normal",
                         "speed": 0
                     }
                 }
             ],
             "photo": null
         }
     }
 */
