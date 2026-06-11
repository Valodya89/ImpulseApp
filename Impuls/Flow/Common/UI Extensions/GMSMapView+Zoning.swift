//
//  GMSMapView+Zoning.swift
//  MimoBike
//
//  Created by Dose on 7/5/21.
//

import UIKit
import GoogleMaps

extension GMSMapView {
    
    enum PolygonColor {
        case red
        case green
   
        var color: UIColor {
            switch self {
            case .red:
                return UIColor(red: 0.25, green: 0, blue: 0, alpha: 0.05);
            case .green:
                return UIColor(red: 0, green: 0.25, blue: 0, alpha: 0.05);

            }
        }
    }
    
    func drawPolygons(locations: [([CLLocationCoordinate2D], PolygonColor)]) {
        
        locations.forEach { item in
            let rect = GMSMutablePath()
            
            item.0.forEach { coordinate in
                rect.add(CLLocationCoordinate2D(latitude:coordinate.latitude, longitude: coordinate.longitude))
            }
            
            let polygon = GMSPolygon(path: rect)
            polygon.fillColor = item.1.color
            polygon.strokeColor = UIColor.init(hue: 210, saturation: 88, brightness: 84, alpha: 1)
            polygon.strokeWidth = 2
            polygon.map = self
        }
    }
    
    func drawCyrcle(zoningModels: [ZoningModel]) {
        zoningModels.forEach { model in
            let circle = GMSCircle(position: CLLocationCoordinate2D(latitude: model.latitude, longitude: model.longitude), radius: CLLocationDistance(model.radius))
            circle.fillColor = UIColor.init(red: CGFloat(model.color.red) / 255, green: CGFloat(model.color.green) / 255, blue: CGFloat(model.color.blue) / 255, alpha: CGFloat(model.color.alpha) / 255)
            circle.strokeColor = UIColor.init(red: CGFloat(model.color.red) / 255, green: CGFloat(model.color.green) / 255, blue: CGFloat(model.color.blue) / 255, alpha: CGFloat(model.color.alpha) / 255)
            circle.strokeWidth = 2
            circle.map = self

        }
    }
}

extension GMSMapView {
    func isMarkerVisible(onMap marker: GMSMarker?) -> Bool {
        let padding: Float = 0.0

        var point: CGPoint? = nil
        if let position = marker?.position {
            point = self.projection.point(for: position)
        }

        let x1 = (point?.x ?? 0.0) >= CGFloat(-padding) && (point?.y ?? 0.0) >= CGFloat(-padding)
        let x2 = (point?.x ?? 0.0) <= CGFloat(self.frame.size.width + CGFloat(padding))
        let x3 = (point?.y ?? 0.0) <= CGFloat(self.frame.size.height + CGFloat(padding))
        
        if x1 && x2 && x3 {
            return true
        }

        return false
    }
}
