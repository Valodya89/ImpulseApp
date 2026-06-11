//
//  NotificationListResponse.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 11.08.21.
//

import Foundation

struct NotificationListResponse: Codable {
    var id: String?
//    var users: [String]?
    var type: String?
    var metadata: Metadata?
    var content: NotificationContent?
    var date: Double?
}


struct Metadata: Codable {
    var action: String?
}

struct Message: Codable {
    var title: String
    var content: String
}

struct NotificationContent: Codable {
    var en: Message?
    var ru: Message?
    var hy: Message?
}
