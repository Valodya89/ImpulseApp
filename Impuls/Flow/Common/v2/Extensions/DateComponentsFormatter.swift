//
//  DateComponentsFormatter.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 08.06.23.
//

import Foundation

extension DateComponentsFormatter {
    
    static var hmsFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        
        return formatter
    }
    
    static var msFormatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = [.pad]
        
        return formatter
    }
}
