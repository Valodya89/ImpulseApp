//
//  MessageServiceProtocol.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 05.06.23.
//

import Foundation

public protocol MessageServiceProtocol {
    func subscribe(_ subscriber: SubscriberProtocol, for messages: MessageKey...)
    func unsubscribe(_ subscriber: SubscriberProtocol, from messages: MessageKey...)
    func publish(_ messages: MessageKey...)
}

public protocol SubscriberProtocol: AnyObject {
    var id: String { get set }
    func receive(message: MessageKey)
    func unsubscribe()
}
