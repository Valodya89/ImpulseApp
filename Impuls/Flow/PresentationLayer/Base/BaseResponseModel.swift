//
//  BaseResponseModel.swift
//  MimoBike
//
//  Created by Vardan on 03.05.21.
//

import Foundation

final class BaseResponseModel<T: Decodable>: Decodable {
    
    var timestamp: String
    var statusCode: UInt
    var status: String
    var message: String
    var content: T?
}
