import Foundation
import UIKit
import CoreLocation
enum TeamEnergyProvider {

    static func loadLocations() -> [TeamEnergyLocation] {
        let lang = currentLanguageCode()
        if let primary = decode(language: lang) {
            return primary
        }
        if lang != "en", let english = decode(language: "en") {
            return english
        }
        return []
    }

    static func marker(for location: TeamEnergyLocation, animate: Bool) -> MimoMarker {
        let marker = MimoMarker()
        marker.position = location.coordinate
        marker.appearAnimation = animate ? .pop : .none
        marker.icon = markerIcon()
        marker.title = location.city
        marker.snippet = location.street
        marker.userData = location
        return marker
    }

    private static func markerIcon() -> UIImage? {
        UIImage(named: "teamenergy_marker") ?? UIImage(named: "evcharger_marker")
    }

    private static func currentLanguageCode() -> String {
        let stored = StorageManager().fetch(key: .language, type: String.self)
        let raw = (stored ?? Locale.current.languageCode ?? "en").lowercased()
        switch raw {
        case "hy", "ru", "en":
            return raw
        default:
            return "en"
        }
    }

    private static func decode(language: String) -> [TeamEnergyLocation]? {
        guard let url = Bundle.main.url(forResource: "locations-\(language)", withExtension: "json") else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([TeamEnergyLocation].self, from: data)
        } catch {
            print("TeamEnergyProvider: failed to decode locations-\(language).json — \(error)")
            return nil
        }
    }
}
