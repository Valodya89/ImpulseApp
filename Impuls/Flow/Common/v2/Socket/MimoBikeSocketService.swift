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
    
    weak var delegate: MimoBikeSocketServiceDelegate?
    
    init() {
        socketManager = SwiftStomp(host: URL(string: MimoBaseURLs.socket.rawValue)!)
        socketManager.autoReconnect = true
        socketManager.delegate = self
        socketManager.enableLogging = true
    }
     
    func connect() {
        if !self.socketManager.isConnected {
            self.socketManager.connect()
        }
    }
    
    func subscribeToBikesUpdate() {
        self.socketManager.subscribe(to: "bikes")
    }
    
    func subscribeToBikeStateUpdate() {
        guard let phoneNumber = StorageManager().fetch(key: .phoneNumber, type: String.self) else {
            return
        }
        
        self.socketManager.subscribe(to: phoneNumber)
    }
    
    private func setupTimer() {
        guard timer == nil else { return }
        
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            if let messageReceiveDate = self?.messageReceiveDate {
                let differenceInSeconds = Int(Date().timeIntervalSince(messageReceiveDate))
                print("\(Date()): \(differenceInSeconds)")
                if differenceInSeconds >= 15 {
                    self?.delegate?.socketDataLagging()
                    print("SOCKET: socketDataLagging")
                }
            }
        }
    }
}

extension MimoBikeSocketService: SwiftStompDelegate {
    
    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
        if connectType == .toStomp {
            delegate?.onConnect()
            subscribeToBikeStateUpdate()
            subscribeToBikesUpdate()
        }
    }
    
    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
        delegate?.onDisconnect()
    }
    
    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers: [String : String]) {
        guard let message = message as? String else { return }
        
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
        print(#function)
    }
    
    func onError(swiftStomp: SwiftStomp, briefDescription: String, fullDescription: String?, receiptId: String?, type: StompErrorType) {
        print(#function)
    }
    
    func onSocketEvent(eventName: String, description: String) {
        print(#function)
    }
}
