//
//  MessageService.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 05.06.23.
//

import Foundation

public class MessageService: MessageServiceProtocol {
    
    private var subscribers: [MessageKey: [SubscriberProtocol]] = [:]
    
    public init() {}
    
    public func subscribe(_ subscriber: SubscriberProtocol, for messages: MessageKey...) {
        for message in messages {
            if subscribers[message] == nil {
                subscribers[message] = []
            }
            subscribers[message]?.append(subscriber)
        }
    }
    
    public func unsubscribe(_ subscriber: SubscriberProtocol, from messages: MessageKey...) {
        for message in messages {
            if var subs = subscribers[message] {
                subs.removeAll { $0.id == subscriber.id }
                subscribers[message] = subs
            }
        }
    }
    
    public func publish(_ messages: MessageKey...) {
        for message in messages {
            if let subscribers = subscribers[message] {
                for subscriber in subscribers {
                    subscriber.receive(message: message)
                }
            }
        }
    }
}
