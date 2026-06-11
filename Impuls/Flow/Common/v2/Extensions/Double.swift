//
//  Double.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 27.05.23.
//

import Foundation

extension Double {
    
    var radians: Double { self * .pi / 180 }
}

extension Double {
    var prettyDistance: String {
        guard self > -.infinity else { return "?" }
        
        let formatter = LengthFormatter()
        formatter.numberFormatter.maximumFractionDigits = 2
        
        if self >= 1000 {
            var distance = formatter.string(fromValue: self / 1000, unit: LengthFormatter.Unit.kilometer)
            distance = distance.replacingOccurrences(of: "km", with: "MOBILE_global_km".localized())
            return distance
        } else {
            let value = Double(Int(self))
            var distance = formatter.string(fromValue: value, unit: LengthFormatter.Unit.meter)
            distance = distance.replacingOccurrences(of: "m", with: "MOBILE__global_metr".localized())
            return distance
        }
    }
}
