//
//  SocketManager.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 6/1/21.
//

//import SwiftStomp

protocol SocketServiceProtocol {
    func listenToBikeShare(result: @escaping ([BikeResult]) -> ())
    func listenToBookNowSuccess(phoneNumber: String, result: @escaping (Result<TripActionModel, Error>) -> ())
}

class SocketService: SocketServiceProtocol {
    
//    let socketManager: SwiftStomp
//    let socket: SocketIOClient
    
    var completions: [String: ((Data) -> ())?] = [:]
    var connected: ((Result<Void, Error>) -> ())?
    
//    var connectionType: StompConnectType?
    
    static var shared: SocketService = SocketService()
    
    lazy var connect: () = {
//        self.socketManager.connect()
    }()
    
    private init() {
//        self.socketManager = SwiftStomp(host: URL(string: MimoBaseURLs.socket.rawValue)!)
        //wss://prod1-sharing.mimobike.com/ws  new
        // ws://62.171.157.66:8040/ws   old
//        self.socketManager.autoReconnect = true
//        self.socketManager.delegate = self
    }
    
    func connect(completion: ((Result<Void, Error>) -> ())?) {
//        self.connected = completion
//        
//        _ = self.connect
    }
    
    func listenToBikeShare(result: @escaping ([BikeResult]) -> ()) {
        completions["bikes"] = { (data) in
            do {
                guard let dict = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: [String: Any]] else { return }
//                let model = dict.mapValues {
//                    return BikeResult(dict: $0)
//                }
                
//                result(model.map { $0.value })
            } catch {
                
            }
        }

        subscribe(name: "bikes")
    }
    
    func listenToBookNowSuccess(phoneNumber: String, result: @escaping (Result<TripActionModel, Error>) -> ()) {
        let isSubribeCalled = completions[phoneNumber] == nil

        completions[phoneNumber] = { (data) in
            do {
                let tripPhoneModel = try JSONDecoder().decode(TripActionModel.self, from: data)
                
                result(.success(tripPhoneModel))
            } catch {
                result(.failure(error))
            }
        }
        
        if isSubribeCalled {
            subscribe(name: phoneNumber)
        }
    }
    
    func listenTripUpdate(phoneNumber: String, result: @escaping (Result<TripActionModel, Error>) -> ()) {
        let _ = completions[phoneNumber] == nil

        completions[phoneNumber] = { (data) in
            do {
                let tripPhoneModel = try JSONDecoder().decode(TripActionModel.self, from: data)
                
                print("Trip model in listenTripUpdate(): \(tripPhoneModel)")
                result(.success(tripPhoneModel))
            } catch {
                result(.failure(error))
            }
        }
        
        subscribe(name: phoneNumber)
    }
    
    func listenToScanSuccess(phoneNumber: String, result: @escaping (Result<TripActionModel, Error>) -> ()) {
        let _ = completions[phoneNumber] == nil
        print("Socket receive" )
        completions[phoneNumber] = { (data) in
            do {
                let tripPhoneModel = try JSONDecoder().decode(TripActionModel.self, from: data)
                result(.success(tripPhoneModel))
                print("Trip model in listenToScanSuccess(): \(tripPhoneModel)")
                print("Socket data: \(data)")
                
            } catch {
                result(.failure(error))
            }
        }
        
        subscribe(name: phoneNumber)
    }
    
    func subscribe(name: String) {
        print("Did subCscripe to event named: \(name)")
//        self.socketManager.subscribe(to: name)
    }
    
    func setupInitialSubscribers() {
        guard let phoneNumber = StorageManager().fetch(key: .phoneNumber, type: String.self) else {
            return
        }
        
//        self.socketManager.subscribe(to: phoneNumber)
    }
}

//extension SocketService: SwiftStompDelegate {
//    
//    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers: [String : String]) {
//        print("Did receive message \(message)")
//
//        guard let message = message as? String else {
//            return
//        }
//        
//        let data = Data(message.utf8)
//        guard let completion = completions[destination] else { return }
//        print("Did send message to completion \(destination)")
//        completion?(data)
//    }
//    
//    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
//        connectionType = connectType
//
//        switch connectType {
//        case .toStomp:
//            print("did connect to socket type: Stomp")
//            self.setupInitialSubscribers()
//            self.connected?(.success(()))
//        case .toSocketEndpoint:
//            print("did connect to socket type: EndPoint")
//        }
//    }
//    
//    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
//        self.connected?(.failure(NetworkError.responseError("MOBILE__global_attention".localized())))
//        print("Did disconnect from socket type \(disconnectType)")
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
