//
//  MimoBikeSocketService.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.07.23.
//

import SwiftStomp

protocol MimoBikeSocketServiceProtocol: AnyObject {
    
    var delegate: MimoBikeSocketServiceDelegate? { get set }
    
    func connect()
    func subscribeToBikesUpdate()
    func subscribeToBikeStateUpdate()
}

protocol MimoBikeSocketServiceDelegate: AnyObject {
    func onConnect()
    func onDisconnect()
    
    func bikesDataReceived(_ data: [BikeResult])
    func bikeStateDataReceived(_ data: TripActionModel)
    func socketDataLagging()
}

class MimoBikeSocketService: MimoBikeSocketServiceProtocol {
    
    private let socketManager: SwiftStomp
    private var messageReceiveDate: Date?
    private var timer: Timer?
    /// When the STOMP session last came up; nil while down. Logged on every
    /// close so an "automatic" disconnect can be read as "after N seconds".
    private var connectedAt: Date?
    private var subscribedDestination: String?
    
    weak var delegate: MimoBikeSocketServiceDelegate?
    
    init() {
        socketManager = SwiftStomp(host: URL(string: MimoBaseURLs.socket.rawValue)!)
        socketManager.autoReconnect = true
        socketManager.delegate = self
        socketManager.enableLogging = true
        MimoSocketLog.info(.bike, "init", "host=\(MimoBaseURLs.socket.rawValue) autoReconnect=true")
    }
    
    deinit {
        MimoSocketLog.info(.bike, "deinit", "isConnected=\(socketManager.isConnected)")
    }
     
    func connect() {
        MimoSocketLog.info(.bike, "connect() requested", "isConnected=\(socketManager.isConnected) status=\(socketManager.connectionStatus)")
        if !self.socketManager.isConnected {
            // `SwiftStomp.connect()` overwrites `autoReconnect` with its own
            // parameter (default false), so the flag set in `init` was lost on
            // the first connect and a dropped socket - the app backgrounded
            // while the rider walked to the cabinet - never came back.
            self.socketManager.connect(autoReconnect: true)
        }
    }
    
    func subscribeToBikesUpdate() {
        MimoSocketLog.info(.bike, "subscribe", "destination=bikes")
        self.socketManager.subscribe(to: "bikes")
    }
    
    func subscribeToBikeStateUpdate() {
        guard let phoneNumber = StorageManager().fetch(key: .phoneNumber, type: String.self) else {
            MimoSocketLog.error(.bike, "subscribe skipped", "no phone number stored")
            return
        }
        
        subscribedDestination = phoneNumber
        MimoSocketLog.info(.bike, "subscribe", "destination=\(MimoSocketLog.masked(phoneNumber))")
        self.socketManager.subscribe(to: phoneNumber)

        // The silence watchdog used to arm only on the first message, so a
        // subscription that delivered nothing had no polling fallback at all.
        if messageReceiveDate == nil {
            messageReceiveDate = Date()
        }
        setupTimer()
    }
    
    private func setupTimer() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            if let messageReceiveDate = self?.messageReceiveDate {
                let differenceInSeconds = Int(Date().timeIntervalSince(messageReceiveDate))
                if differenceInSeconds >= 15 {
                    self?.delegate?.socketDataLagging()
                    MimoSocketLog.info(.bike, "data lagging", "lastMessage=\(differenceInSeconds)s ago isConnected=\(self?.socketManager.isConnected ?? false)")
                }
            }
        }
    }
}

extension MimoBikeSocketService: SwiftStompDelegate {
    
    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
        MimoSocketLog.info(.bike, "onConnect", "type=\(connectType)")
        if connectType == .toStomp {
            connectedAt = Date()
            delegate?.onConnect()
            subscribeToBikeStateUpdate()
            subscribeToBikesUpdate()
        }
    }
    
    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
        // `.fromSocket` = the WebSocket itself closed (server, network, iOS
        // suspension); `.fromStomp` = a STOMP-level disconnect. SwiftStomp's own
        // log line just before this one carries the close code and reason.
        MimoSocketLog.error(.bike, "onDisconnect", "type=\(disconnectType) up=\(MimoSocketLog.age(since: connectedAt)) lastMessage=\(MimoSocketLog.age(since: messageReceiveDate)) ago destination=\(MimoSocketLog.masked(subscribedDestination)) autoReconnect=\(swiftStomp.autoReconnect)")
        connectedAt = nil
        subscribedDestination = nil
        delegate?.onDisconnect()
    }
    
    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers: [String : String]) {
        guard let message = message as? String else { return }
        MimoSocketLog.info(.bike, "message", "id=\(messageId) destination=\(destination == "bikes" ? "bikes" : MimoSocketLog.masked(destination)) bytes=\(message.utf8.count)")
        
        if destination == "bikes" {
            do {
                let jsonData = Data(message.utf8)
                let data = try JSONDecoder().decode([String: BikeResponse].self, from: jsonData)
                let bikes = data.map({ $0.value })
                let result = HomeMapper.toBikeResults(from: bikes)
                
                delegate?.bikesDataReceived(result)
            } catch {
                print(error.localizedDescription)
            }
        } else {
            do {
                let jsonData = Data(message.utf8)
                let data = try JSONDecoder().decode(TripActionModel.self, from: jsonData)
                delegate?.bikeStateDataReceived(data)
                
                messageReceiveDate = Date()
                setupTimer()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func onReceipt(swiftStomp: SwiftStomp, receiptId: String) {
        MimoSocketLog.info(.bike, "onReceipt", "receiptId=\(receiptId)")
    }
    
    func onError(swiftStomp: SwiftStomp, briefDescription: String, fullDescription: String?, receiptId: String?, type: StompErrorType) {
        MimoSocketLog.error(.bike, "onError", "type=\(type) \(briefDescription): \(fullDescription ?? "-") receiptId=\(receiptId ?? "-") up=\(MimoSocketLog.age(since: connectedAt))")
    }
    
    func onSocketEvent(eventName: String, description: String) {
        MimoSocketLog.info(.bike, "onSocketEvent", "\(eventName): \(description)")
    }
}
