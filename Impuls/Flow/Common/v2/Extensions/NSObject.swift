//
//  NSObject.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.05.23.
//

import Foundation

public extension NSObject {

    class var identifier: String {
        return String(describing: self)
    }
}
