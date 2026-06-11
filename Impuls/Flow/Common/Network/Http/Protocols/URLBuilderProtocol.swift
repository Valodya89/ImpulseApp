//
//  URLBuilderProtocol.swift
//  MimoBike
//
//  Created by Albert on 17.05.21.
//

import Foundation

protocol URLBuilderProtocol {
    
    var request: URLRequest? { get }
   
    init(from api: APIProtocol)
    
    func buildURL(from api: APIProtocol)
    func getRequst() -> URLRequest?
    func rebuild()
}
