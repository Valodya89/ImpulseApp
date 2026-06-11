//
//  SessionProtocol.swift
//  MimoBike
//
//  Created by Albert on 17.05.21.
//

import Foundation

protocol SessionProtocol {
    func request(with builderProtocol: URLBuilderProtocol, _ completion: @escaping (Result<Data,NetworkSessionErrors>) -> (), _ queue: DispatchQueue)
}
