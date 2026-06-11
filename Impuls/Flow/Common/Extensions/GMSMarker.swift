//
//  GMSMarker.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.05.23.
//

import Foundation
import GoogleMaps

extension GMSMarker {
    func isVisible(on map: GMSMapView) -> Bool {
        let padding: CGFloat = 0.0

        let point: CGPoint = map.projection.point(for: position)

        let condition1 = point.x >= -padding && point.y >= -padding
        let condition2 = point.x <= (map.frame.size.width + padding)
        let condition3 = point.y <= (map.frame.size.height + padding)

        if condition1 && condition2 && condition3 {
            return true
        }

        return false
    }
}
