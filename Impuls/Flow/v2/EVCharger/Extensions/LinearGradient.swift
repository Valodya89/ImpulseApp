//
//  LinearGradient.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 24.02.25.
//

import SwiftUI

extension LinearGradient {
    static var evBrandGradientHorizontal: LinearGradient = LinearGradient(colors: [.evBrandBlue, .evBrandGreen], startPoint: .leading, endPoint: .trailing)
    static var evBrandGradientVertical: LinearGradient = LinearGradient(colors: [.evBrandBlue, .evBrandGreen], startPoint: .bottom, endPoint: .top)
    static var evBrandCyanGradientVertical: LinearGradient = LinearGradient(colors: [.evbrandCyan80.opacity(0.5), Color.init(hex: "#F2F2F2")], startPoint: .bottom, endPoint: .top)
}

