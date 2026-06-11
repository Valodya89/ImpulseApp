//
//  CustomMarker.swift
//  MimoBike
//
//  Created by Karen Galoyan on 7/19/22.
//

import UIKit

class CustomMarker: UIView {

    @IBOutlet weak var markerImageView: UIImageView!
    @IBOutlet weak var battaryImageView: UIImageView!
    
    func customInit(markerImage: UIImage, batteryImage: UIImage? = nil) {
        markerImageView.image = markerImage
        if batteryImage != nil {
            battaryImageView.image = batteryImage!
        }
    }
}
