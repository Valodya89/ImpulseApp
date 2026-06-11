//
//  Dictionary+Extension.swift
//  MimoBike
//
//  Created by Andrey Lupin on 01.02.26.
//

import Foundation

public extension Dictionary where Key: ExpressibleByStringLiteral, Value: Any {
    var jsonData: Data? {
        return try? JSONSerialization.data(withJSONObject: self, options: [])
    }
}

public extension Dictionary {
    
    static func += (lhs: inout Dictionary, rhs: Dictionary) {
        lhs.merge(rhs) { (_, new) in new }
    }
}
