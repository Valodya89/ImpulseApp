//
//  PolygonDrawer.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 29.06.23.
//

import Foundation
import CoreLocation
import UIKit
class PolygonDrawer {
    
    public static let shared = PolygonDrawer()
    
    private var redPaths: [MimoMutablePath] = []
    private var yellowPath: MimoMutablePath = MimoMutablePath()
    private var greenPath: MimoMutablePath = MimoMutablePath()
    
    var ridePolygon: [MimoPolygon] = []
    var restrictedPolygon: [MimoPolygon] = []
    var forbiddenPolygon: [MimoPolygon] = []
    
    var forbiddenCoordinates: [[CLLocationCoordinate2D]] = []
    
    private init() {}
    
    func polygon(with zones: [Zone], withHoles: Bool) -> ZoneDrawerData {
        forbiddenCoordinates = []
        redPaths = []
        yellowPath = MimoMutablePath()
        greenPath = MimoMutablePath()
        
        ridePolygon = withHoles ? [.fillingPolygon1, .fillingPolygon2, .fillingPolygon3, .fillingPolygon4] : []
        forbiddenPolygon = []
        restrictedPolygon = []
        
        var ridePolylines: [MimoPolyline] = []
        var forbiddenPolylines: [MimoPolyline] = []
        var restrictedPolylines: [MimoPolyline] = []
        
        zones.enumerated().forEach { index, zone in
            let path = MimoMutablePath()
            let redPath = MimoMutablePath()
            let feature = zone.featureCollection?.features?.first
            let coordinates = feature?.geometry?.coordinates?.first ?? []
            
            coordinates.forEach({ coordinate in
                guard let latitude = coordinate.last, let longitude = coordinate.first else { return }
                path.add(.init(latitude: latitude, longitude: longitude))
                
                switch zone.type {
                case .RIDE:
                    self.greenPath.add(.init(latitude: latitude, longitude: longitude))
                case .RESTRICTED:
                    self.yellowPath.add(.init(latitude: latitude, longitude: longitude))
                case .FORBIDDEN:
                    redPath.add(.init(latitude: latitude, longitude: longitude))
                default:
                    break
                }
            })
            
            redPaths.append(redPath)
            
            if zone.type == .FORBIDDEN {
                forbiddenCoordinates.append(coordinates.compactMap({ CLLocationCoordinate2D(latitude: $0.last ?? 0, longitude: $0.first ?? 0) }))
            }
            
            if withHoles {
                ridePolygon.forEach({ $0.fillColor = UIColor.red.withAlphaComponent(0.2) })
                ridePolygon.forEach({ $0.holes?.append(path) })
            } else {
                let polygone = MimoPolygon(path: path)
                polygone.fillColor = UIColor.green.withAlphaComponent(0.2)
                ridePolygon.append(polygone)
            }
            
            let polygon1 = MimoPolygon(path: yellowPath)
            polygon1.fillColor = UIColor.mimoYellow500.withAlphaComponent(0.2)
            restrictedPolygon.append(polygon1)
            
            let polygone2 = MimoPolygon(path: redPath)
            polygone2.fillColor = UIColor.red.withAlphaComponent(0.2)
            forbiddenPolygon.append(polygone2)
            
            let ridePolyline = MimoPolyline(path: path)
            ridePolyline.strokeColor = zone.borderColor?.hexStringToUIColor() ?? .mimoGreen
            ridePolyline.strokeWidth = 2
            ridePolylines.append(ridePolyline)
            
            let forbiddenPolyline = MimoPolyline(path: redPath)
            forbiddenPolyline.strokeColor = UIColor.red
            forbiddenPolyline.strokeWidth = 2
            forbiddenPolylines.append(forbiddenPolyline)
            
            let restrictedPolyline = MimoPolyline(path: yellowPath)
            restrictedPolyline.strokeColor = UIColor.mimoYellow500
            restrictedPolyline.strokeWidth = 2
            restrictedPolylines.append(restrictedPolyline)
        }
        
        return ZoneDrawerData(
            ridePolygon: ridePolygon,
            restrictedPolygon: restrictedPolygon,
            forbiddenPolygon: forbiddenPolygon,
            ridePolyline: ridePolylines,
            restrictedPolyline: restrictedPolylines,
            forbiddenPolyline: forbiddenPolylines
        )
    }
    
    func zoneType(for coordinate: CLLocationCoordinate2D) -> ZoneType {
        for redPath in redPaths {
            if mimoGeometryContainsLocation(coordinate, redPath, true) {
                return .FORBIDDEN
            }
        }
        
        if mimoGeometryContainsLocation(coordinate, yellowPath, true) {
            return .RESTRICTED
        }
        
        if mimoGeometryContainsLocation(coordinate, greenPath, true) {
            return .RIDE
        }
        
        return .FORBIDDEN
    }
}

extension MimoPolygon {
    
    static var fillingPolygon1: MimoPolygon {
        let fillingPath = MimoMutablePath()
        fillingPath.add(CLLocationCoordinate2D(latitude: 90, longitude: -90))
        fillingPath.add(CLLocationCoordinate2D(latitude: 90, longitude: 90))
        fillingPath.add(CLLocationCoordinate2D(latitude: 0, longitude: 90))
        fillingPath.add(CLLocationCoordinate2D(latitude: 0, longitude: -90))
        
        let polygon = MimoPolygon(path: fillingPath)
        polygon.holes = []
        
        return polygon
    }
    
    static var fillingPolygon2: MimoPolygon {
        let fillingPath = MimoMutablePath()
        fillingPath.add(CLLocationCoordinate2D(latitude: 90, longitude: -90.01))
        fillingPath.add(CLLocationCoordinate2D(latitude: 90.01, longitude: 90))
        fillingPath.add(CLLocationCoordinate2D(latitude: 0, longitude: 90.01))
        fillingPath.add(CLLocationCoordinate2D(latitude: 0, longitude: -90))
        
        let polygon = MimoPolygon(path: fillingPath)
        polygon.holes = []
        
        return polygon
    }
    
    static var fillingPolygon3: MimoPolygon {
        let fillingPath = MimoMutablePath()
        fillingPath.add(CLLocationCoordinate2D(latitude: 90, longitude: -90))
        fillingPath.add(CLLocationCoordinate2D(latitude: 90, longitude: 90))
        fillingPath.add(CLLocationCoordinate2D(latitude: -0.01, longitude: 90))
        fillingPath.add(CLLocationCoordinate2D(latitude: -0.01, longitude: -90))
        
        let polygon = MimoPolygon(path: fillingPath)
        polygon.holes = []
        
        return polygon
    }
    
    static var fillingPolygon4: MimoPolygon {
        let fillingPath = MimoMutablePath()
        fillingPath.add(CLLocationCoordinate2D(latitude: 90, longitude: -90.01))
        fillingPath.add(CLLocationCoordinate2D(latitude: 90, longitude: 90))
        fillingPath.add(CLLocationCoordinate2D(latitude: -0.01, longitude: 90.01))
        fillingPath.add(CLLocationCoordinate2D(latitude: -0.01, longitude: -90))
        
        let polygon = MimoPolygon(path: fillingPath)
        polygon.holes = []
        
        return polygon
    }
    
    static var emptyPolygon: MimoPolygon {
        let emptyPath = MimoMutablePath()
        
        let polygon = MimoPolygon(path: emptyPath)
        
        return polygon
    }
}

struct ZoneDrawerData {
    let ridePolygon: [MimoPolygon]
    var restrictedPolygon: [MimoPolygon]
    var forbiddenPolygon: [MimoPolygon]
    
    var ridePolyline: [MimoPolyline]
    var restrictedPolyline: [MimoPolyline]
    var forbiddenPolyline: [MimoPolyline]
}
