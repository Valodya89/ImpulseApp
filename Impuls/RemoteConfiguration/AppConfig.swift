//
//  AppConfig.swift
//  MimoBike
//
//  Created by Andrey Lupin on 01.02.26.
//

import Foundation

public struct AppConfig: Decodable, Equatable {
    var isInsuranceAvailable: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case isInsuranceAvailable
    }
    
    init() { }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.isInsuranceAvailable = try container.decode(Bool.self, forKey: .isInsuranceAvailable)
    }
}
