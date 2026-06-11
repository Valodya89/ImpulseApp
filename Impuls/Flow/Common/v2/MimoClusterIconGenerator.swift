//
//  MimoClusterIconGenerator.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 04.07.23.
//

import GoogleMapsUtils

class MimoClusterIconGenerator: NSObject, GMUClusterIconGenerator {
    
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
            let width = size == 1 ? 18 : (size <= 9 ? 22 : (size > 100 ? 28 : 32))
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
        view.setNeedsLayout()
        view.cornerRadius = iconSize.designedSize.height / 2
        view.borderWidth = 2
        view.borderColor = .white
        view.backgroundColor = .mimoDarkGray
        
        let image = UIImage(named: "mimo_m")
        let imageView = UIImageView(frame: frame)
        imageView.image = image
        imageView.transform = .init(scaleX: 0.5, y: 0.5)
        view.addSubview(imageView)
        
        return view.asImage
    }
}

extension UIView {

    var asImage: UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }

}
