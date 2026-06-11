//
//  DrawPolygone.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 30.07.22.
//

import UIKit

import GoogleMaps

class DrawPolygone: NSObject {

    static let shared = DrawPolygone()
        
    var polygons: GMSPolygon?
    var redPolygons: GMSPolygon?
    var greenPolygons: GMSPolygon?
    var yellowPolygons: GMSPolygon?
    
    func drawZone(mapZone: [Zone], mapView: GMSMapView) {
            //Add vertex's to Path like as shown bellow
            //get vertices from map
           // https://developers.google.com/maps/documentation/ios-sdk/shapes
        let redPath = GMSMutablePath()
        let greenPath = GMSMutablePath()
        let yellowPath = GMSMutablePath()
        
        for zoneItem in mapZone {
            print(zoneItem)
            guard let features = zoneItem.featureCollection?.features else {
              return
            }

            for item in features {
                let path = GMSMutablePath()
                if let zoneList = item.geometry?.coordinates?.first {
                    for value in zoneList  {
                        print("poligone value = \(value)")
                        path.add(CLLocationCoordinate2D(latitude: value.last ?? 0.0, longitude: value.first ?? 0.0))
    //                    path.addLatitude(value.first!, longitude: value.last!)
                        switch zoneItem.type?.rawValue ?? "" {
                        case "RESTRICTED":
                            yellowPath.add(CLLocationCoordinate2D(latitude: value.last ?? 0.0, longitude: value.first ?? 0.0))
                        case "FORBIDDEN":
                            redPath.add(CLLocationCoordinate2D(latitude: value.last ?? 0.0, longitude: value.first ?? 0.0))
                        case "RIDE":
                            greenPath.add(CLLocationCoordinate2D(latitude: value.last ?? 0.0, longitude: value.first ?? 0.0))
                        default :
                            break
                        }
                    }
                }
//                polygons = GMSPolygon(path: path)
//
//                polygons?.strokeColor = zoneItem.borderColor?.hexStringToUIColor() //?? UIColor.mimoGray500
//                polygons?.fillColor = zoneItem.color?.hexStringToUIColor().withAlphaComponent(0.16) ?? UIColor.mimoGreenLight.withAlphaComponent(0.30)
//                polygons?.strokeWidth = 2.0
//                polygons?.map = mapView
                
//                polygons = GMSPolygon(path: redPath)
//                polygons?.fillColor = zoneItem.color?.hexStringToUIColor().withAlphaComponent(0.16) ?? UIColor.mimoGreenLight.withAlphaComponent(0.30)
//                polygons?.strokeWidth = 2.0
//                polygons?.map = mapView
                
                
                let fillingPath = GMSMutablePath()
                fillingPath.add(CLLocationCoordinate2D(latitude: 90, longitude: -90))
                fillingPath.add(CLLocationCoordinate2D(latitude: 90, longitude: 90))
                fillingPath.add(CLLocationCoordinate2D(latitude: 0, longitude: 90))
                fillingPath.add(CLLocationCoordinate2D(latitude: 0, longitude: -90))
                
                let fillingPath2 = GMSMutablePath()
                fillingPath2.add(CLLocationCoordinate2D(latitude: 90, longitude: -90.01))
                fillingPath2.add(CLLocationCoordinate2D(latitude: 90.01, longitude: 90))
                fillingPath2.add(CLLocationCoordinate2D(latitude: 0, longitude: 90.01))
                fillingPath2.add(CLLocationCoordinate2D(latitude: 0, longitude: -90))
                
                let fillingPath3 = GMSMutablePath()
                fillingPath3.add(CLLocationCoordinate2D(latitude: 90, longitude: -90))
                fillingPath3.add(CLLocationCoordinate2D(latitude: 90, longitude: 90))
                fillingPath3.add(CLLocationCoordinate2D(latitude: -0.01, longitude: 90))
                fillingPath3.add(CLLocationCoordinate2D(latitude: -0.01, longitude: -90))
                
                let fillingPath4 = GMSMutablePath()
                fillingPath4.add(CLLocationCoordinate2D(latitude: 90, longitude: -90.01))
                fillingPath4.add(CLLocationCoordinate2D(latitude: 90, longitude: 90))
                fillingPath4.add(CLLocationCoordinate2D(latitude: -0.01, longitude: 90.01))
                fillingPath4.add(CLLocationCoordinate2D(latitude: -0.01, longitude: -90))
                
                let fillingPolygon = GMSPolygon(path: fillingPath)
                let fillColor = UIColor.mimoGreenLight.withAlphaComponent(0.1)
                fillingPolygon.fillColor = fillColor
                fillingPolygon.map = mapView
                
                let fillingPolygon2 = GMSPolygon(path: fillingPath2)
                fillingPolygon2.fillColor = fillColor
                fillingPolygon2.map = mapView
                
                let fillingPolygon3 = GMSPolygon(path: fillingPath3)
                fillingPolygon3.fillColor = fillColor
                fillingPolygon3.map = mapView
                
                let fillingPolygon4 = GMSPolygon(path: fillingPath4)
                fillingPolygon4.fillColor = fillColor
                fillingPolygon4.map = mapView
                
                fillingPolygon.holes = [greenPath]
                fillingPolygon2.holes = [greenPath]
                fillingPolygon3.holes = [greenPath]
                fillingPolygon4.holes = [greenPath]
                
                let line = GMSPolyline(path: greenPath)
                line.map = mapView
                line.strokeColor = UIColor.mimoGreenLight
                line.strokeWidth = 2
            }
        }
        
        yellowPolygons = GMSPolygon(path: yellowPath)
        greenPolygons = GMSPolygon(path: greenPath)
        redPolygons = GMSPolygon(path: redPath)
    }
    
    func isContain(coordinate: CLLocationCoordinate2D) -> Bool {
        
        guard let path = polygons?.path else { return false }
        
        return GMSGeometryContainsLocation(coordinate, path, true)
    }
    
    func isCanFinish(coordinate: CLLocationCoordinate2D) -> Bool {
        
        guard let redPath = redPolygons?.path else { return false }
        guard let grenPath = greenPolygons?.path else { return false }
        guard let yellowPath = yellowPolygons?.path else { return false }
        
        if GMSGeometryContainsLocation(coordinate, yellowPath, true) {
            return true
        }
        return false
    }
    
    func whichZoneClicked(coordinate: CLLocationCoordinate2D) -> String {
        
        guard let redPath = redPolygons?.path else { return "OUT" }
        guard let grenPath = greenPolygons?.path else { return "OUT" }
        guard let yellowPath = yellowPolygons?.path else { return "OUT" }
        
        if GMSGeometryContainsLocation(coordinate, yellowPath, true) {
            return "RESTRICTED"
        }
        
        if GMSGeometryContainsLocation(coordinate, redPath, true) {
            return "FORBIDDEN"
        }
        
        if GMSGeometryContainsLocation(coordinate, grenPath, true) {
            return "RIDE"
        }
        return "OUT"
    }
}
