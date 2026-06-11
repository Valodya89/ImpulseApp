//
//  ResponseWrapper.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.06.24.
//

import Foundation

struct ResponseWrapper<T: Decodable>: Decodable {
    var timestamp: String
    var statusCode: UInt
    var status: String
    var message: String
    var content: T?
    
    enum CodingKeys: CodingKey {
        case timestamp
        case statusCode
        case status
        case message
        case content
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: ResponseWrapper<T>.CodingKeys.self)
        self.timestamp = try container.decode(String.self, forKey: ResponseWrapper<T>.CodingKeys.timestamp)
        self.statusCode = try container.decode(UInt.self, forKey: ResponseWrapper<T>.CodingKeys.statusCode)
        self.status = try container.decode(String.self, forKey: ResponseWrapper<T>.CodingKeys.status)
        self.message = try container.decode(String.self, forKey: ResponseWrapper<T>.CodingKeys.message)
        self.content = try container.decodeIfPresent(T.self, forKey: ResponseWrapper<T>.CodingKeys.content)
    }
}
