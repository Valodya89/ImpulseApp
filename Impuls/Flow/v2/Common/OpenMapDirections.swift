//
//  OpenMapDirections.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 13.10.23.
//

import Foundation
import CoreLocation
import MapKit

class OpenMapDirections {
    
    static func present(in viewController: UIViewController, coordinate: CLLocationCoordinate2D) {
        
        let actionSheet = UIAlertController(title: nil, message: "MOBILE_direction_sheet_message".localized(), preferredStyle: .actionSheet)
        
        let yandexMapsAction = UIAlertAction(title: "Yandex Maps", style: .default) { _ in
            let url = URL(string: "yandexmaps://build_route_on_map/?lat_to=\(coordinate.latitude)&lon_to=\(coordinate.longitude)")!
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                if let url = URL(string: "https://yandex.ru/maps/?ll=\(coordinate.latitude),\(coordinate.longitude)&z=12&l=map") {
                    UIApplication.shared.open(url)
                }
            }
        }
        
        if let icon = UIImage(named: "yandex_maps_icon")?.resizeImage(targetSize: CGSize(width: 32, height: 32)) {
            yandexMapsAction.setValue(icon.withRenderingMode(.alwaysOriginal), forKey: "image")
        }
        
        let googleMapsAction = UIAlertAction(title: "Google Maps", style: .default) { _ in
            let url = URL(string: "comgooglemaps://?daddr=\(coordinate.latitude),\(coordinate.longitude))&directionsmode=driving&zoom=14&views=traffic")!
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                if let urlDestination = URL.init(string: "https://www.google.co.in/maps/dir/?saddr=&daddr=\(coordinate.latitude),\(coordinate.longitude)&directionsmode=driving") {
                    UIApplication.shared.open(urlDestination)
                }
            }
        }
        
        if let icon = UIImage(named: "google_maps_icon")?.resizeImage(targetSize: CGSize(width: 32, height: 32)) {
            googleMapsAction.setValue(icon.withRenderingMode(.alwaysOriginal), forKey: "image")
        }
        
        let appleMapsAction = UIAlertAction(title: "Apple Maps", style: .default) { _ in
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
            mapItem.name = "Mimo"
            mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
        }
        
        if let icon = UIImage(named: "apple_maps_icon")?.resizeImage(targetSize: CGSize(width: 32, height: 32)) {
            appleMapsAction.setValue(icon.withRenderingMode(.alwaysOriginal), forKey: "image")
        }
        
        actionSheet.addAction(yandexMapsAction)
        actionSheet.addAction(googleMapsAction)
        actionSheet.addAction(appleMapsAction)

        actionSheet.addAction(UIAlertAction(title: "MOBILE_global_cancel".localized(), style: .cancel, handler: nil))
        viewController.present(actionSheet, animated: true, completion: nil)
    }
}
