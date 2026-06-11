//
//  ZoningModel.swift
//  MimoBike
//
//  Created by Dose on 7/14/21.
//

import UIKit

struct ZoningModel: Codable {
    
    struct ZoningColor: Codable {
        let alpha: Int
        let blue: Int
        let green: Int
        let red: Int
    }
    
    enum ZoningType {
        case red,green,yellow
        
        init?(from value: String) {
            switch value {
            case "RED":
                self = .red
            case "YELLOW":
                self = .yellow
            case "GREEN":
                self = .green
            default:
                return nil
            }
        }
    }
    
    var bonus: Int
    var color: ZoningColor
    var description: String
    var id: String
    var latitude: Double
    var longitude: Double
    var name: String
    var radius: Int
    var type: String
    
    var typeEnum: ZoningType? {
        return ZoningType.init(from: type)
    }
    
}
