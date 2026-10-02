//
//  Color.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.09.23.
//

import Foundation
import SwiftUI

extension Color {
    static var grayBackground = Color("grayBackground")
    static var black015 = Color.black.opacity(0.15)
    static var black025 = Color.black.opacity(0.25)
    static var black05 = Color.black.opacity(0.5)
    static var black075 = Color.black.opacity(0.75)
    static var black08 = Color.black.opacity(0.8)
    static var mimoRed500 = Color("mimoRed500")
    static var mimoYellow500 = Color("mimoYellow500")
    static var mimoDarkGray = Color("mimoDarkGray")
    
    static var headerTitleColor = Color("HeaderTitleColor")
    static var iconGray = Color("IconGray")
    static var red500 = Color("Red500")
    static var profileBackground = Color("ProfileBackground")
    static var packageStart = Color("PackageStart")
    static var packageEnd = Color("PackageEnd")
    
    static var grayBackgroundV2 = Color("GrayBackground")
    
    static var gray4 = Color("Gray4")
    static var gray5 = Color("Gray5")
    static var gray6 = Color("Gray6")
    static var gray8 = Color("Gray8")
    static var gray9 = Color("Gray9")
    
    static var black2 = Color("Black2")
    
    static var brandYellow = Color("BrandYellow")
    static var dividerColor = Color("DividerColor")
    
    static var successGreen = Color("SuccessGreen")
    static var errorRed = Color("ErrorRed")
    static var warningColor = Color("WarningColor")
    
    static var clearVision = Color("ClearVision")
    
    // MARK: - Semantic (light / dark aware) colors
    
    /// Primary screen / card background (white in light, dark gray in dark).
    static var appBackground = Color("AppBackground")
    /// Grouped canvas behind cards.
    static var appSecondaryBackground = Color("AppSecondaryBackground")
    /// Input / chip fill on top of a background.
    static var appFill = Color("AppFill")
    /// Primary text.
    static var appLabel = Color("AppLabel")
    /// Secondary text.
    static var appSecondaryLabel = Color("AppSecondaryLabel")
    /// Hairlines and dividers.
    static var appSeparator = Color("AppSeparator")
    /// Dimming layer behind sheets and popups.
    static var overlay = Color("Overlay")
    /// Fixed colors that must not change with the theme (content on brand colors, photos, maps).
    static var alwaysWhite = Color("AlwaysWhite")
    static var alwaysBlack = Color("AlwaysBlack")
    /// Text on the brand yellow / colored buttons.
    static var onBrandLabel = Color("OnBrandLabel")
    /// The two ends of the pulse in the app icon: orange into amber.
    static var brandPulseStart = Color("BrandPulseStart")
    static var brandPulseEnd = Color("BrandPulseEnd")
    static var onBrandSecondaryLabel = Color("OnBrandSecondaryLabel")
    /// Theme-aware replacements for the fixed black overlays above.
    static var label015 = Color("AppLabel").opacity(0.15)
    static var label025 = Color("AppLabel").opacity(0.25)
    static var label05 = Color("AppLabel").opacity(0.5)
    static var label075 = Color("AppLabel").opacity(0.75)

    // MARK: - Redesign tints (derived from the semantic set so they adapt)

    /// Highlight behind a selected row / chip.
    static var yellowTint = Color("BrandYellow").opacity(0.14)
    static var greenTint = Color("SuccessGreen").opacity(0.14)
    static var redTint = Color("ErrorRed").opacity(0.14)
    static var amberTint = Color("WarningColor").opacity(0.16)
    /// The legacy pale yellow; identical in light and dark, so prefer `yellowTint`.
    static var mimoYellow100 = Color("mimoYellow100")
}
