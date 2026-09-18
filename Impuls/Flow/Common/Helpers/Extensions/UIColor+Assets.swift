//
//  UIColor+Assets.swift
//  MimoBike
//
//  Created by Vardan on 15.04.21.
//

import UIKit

extension UIColor {
    
    static let mimoGray100: UIColor = UIColor(named: "mimoGray100")!
    static let mimoGray100With025alpha: UIColor = UIColor(named: "mimoGray100With025alpha")!
    static let mimoGray500: UIColor = UIColor(named: "mimoGray500")!
    static let deepOrange100: UIColor = UIColor(named: "deepOrange100")!
    static let deepOrange500: UIColor = UIColor(named: "deepOrange500")!
    static let mimoAmber100: UIColor = UIColor(named: "mimoAmber100")!
    static let mimoAmber500: UIColor = UIColor(named: "mimoAmber500")!
    static let mimoBlack: UIColor = UIColor(named: "mimoBlack")!
    static let mimoBlackWith075alpha: UIColor = UIColor(named: "mimoBlackWith075alpha")!
    static let mimoBlackWith05alpha: UIColor = UIColor(named: "mimoBlackWith05alpha")!
    static let mimoBlackWith03alpha: UIColor = UIColor(named: "mimoBlackWith03alpha")!
    static let mimoBlackWith025alpha: UIColor = UIColor(named: "mimoBlackWith025alpha")!
    static let mimoBlackWith01alpha: UIColor = UIColor(named: "mimoBlackWith01alpha")!
    static let mimoGreen: UIColor = UIColor(named: "mimoGreen")!
    static let mimoGreenLight: UIColor = UIColor(named: "mimoGreenLight")!
    static let mimoRed100: UIColor = UIColor(named: "mimoRed100")!
    static let mimoRed500: UIColor = UIColor(named: "mimoRed500")!
    static let mimoWhite: UIColor = UIColor(named: "mimoWhite")!
    static let mimoYellow100: UIColor = UIColor(named: "mimoYellow100")!
    static let mimoYellow500: UIColor = UIColor(named: "mimoYellow500")!
    static let borderColor: UIColor = UIColor(named: "borderColor")!
    static let zoneColor: UIColor = UIColor(named: "zoneColor")!
    static let selectedSpeed: UIColor = UIColor(named: "selectedSpeed")!
    static let unSelectedSpeed: UIColor = UIColor(named: "unSelectedSpeed")!
    static let mimoDarkGray: UIColor = UIColor(named: "mimoDarkGray")!
    static let zoneGreen: UIColor = UIColor(named: "zoneGreen")!
    static let zoneRed: UIColor = UIColor(named: "zoneRed")!
    static let grayBackground: UIColor = UIColor(named: "GrayBackground")!
    
    // MARK: - Semantic (light / dark aware) colors
    
    /// Primary screen / card background (white in light, dark gray in dark).
    static let appBackground: UIColor = UIColor(named: "AppBackground")!
    /// Grouped canvas behind cards (very light gray in light, near black in dark).
    static let appSecondaryBackground: UIColor = UIColor(named: "AppSecondaryBackground")!
    /// Input / chip fill on top of a background.
    static let appFill: UIColor = UIColor(named: "AppFill")!
    /// Primary text.
    static let appLabel: UIColor = UIColor(named: "AppLabel")!
    /// Secondary text.
    static let appSecondaryLabel: UIColor = UIColor(named: "AppSecondaryLabel")!
    /// Hairlines and dividers.
    static let appSeparator: UIColor = UIColor(named: "AppSeparator")!
    /// Dimming layer behind sheets and popups.
    static let overlay: UIColor = UIColor(named: "Overlay")!
    /// Fixed colors that must not change with the theme (content on brand colors, photos, maps).
    static let alwaysWhite: UIColor = UIColor(named: "AlwaysWhite")!
    static let alwaysBlack: UIColor = UIColor(named: "AlwaysBlack")!
    /// Text on the brand yellow / colored buttons.
    static let onBrandLabel: UIColor = UIColor(named: "OnBrandLabel")!
    static let onBrandSecondaryLabel: UIColor = UIColor(named: "OnBrandSecondaryLabel")!
}
