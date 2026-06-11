//
//  Double+Extensions.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 3/16/25.
//

import Foundation

extension Double {
    var stringValue: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.roundingMode = .down
        formatter.locale = Locale(identifier: "en_US_POSIX")

        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.1f", self)
    }
    
    var stringValueRoundedUp2: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.roundingMode = .up
        formatter.locale = Locale(identifier: "en_US_POSIX")

        return formatter.string(from: NSNumber(value: self)) ?? String(format: "%.2f", ceil(self * 100) / 100)
    }
}
