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
    
    init() {
        socketManager = SwiftStomp(host: URL(string: MimoBaseURLs.chargerSoket.rawValue)!)
        socketManager.autoReconnect = true
        socketManager.enableLogging = true
        socketManager.delegate = self
    }
    
    /// The backend pushes rent state to a destination named after the signed-in
    /// phone number (`SimpMessagingTemplate.convertAndSend(userId, ...)`), so the
    /// subscription has to follow whoever is signed in right now.
    func setupInitialSubscribers() {
        guard let phoneNumber = StorageManager().fetch(key: .phoneNumber, type: String.self) else {
            return
        }

        guard subscribedUserId != phoneNumber else { return }

        // This service lives for the whole app run, so a sign-out and sign-in as
        // somebody else would otherwise leave it listening on the previous
        // rider's destination and receiving nothing.
        if let subscribedUserId {
            socketManager.unsubscribe(from: subscribedUserId)
        }

        socketManager.subscribe(to: phoneNumber)
        subscribedUserId = phoneNumber

        // Start watching for silence as soon as there is something to listen to -
        // the screens use it to re-read state when the socket goes quiet. It used
        // to start only after the first message, so a subscription that never
        // delivered anything had no fallback at all.
        setupTimer()
    }

    func connect() {
        if !self.socketManager.isConnected {
            self.socketManager.connect()
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
                print("\(Date()): \(differenceInSeconds)")
                if differenceInSeconds >= 10 {
                    self?.delegate?.socketDataLagging()
                    self?.laggingSubject.send(())
                    print("SOCKET: SOCKET DATA LOGGING")
                }
            }
        }
    }
}

extension MimoChargerSocketService: SwiftStompDelegate {
    
    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
        if connectType == .toStomp {
            delegate?.onConnect()
            setupInitialSubscribers()
        }
    }
    
    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
        // The subscription dies with the connection; forgetting it here is what
        // lets `onConnect` re-subscribe instead of skipping it as a duplicate.
        subscribedUserId = nil

        delegate?.onDisconnect()
    }
    
    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers: [String : String]) {
        guard let message = message as? String else { return }
        
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
            print(error.localizedDescription)
        }
    }
    
    func onReceipt(swiftStomp: SwiftStomp, receiptId: String) {
        
    }
    
    func onError(swiftStomp: SwiftStomp, briefDescription: String, fullDescription: String?, receiptId: String?, type: StompErrorType) {
        
    }
    
    func onSocketEvent(eventName: String, description: String) {
        
    }
}
