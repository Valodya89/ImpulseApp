//
//  DateFormatter.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.04.24.
//

import Foundation

extension DateFormatter {
    
    static var fullDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        
        return formatter
    }
    
    static var dayMonthYearFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "dd.MM.yyyy"
        
        return formatter
    }
    
    static var dayMonthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "dd:MM"
        
        return formatter
    }
    
    static var hoursMinutesFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm"
        
        return formatter
    }
}
