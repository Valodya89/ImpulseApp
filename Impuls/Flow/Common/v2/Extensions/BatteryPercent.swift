//
//  BatteryPercent.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.05.23.
//

import Foundation

extension BatteryPercent {
    
    var percentPrettyPrinted: String { "\(self)%" }
    
    var image: UIImage? {
        switch self {
        case 0...20: return .battery0
        case 21...40: return .battery25
        case 41...60: return .battery50
        case 61...80: return .battery75
        case 81...100: return .battery100
        default: return nil
        }
    }
    
    var scooterMarkerIcon: UIImage? {
        switch self {
            case 0...20: return #imageLiteral(resourceName: "ic_scooter_batarey_0")
            case 21...40: return #imageLiteral(resourceName: "ic_scooter_batarey_25")
            case 41...60: return #imageLiteral(resourceName: "ic_scooter_batarey_50")
            case 61...80: return #imageLiteral(resourceName: "ic_scooter_batarey_75")
            case 81...100: return #imageLiteral(resourceName: "ic_scooter_batarey_100")
            default: return nil
        }
    }
    
    var scooterMarkerSelectedIcon: UIImage? {
        switch self {
            case 0...20: return #imageLiteral(resourceName: "ic_scooter_batarey_big_0")
            case 21...40: return #imageLiteral(resourceName: "ic_scooter_batarey_big_25")
            case 41...60: return #imageLiteral(resourceName: "ic_scooter_batarey_big_50")
            case 61...80: return #imageLiteral(resourceName: "ic_scooter_batarey_big_75")
            case 81...100: return #imageLiteral(resourceName: "ic_scooter_batarey_big_100")
            default: return nil
        }
    }
}
