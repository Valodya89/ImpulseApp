//
//  Endpointable.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.06.24.
//

import Foundation

protocol Endpointable {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var parameters: Encodable? { get }
}

extension Endpointable {
    var headers: [String: String]? { nil }
    var parameters: Encodable? { nil }
}
