//
//  GMSMapView+Theme.swift
//  Impuls
//
//  Applies a dark ("night mode") map style when the interface is dark and
//  restores the default (unstyled) look in light mode.
//

import UIKit
import GoogleMaps

extension GMSMapView {
    
    /// Standard Google Maps "night mode" style.
    static let darkStyleJSON: String = """
    [
      { "elementType": "geometry", "stylers": [ { "color": "#242f3e" } ] },
      { "elementType": "labels.text.fill", "stylers": [ { "color": "#746855" } ] },
      { "elementType": "labels.text.stroke", "stylers": [ { "color": "#242f3e" } ] },
      { "featureType": "administrative.locality", "elementType": "labels.text.fill", "stylers": [ { "color": "#d59563" } ] },
      { "featureType": "poi", "elementType": "labels.text.fill", "stylers": [ { "color": "#d59563" } ] },
      { "featureType": "poi.park", "elementType": "geometry", "stylers": [ { "color": "#263c3f" } ] },
      { "featureType": "poi.park", "elementType": "labels.text.fill", "stylers": [ { "color": "#6b9a76" } ] },
      { "featureType": "road", "elementType": "geometry", "stylers": [ { "color": "#38414e" } ] },
      { "featureType": "road", "elementType": "geometry.stroke", "stylers": [ { "color": "#212a37" } ] },
      { "featureType": "road", "elementType": "labels.text.fill", "stylers": [ { "color": "#9ca5b3" } ] },
      { "featureType": "road.arterial", "elementType": "geometry", "stylers": [ { "color": "#746855" } ] },
      { "featureType": "road.highway", "elementType": "geometry", "stylers": [ { "color": "#746855" } ] },
      { "featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [ { "color": "#1f2835" } ] },
      { "featureType": "road.highway", "elementType": "labels.text.fill", "stylers": [ { "color": "#f3d19c" } ] },
      { "featureType": "transit", "elementType": "geometry", "stylers": [ { "color": "#2f3948" } ] },
      { "featureType": "transit.station", "elementType": "labels.text.fill", "stylers": [ { "color": "#d59563" } ] },
      { "featureType": "water", "elementType": "geometry", "stylers": [ { "color": "#17263c" } ] },
      { "featureType": "water", "elementType": "labels.text.fill", "stylers": [ { "color": "#515c6d" } ] },
      { "featureType": "water", "elementType": "labels.text.stroke", "stylers": [ { "color": "#17263c" } ] }
    ]
    """
    
    /// Dark map style in dark mode, default (unstyled) map in light mode.
    /// Call after configuring the map and again from `traitCollectionDidChange(_:)`.
    /// Pass the owning view controller's trait collection from
    /// `traitCollectionDidChange(_:)`: the map view's own traits can still be
    /// the previous ones at that moment, which left the tiles unchanged.
    func applyAppearanceStyle(for traits: UITraitCollection? = nil) {
        let style = traits?.userInterfaceStyle ?? traitCollection.userInterfaceStyle
        let isDark: Bool
        switch ThemeManager.shared.theme {
        case .dark: isDark = true
        case .light: isDark = false
        case .system:
            isDark = style == .dark || (style == .unspecified && ThemeManager.shared.isDarkModeActive)
        }
        mapStyle = isDark ? (try? GMSMapStyle(jsonString: GMSMapView.darkStyleJSON)) : nil
    }
}
