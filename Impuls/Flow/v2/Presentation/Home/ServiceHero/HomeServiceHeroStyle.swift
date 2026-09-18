//
//  HomeServiceHeroStyle.swift
//  Impuls
//
//  What each product's home card looks like: its name, headline, chip icon,
//  the pin drawn on the map picture and the accent of its "Open map" pill.
//  Everything else about the card is shared, so the row of services reads as
//  one family whatever the market offers.
//

import SwiftUI

struct HomeServiceHeroStyle {

    enum Accent {
        /// Impuls yellow with dark text - scooters, bikes, power banks.
        case yellow
        /// The EV module's blue-to-green gradient with white text.
        case evGradient
    }

    let product: MimoProductType
    /// The product name in the top-left chip.
    let title: String
    /// The card's headline ("Ride a scooter").
    let headline: String
    /// Plural noun for the count in the summary line ("scooters").
    let unit: String
    let iconName: String
    /// Template icons are tinted with `iconTint`; the others are drawn as they are.
    let iconIsTemplate: Bool
    let iconTint: Color
    let markerImageName: String
    /// Drawn centred in the pin head when the pin asset is a plain background.
    let markerOverlayImageName: String?
    /// Whether "N available" says something the site count does not (power
    /// banks in cabinets, free plugs on stations). A scooter is its own site.
    let showsAvailabilityChip: Bool
    let accent: Accent

    static func style(for product: MimoProductType) -> HomeServiceHeroStyle {
        switch product {
        case .scooter:
            return HomeServiceHeroStyle(
                product: product,
                title: "SCOOTER_global_title".localized(fallback: "Scooter"),
                headline: "MOBILE_home_hero_scooter_title".localized(fallback: "Ride a scooter"),
                unit: "MOBILE_home_hero_scooters".localized(fallback: "scooters"),
                iconName: "ic_scooter",
                iconIsTemplate: true,
                iconTint: .brandYellow,
                markerImageName: "ic_scooter_marker",
                markerOverlayImageName: nil,
                showsAvailabilityChip: false,
                accent: .yellow
            )
        case .bike:
            return HomeServiceHeroStyle(
                product: product,
                title: "SHARING_global_title".localized(fallback: "Bike"),
                headline: "MOBILE_home_hero_bike_title".localized(fallback: "Ride a bike"),
                unit: "MOBILE_home_hero_bikes".localized(fallback: "bikes"),
                iconName: "mimo_product_bike",
                iconIsTemplate: false,
                iconTint: .brandYellow,
                markerImageName: "ic_bike_marker",
                markerOverlayImageName: nil,
                showsAvailabilityChip: false,
                accent: .yellow
            )
        case .charger:
            return HomeServiceHeroStyle(
                product: product,
                title: "MOBILE_charger_title".localized(fallback: "Power bank"),
                headline: "MOBILE_home_hero_charger_title".localized(fallback: "Rent a power bank"),
                unit: "MOBILE_home_hero_stations".localized(fallback: "stations"),
                // The power-bank artwork is black on the dark chip; as a
                // template it reads like the scooter glyph.
                iconName: "station",
                iconIsTemplate: true,
                iconTint: .brandYellow,
                markerImageName: "charger_marker_background",
                markerOverlayImageName: "charger_marker_circle_background",
                showsAvailabilityChip: true,
                accent: .yellow
            )
        case .evCharger:
            return HomeServiceHeroStyle(
                product: product,
                title: "CHARGER_ev_title".localized(fallback: "EV Charging"),
                headline: "EV_CHARGER_home_hero_title".localized(fallback: "Charge your EV"),
                unit: "EV_CHARGER_home_hero_stations".localized(fallback: "stations"),
                iconName: "ev_flash_fill",
                iconIsTemplate: true,
                iconTint: .evBrandYellow,
                markerImageName: "evcharger_marker",
                markerOverlayImageName: nil,
                showsAvailabilityChip: true,
                accent: .evGradient
            )
        }
    }
}
