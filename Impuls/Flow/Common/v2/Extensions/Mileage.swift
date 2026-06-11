//
//  Mileage.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.05.23.
//

import Foundation

extension Mileage {
    
    var prettyPrinted: String {
        let range = Double(self) / 1000
        let timeInMinutes = Int(range / 20 * 60) // default speed is 20km/h
        
        let hours = timeInMinutes / 60
        let minutes = timeInMinutes % 60
        
        var result = "≈"
        if hours > 0 {
            result.append(" ")
            result.append("\(hours)")
            result.append("SCOOTER_global_hour".localized())
        }
        
        if minutes > 0 {
            result.append(" ")
            result.append("\(minutes)")
            result.append("SCOOTER_global_minute".localized())
        }
        
        return "\(result) \(rangePrettyPrinted)"
    }
    
    var prettyPrintedWithoutRange: String {
        let range = Double(self) / 1000
        let timeInMinutes = Int(range / 20 * 60) // default speed is 20km/h
        
        let hours = timeInMinutes / 60
        let minutes = timeInMinutes % 60
        
        var result = "≈"
        if hours > 0 {
            result.append(" ")
            result.append("\(hours)")
            result.append("SCOOTER_global_hour".localized())
        }
        
        if minutes > 0 {
            result.append(" ")
            result.append("\(minutes)")
            result.append("SCOOTER_global_minute".localized())
        }
        
        return "\(result)"
    }
    
    var rangePrettyPrinted: String {
        let range = Double(self) / 1000
        
        return String(format: "(%.2f\("MOBILE_global_km".localized()))", range)
    }
}
