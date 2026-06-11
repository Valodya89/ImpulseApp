//
//  Date+Extension.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 18.09.22.
//

import Foundation

extension Date {

    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }

}
