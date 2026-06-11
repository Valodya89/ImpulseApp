//
//  EVClusterIconGenerator.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 9/25/25.
//

import GoogleMapsUtils

class EVClusterIconGenerator: NSObject, GMUClusterIconGenerator {
    
    private struct IconSize {
        let size: UInt
        
        /**
         Returns designed title from cluster's size
         */
        var designedTitle: String {
            return size == 1 ? "" : (size > 100 ? "∞" : "\(size)")
        }
        
        /**
         Returns initial `CGSize` multiplied by recursively created multiplier
         */
        var designedSize: CGSize {
            let width = size == 1 ? 22 : (size <= 9 ? 26 : (size > 100 ? 32 : 36))
            let height = width
            return CGSize(width: width, height: height)
        }
    }
    
    /**
     Returns image based on current cluster's size
     */
    func icon(forSize size: UInt) -> UIImage! {
        let iconSize = IconSize(size: size)
        
        let frame = CGRect(origin: .zero, size: iconSize.designedSize)
        
        let view = UIView(frame: frame)

        let image = UIImage(named: "evcharger_marker_cluster")
        let imageView = UIImageView(frame: frame)
        imageView.image = image
        view.addSubview(imageView)
        
        let label = UILabel(frame: frame)
        label.text = iconSize.designedTitle
        label.textColor = .white
        label.font = UIFont(name: Constant.Font.robotoBold, size: 12)
        label.textAlignment = .center
        imageView.addSubview(label)
        
        return view.asImage
    }
}
