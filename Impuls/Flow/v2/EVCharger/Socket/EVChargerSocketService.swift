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
    
    weak var delegate: EVChargerSocketServiceDelegate?
    
    init() {
        socketManager = SwiftStomp(host: URL(string: MimoBaseURLs.evChargerSoket.rawValue)!)
        socketManager.autoReconnect = true
        socketManager.delegate = self
        socketManager.enableLogging = true
    }
    
    deinit {
        print("==SOCKET DEINIT EVChargerSocketService")
        if self.socketManager.isConnected {
            print("==SOCKET DEINIT EVChargerSocketService disconnect")
            socketManager.disconnect()
        }
    }
     
    func connect() {
        if !self.socketManager.isConnected {
            self.socketManager.connect()
        }
    }
    
    func disconnect() {
        if self.socketManager.isConnected {
            self.socketManager.disconnect()
            print("AAA DISCONNECT")
        }
    }
    
    func subscribeToBikeStateUpdate() {
        guard let phoneNumber = StorageManager().fetch(key: .phoneNumber, type: String.self) else {
            return
        }
        
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
                print("\(Date()): \(differenceInSeconds)")
                if differenceInSeconds >= 15 {
                    self?.delegate?.socketDataLagging()
                    print("==SOCKET: socketDataLagging")
                }
            }
        }
    }
}

extension EVChargerSocketService: SwiftStompDelegate {
    
    func onConnect(swiftStomp: SwiftStomp, connectType: StompConnectType) {
        print("==SOCKET Socket onConnect")
        
        if connectType == .toStomp {
            delegate?.onConnect()
            subscribeToBikeStateUpdate()
        }
    }
    
    func onDisconnect(swiftStomp: SwiftStomp, disconnectType: StompDisconnectType) {
        print("==SOCKET Socket onDisconnect")
        
        delegate?.onDisconnect()
    }
    
    func onMessageReceived(swiftStomp: SwiftStomp, message: Any?, messageId: String, destination: String, headers: [String : String]) {
        guard let message = message as? String else { return }
        print("==SOCKET Socket message: \(message)")
        
        do {
            let jsonData = Data(message.utf8)
            let data = try JSONDecoder().decode(EVSocketResponse.self, from: jsonData)
            
            delegate?.evChargerStateDataReceived(data)
            sendAcknowledgment(messageId: data.id)
            
            messageReceiveDate = Date()
            setupTimer()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func onReceipt(swiftStomp: SwiftStomp, receiptId: String) {
        print("==SOCKET Socket onReceipt")
        
        print(#function)
    }
    
    func onError(swiftStomp: SwiftStomp, briefDescription: String, fullDescription: String?, receiptId: String?, type: StompErrorType) {
        print("==SOCKET Socket onError")
        
        print(#function)
    }
    
    func onSocketEvent(eventName: String, description: String) {
        print("==SOCKET onsetocketevent eventName:\(eventName) description:\(description)")
        print(#function)
    }
}
