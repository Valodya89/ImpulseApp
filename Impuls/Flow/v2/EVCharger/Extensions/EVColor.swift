//
//  EVColor.swift
//  MimoBike
//
//  Created by Kirakosyan Yuri on 06.02.25.
//

import SwiftUI

extension Color {
    static var addresTypeGreen: Color = Color("addresTypeGreen")
    static var evGray4: Color = Color("EVgray4")
    static var evGray8: Color = Color("EVgray8")
    static var evGray12: Color = Color("EVgray12")
    static var evGray12_Green: Color = Color("EVgray12_green")
    static var evBrandYellow: Color = Color("EVBrandYellow")
    static var evBrandBlue: Color = Color("EVBrandBlue")
    static var evbrandCyan80: Color = Color("EvbrandCyan80")
    static var evBrandGreen: Color = Color("EVBrandGreen")
    static var evBgColor: Color = Color("EVBackgroundColor")
    static var evBgColor2: Color = Color("EVBackgroundColor2")
    static var evBgColor3: Color = Color("EVBackgroundColor3")
    static var evBgColor4: Color = Color("EVBackgroundColor4")
    static var evSheetBgColor: Color = Color("EVSheetBackgroundColor")
    static var evBgDark: Color = Color("EVBgDark")
    static var black60: Color = Color("Black60")
    
    static var evText6: Color = Color("EVText6")
    static var evText8: Color = Color("EVText8")
    static var evText9: Color = Color("EVText9")
    static var evTextDisabled: Color = Color("EVTextDisabled")
    static var evMainBg1: Color = Color("EVMainBg1")
    static var evMainBg2: Color = Color("EVMainBg2")
    static var evMainBgBlue: Color = Color("EVMainBgBlue")
    static var evBgDisabled: Color = Color("EVBgDisabled")
    static var evStroke: Color = Color("EVStroke")
    static var evDivider: Color = Color("EVDivider")
    static var evSuccess: Color = Color("EVSuccess")
    static var evSuccessTint: Color = Color("EVSuccessTint")
    static var evError: Color = Color("EVError")
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
