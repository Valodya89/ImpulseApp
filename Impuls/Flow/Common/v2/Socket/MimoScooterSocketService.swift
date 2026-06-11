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
    
    init() {
        socketManager = SwiftStomp(host: URL(string: MimoBaseURLs.scooterSoket.rawValue)!)
        socketManager.autoReconnect = true
        socketManager.enableLogging = true
        socketManager.delegate = self
    }
    
    func setupInitialSubscribers() {
        guard let phoneNumber = StorageManager().fetch(key: .phoneNumber, type: String.self) else {
            return
        }
        
        self.socketManager.subscribe(to: phoneNumber)
        setupTimer()
    }
     
    func connect() {
        if !self.socketManager.isConnected {
            self.socketManager.connect()
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
                }
            } else {
                self?.delegate?.socketDataLagging()
            }
        }
    }
}

extension MimoScooterSocketService: SwiftStompDelegate {
    
    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
        if connectType == .toStomp {
            delegate?.onConnect()
            setupInitialSubscribers()
        }
    }
    
    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
        delegate?.onDisconnect()
    }
    
    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers: [String : String]) {
        guard let message = message as? String else { return }
        
        do {
            let jsonData = Data(message.utf8)
            let data = try JSONDecoder().decode(ScooterStateModel.self, from: jsonData)
            
            DispatchQueue.main.async {
                self.delegate?.onDataReceived(data)
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
        print("")
    }
    
    func onSocketEvent(eventName: String, description: String) {
        print("")
    }
}
