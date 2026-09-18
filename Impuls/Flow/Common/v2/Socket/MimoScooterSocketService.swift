//
//  MimoScooterSocketService.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 04.06.23.
//

import SwiftStomp

protocol MimoScooterSocketServiceProtocol: AnyObject {
    
    var delegate: MimoScooterSocketServiceDelegate? { get set }
    
    func connect()
}

protocol MimoScooterSocketServiceDelegate: AnyObject {
    func onConnect()
    func onDisconnect()
    func onDataReceived(_ data: ScooterStateModel)
    func socketDataLagging()
}

final class MimoScooterSocketService: MimoScooterSocketServiceProtocol {
    
    let socketManager: SwiftStomp
    
    weak var delegate: MimoScooterSocketServiceDelegate?
    private var messageReceiveDate: Date?
    private var timer: Timer?
    /// When the STOMP session last came up; nil while down. Logged on every
    /// close so an "automatic" disconnect can be read as "after N seconds".
    private var connectedAt: Date?
    private var subscribedDestination: String?
    
    init() {
        socketManager = SwiftStomp(host: URL(string: MimoBaseURLs.scooterSoket.rawValue)!)
        socketManager.autoReconnect = true
        socketManager.enableLogging = true
        socketManager.delegate = self
        MimoSocketLog.info(.scooter, "init", "host=\(MimoBaseURLs.scooterSoket.rawValue) autoReconnect=true")
    }
    
    deinit {
        MimoSocketLog.info(.scooter, "deinit", "isConnected=\(socketManager.isConnected)")
    }
    
    func setupInitialSubscribers() {
        guard let phoneNumber = StorageManager().fetch(key: .phoneNumber, type: String.self) else {
            MimoSocketLog.error(.scooter, "subscribe skipped", "no phone number stored")
            return
        }
        
        subscribedDestination = phoneNumber
        MimoSocketLog.info(.scooter, "subscribe", "destination=\(MimoSocketLog.masked(phoneNumber))")
        self.socketManager.subscribe(to: phoneNumber)
        setupTimer()
    }
     
    func connect() {
        MimoSocketLog.info(.scooter, "connect() requested", "isConnected=\(socketManager.isConnected) status=\(socketManager.connectionStatus)")
        if !self.socketManager.isConnected {
            // `SwiftStomp.connect()` overwrites `autoReconnect` with its own
            // parameter (default false), so the flag set in `init` was lost on
            // the first connect and a dropped socket - the app backgrounded
            // while the rider walked to the cabinet - never came back.
            self.socketManager.connect(autoReconnect: true)
        }
    }
    
    private func setupTimer() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            if let messageReceiveDate = self?.messageReceiveDate {
                let differenceInSeconds = Int(Date().timeIntervalSince(messageReceiveDate))
                if differenceInSeconds >= 10 {
                    self?.delegate?.socketDataLagging()
                    MimoSocketLog.info(.scooter, "data lagging", "lastMessage=\(differenceInSeconds)s ago isConnected=\(self?.socketManager.isConnected ?? false)")
                }
            } else {
                self?.delegate?.socketDataLagging()
            }
        }
    }
}

extension MimoScooterSocketService: SwiftStompDelegate {
    
    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
        MimoSocketLog.info(.scooter, "onConnect", "type=\(connectType)")
        if connectType == .toStomp {
            connectedAt = Date()
            delegate?.onConnect()
            setupInitialSubscribers()
        }
    }
    
    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
        // `.fromSocket` = the WebSocket itself closed (server, network, iOS
        // suspension); `.fromStomp` = a STOMP-level disconnect. SwiftStomp's own
        // log line just before this one carries the close code and reason.
        MimoSocketLog.error(.scooter, "onDisconnect", "type=\(disconnectType) up=\(MimoSocketLog.age(since: connectedAt)) lastMessage=\(MimoSocketLog.age(since: messageReceiveDate)) ago destination=\(MimoSocketLog.masked(subscribedDestination)) autoReconnect=\(swiftStomp.autoReconnect)")
        connectedAt = nil
        subscribedDestination = nil
        delegate?.onDisconnect()
    }
    
    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers: [String : String]) {
        guard let message = message as? String else { return }
        MimoSocketLog.info(.scooter, "message", "id=\(messageId) destination=\(MimoSocketLog.masked(destination)) bytes=\(message.utf8.count)")
        
        do {
            let jsonData = Data(message.utf8)
            let data = try JSONDecoder().decode(ScooterStateModel.self, from: jsonData)
            
            DispatchQueue.main.async {
                self.delegate?.onDataReceived(data)
            }
            
            messageReceiveDate = Date()
            setupTimer()
        } catch {
            MimoSocketLog.error(.scooter, "message decode failed", "\(error)")
        }
    }
    
    func onReceipt(swiftStomp: SwiftStomp, receiptId: String) {
        MimoSocketLog.info(.scooter, "onReceipt", "receiptId=\(receiptId)")
    }
    
    func onError(swiftStomp: SwiftStomp, briefDescription: String, fullDescription: String?, receiptId: String?, type: StompErrorType) {
        MimoSocketLog.error(.scooter, "onError", "type=\(type) \(briefDescription): \(fullDescription ?? "-") receiptId=\(receiptId ?? "-") up=\(MimoSocketLog.age(since: connectedAt))")
    }
    
    func onSocketEvent(eventName: String, description: String) {
        MimoSocketLog.info(.scooter, "onSocketEvent", "\(eventName): \(description)")
    }
}
