//
//  Routable.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 07.03.25.
//

import Foundation
import SwiftUI

public protocol Routable: Hashable, Identifiable {
    associatedtype ContentView: View
    var id: String { get }
    var contentView: ContentView { get }
}

extension Routable {
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
