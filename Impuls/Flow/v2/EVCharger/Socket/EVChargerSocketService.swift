//
//  EVChargerSocketService.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 5/4/25.
//

import Foundation
import SwiftStomp

struct WSAcknowledgment: Encodable {
    let messageId: String
    let topic: String
}

protocol EVChargerSocketServiceProtocol: AnyObject {
    
    var delegate: EVChargerSocketServiceDelegate? { get set }
    
    func connect()
    func disconnect()
    func subscribeToBikeStateUpdate()
}

protocol EVChargerSocketServiceDelegate: AnyObject {
    func onConnect()
    func onDisconnect()
    
    func evChargerStateDataReceived(_ data: EVSocketResponse)
    func socketDataLagging()
}

class EVChargerSocketService: EVChargerSocketServiceProtocol {
    
    private let socketManager: SwiftStomp
    private var messageReceiveDate: Date?
    private var timer: Timer?
    /// When the STOMP session last came up; nil while down. Logged on every
    /// close so an "automatic" disconnect can be read as "after N seconds".
    private var connectedAt: Date?
    private var subscribedDestination: String?
    
    weak var delegate: EVChargerSocketServiceDelegate?
    
    init() {
        socketManager = SwiftStomp(host: URL(string: MimoBaseURLs.evChargerSoket.rawValue)!)
        socketManager.autoReconnect = true
        socketManager.delegate = self
        socketManager.enableLogging = true
        MimoSocketLog.info(.evCharger, "init", "host=\(MimoBaseURLs.evChargerSoket.rawValue) autoReconnect=true")
    }
    
    deinit {
        MimoSocketLog.info(.evCharger, "deinit", "isConnected=\(socketManager.isConnected)")
        if self.socketManager.isConnected {
            MimoSocketLog.info(.evCharger, "disconnect() from deinit")
            socketManager.disconnect()
        }
    }
     
    func connect() {
        MimoSocketLog.info(.evCharger, "connect() requested", "isConnected=\(socketManager.isConnected) status=\(socketManager.connectionStatus)")
        if !self.socketManager.isConnected {
            // `SwiftStomp.connect()` overwrites `autoReconnect` with its own
            // parameter (default false), so the flag set in `init` was lost on
            // the first connect and a dropped socket - the app backgrounded
            // while the rider walked to the cabinet - never came back.
            self.socketManager.connect(autoReconnect: true)
        }
    }
    
    func disconnect() {
        MimoSocketLog.info(.evCharger, "disconnect() requested by app", "isConnected=\(socketManager.isConnected) up=\(MimoSocketLog.age(since: connectedAt))")
        if self.socketManager.isConnected {
            self.socketManager.disconnect()
        }
        // This service lives for the whole app session, so without stopping the
        // lag timer here it keeps firing socketDataLagging() every 15 seconds -
        // and each one refetches state - long after the socket is gone.
        timer?.invalidate()
        timer = nil
        messageReceiveDate = nil
    }
    
    func subscribeToBikeStateUpdate() {
        guard let phoneNumber = StorageManager().fetch(key: .phoneNumber, type: String.self) else {
            MimoSocketLog.error(.evCharger, "subscribe skipped", "no phone number stored")
            return
        }
        
        subscribedDestination = phoneNumber
        MimoSocketLog.info(.evCharger, "subscribe", "destination=\(MimoSocketLog.masked(phoneNumber))")
        self.socketManager.subscribe(to: phoneNumber)
    }
    
    private func sendAcknowledgment(messageId: String) {
        guard let topic = StorageManager().fetch(key: .phoneNumber, type: String.self) else { return }
        let ack = WSAcknowledgment(messageId: messageId, topic: topic)
        guard let body = try? JSONEncoder().encode(ack),
              let bodyString = String(data: body, encoding: .utf8) else { return }
        socketManager.send(
            body: bodyString,
            to: "/app/acknowledgment",
            headers: [
                "content-type": "application/json"
            ]
        )
    }

    private func setupTimer() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            if let messageReceiveDate = self?.messageReceiveDate {
                let differenceInSeconds = Int(Date().timeIntervalSince(messageReceiveDate))
                if differenceInSeconds >= 15 {
                    self?.delegate?.socketDataLagging()
                    MimoSocketLog.info(.evCharger, "data lagging", "lastMessage=\(differenceInSeconds)s ago isConnected=\(self?.socketManager.isConnected ?? false)")
                    // Reset the watermark so the next report is a fresh 15s of
                    // silence rather than every tick from here on.
                    self?.messageReceiveDate = Date()
                }
            }
        }
    }
}

extension EVChargerSocketService: SwiftStompDelegate {
    
    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
        MimoSocketLog.info(.evCharger, "onConnect", "type=\(connectType)")
        
        if connectType == .toStomp {
            connectedAt = Date()
            delegate?.onConnect()
            subscribeToBikeStateUpdate()
        }
    }
    
    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
        // `.fromSocket` = the WebSocket itself closed (server, network, iOS
        // suspension); `.fromStomp` = a STOMP-level disconnect. SwiftStomp's own
        // log line just before this one carries the close code and reason.
        MimoSocketLog.error(.evCharger, "onDisconnect", "type=\(disconnectType) up=\(MimoSocketLog.age(since: connectedAt)) lastMessage=\(MimoSocketLog.age(since: messageReceiveDate)) ago destination=\(MimoSocketLog.masked(subscribedDestination)) autoReconnect=\(swiftStomp.autoReconnect)")
        connectedAt = nil
        subscribedDestination = nil
        
        delegate?.onDisconnect()
    }
    
    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers: [String : String]) {
        guard let message = message as? String else { return }
        MimoSocketLog.info(.evCharger, "message", "id=\(messageId) destination=\(MimoSocketLog.masked(destination)) bytes=\(message.utf8.count)")
        print("==SOCKET Socket message: \(message)")
        
        do {
            let jsonData = Data(message.utf8)
            let data = try JSONDecoder().decode(EVSocketResponse.self, from: jsonData)
            
            delegate?.evChargerStateDataReceived(data)
            sendAcknowledgment(messageId: data.id)
            
            messageReceiveDate = Date()
            setupTimer()
        } catch {
            // `localizedDescription` of a DecodingError says nothing useful.
            MimoSocketLog.error(.evCharger, "message decode failed", "\(error)")
        }
    }
    
    func onReceipt(swiftStomp: SwiftStomp, receiptId: String) {
        MimoSocketLog.info(.evCharger, "onReceipt", "receiptId=\(receiptId)")
    }
    
    func onError(swiftStomp: SwiftStomp, briefDescription: String, fullDescription: String?, receiptId: String?, type: StompErrorType) {
        MimoSocketLog.error(.evCharger, "onError", "type=\(type) \(briefDescription): \(fullDescription ?? "-") receiptId=\(receiptId ?? "-") up=\(MimoSocketLog.age(since: connectedAt))")
    }
    
    func onSocketEvent(eventName: String, description: String) {
        MimoSocketLog.info(.evCharger, "onSocketEvent", "\(eventName): \(description)")
    }
}
