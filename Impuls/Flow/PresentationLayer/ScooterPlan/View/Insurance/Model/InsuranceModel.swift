//
//  InsuranceModel.swift
//  MimoBike
//
//  Created by Yurka Babayan on 19.09.25.
//

import Foundation

struct InsuranceModel: Identifiable {
    let id = UUID().uuidString
    var text: String
    var url: String
    
    init(text: String, url: String) {
        self.text = text.localized()
        self.url = url
    }
}

struct InsuranceResponceModel: Decodable {
    
}

struct InsurancePriceResponceModel: Decodable {
    let price: Double
}

//{
//  "status" : "OK",
//  "statusCode" : 200,
//  "timestamp" : "2025-11-19T19:36:55.105+00:00",
//  "message" : "SUCCESS",
//  "content" : {
//    "price" : 300
//  }
//}
