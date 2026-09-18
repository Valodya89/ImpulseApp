//
//  MimoChargerSocketService.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.11.23.
//

import Combine
import SwiftStomp

protocol MimoChargerSocketServiceProtocol: AnyObject {

    var delegate: MimoChargerSocketServiceDelegate? { get set }

    /// Rent state as it arrives. A publisher rather than the single `delegate`
    /// below: the home screen and the power bank map both need every message, and
    /// one weak delegate can only ever serve whichever of them set it last.
    var dataPublisher: AnyPublisher<RentedCharger, Never> { get }
    /// Fires when nothing has arrived for a while, so a screen can re-read state.
    var laggingPublisher: AnyPublisher<Void, Never> { get }

    func connect()
}

protocol MimoChargerSocketServiceDelegate: AnyObject {
    func onConnect()
    func onDisconnect()
    func onDataReceived(_ data: RentedCharger)
    func socketDataLagging()
}

final class MimoChargerSocketService: MimoChargerSocketServiceProtocol {
    
    let socketManager: SwiftStomp
    
    weak var delegate: MimoChargerSocketServiceDelegate?

    var dataPublisher: AnyPublisher<RentedCharger, Never> { dataSubject.eraseToAnyPublisher() }
    var laggingPublisher: AnyPublisher<Void, Never> { laggingSubject.eraseToAnyPublisher() }

    private let dataSubject = PassthroughSubject<RentedCharger, Never>()
    private let laggingSubject = PassthroughSubject<Void, Never>()

    private var messageReceiveDate: Date?
    private var timer: Timer?
    /// Destination currently subscribed to, i.e. the phone number of the rider the
    /// subscription belongs to.
    private var subscribedUserId: String?
    
    /// When the STOMP session last came up; nil while down. Logged on every
    /// close so an "automatic" disconnect can be read as "after N seconds".
    private var connectedAt: Date?
    
    init() {
        socketManager = SwiftStomp(host: URL(string: MimoBaseURLs.chargerSoket.rawValue)!)
        socketManager.autoReconnect = true
        socketManager.enableLogging = true
        socketManager.delegate = self
        MimoSocketLog.info(.charger, "init", "host=\(MimoBaseURLs.chargerSoket.rawValue) autoReconnect=true")
    }
    
    deinit {
        MimoSocketLog.info(.charger, "deinit", "isConnected=\(socketManager.isConnected)")
    }
    
    /// The backend pushes rent state to a destination named after the signed-in
    /// phone number (`SimpMessagingTemplate.convertAndSend(userId, ...)`), so the
    /// subscription has to follow whoever is signed in right now.
    func setupInitialSubscribers() {
        guard let phoneNumber = StorageManager().fetch(key: .phoneNumber, type: String.self) else {
            MimoSocketLog.error(.charger, "subscribe skipped", "no phone number stored")
            return
        }

        guard subscribedUserId != phoneNumber else { return }

        // This service lives for the whole app run, so a sign-out and sign-in as
        // somebody else would otherwise leave it listening on the previous
        // rider's destination and receiving nothing.
        if let subscribedUserId {
            MimoSocketLog.info(.charger, "unsubscribe", "destination=\(MimoSocketLog.masked(subscribedUserId))")
            socketManager.unsubscribe(from: subscribedUserId)
        }

        MimoSocketLog.info(.charger, "subscribe", "destination=\(MimoSocketLog.masked(phoneNumber))")
        socketManager.subscribe(to: phoneNumber)
        subscribedUserId = phoneNumber

        // The silence watchdog compares against the last message; with no
        // message ever received it had nothing to compare against and never
        // fired, so a subscription that delivered nothing also had no polling
        // fallback. Count from the subscription instead.
        if messageReceiveDate == nil {
            messageReceiveDate = Date()
        }

        // Start watching for silence as soon as there is something to listen to -
        // the screens use it to re-read state when the socket goes quiet. It used
        // to start only after the first message, so a subscription that never
        // delivered anything had no fallback at all.
        setupTimer()
    }

    func connect() {
        MimoSocketLog.info(.charger, "connect() requested", "isConnected=\(socketManager.isConnected) status=\(socketManager.connectionStatus)")
        if !self.socketManager.isConnected {
            // `SwiftStomp.connect()` overwrites `autoReconnect` with its own
            // parameter (default false), so the flag set in `init` was lost on
            // the first connect and a dropped socket - the app backgrounded
            // while the rider walked to the cabinet - never came back.
            self.socketManager.connect(autoReconnect: true)
        } else {
            // Already connected - `onConnect` will not fire again, so this is the
            // only chance to notice that the signed-in user changed.
            setupInitialSubscribers()
        }
    }
    
    private func setupTimer() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            if let messageReceiveDate = self?.messageReceiveDate {
                let differenceInSeconds = Int(Date().timeIntervalSince(messageReceiveDate))
                if differenceInSeconds >= 10 {
                    self?.delegate?.socketDataLagging()
                    self?.laggingSubject.send(())
                    MimoSocketLog.info(.charger, "data lagging", "lastMessage=\(differenceInSeconds)s ago isConnected=\(self?.socketManager.isConnected ?? false)")
                }
            }
        }
    }
}

extension MimoChargerSocketService: SwiftStompDelegate {
    
    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
        MimoSocketLog.info(.charger, "onConnect", "type=\(connectType)")
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
        MimoSocketLog.error(.charger, "onDisconnect", "type=\(disconnectType) up=\(MimoSocketLog.age(since: connectedAt)) lastMessage=\(MimoSocketLog.age(since: messageReceiveDate)) ago destination=\(MimoSocketLog.masked(subscribedUserId)) autoReconnect=\(swiftStomp.autoReconnect)")
        connectedAt = nil

        // The subscription dies with the connection; forgetting it here is what
        // lets `onConnect` re-subscribe instead of skipping it as a duplicate.
        subscribedUserId = nil

        delegate?.onDisconnect()
    }
    
    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers: [String : String]) {
        guard let message = message as? String else { return }
        MimoSocketLog.info(.charger, "message", "id=\(messageId) destination=\(MimoSocketLog.masked(destination)) bytes=\(message.utf8.count)")
        
        do {
            let jsonData = Data(message.utf8)
            let data = try JSONDecoder().decode(RentedCharger.self, from: jsonData)
            
            DispatchQueue.main.async {
                self.delegate?.onDataReceived(data)
                self.dataSubject.send(data)
            }
            
            messageReceiveDate = Date()
            setupTimer()
        } catch {
            MimoSocketLog.error(.charger, "message decode failed", "\(error)")
        }
    }
    
    func onReceipt(swiftStomp: SwiftStomp, receiptId: String) {
        MimoSocketLog.info(.charger, "onReceipt", "receiptId=\(receiptId)")
    }
    
    func onError(swiftStomp: SwiftStomp, briefDescription: String, fullDescription: String?, receiptId: String?, type: StompErrorType) {
        MimoSocketLog.error(.charger, "onError", "type=\(type) \(briefDescription): \(fullDescription ?? "-") receiptId=\(receiptId ?? "-") up=\(MimoSocketLog.age(since: connectedAt))")
    }
    
    func onSocketEvent(eventName: String, description: String) {
        MimoSocketLog.info(.charger, "onSocketEvent", "\(eventName): \(description)")
    }
}
