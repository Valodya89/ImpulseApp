//
//  UIImageView+Kingfisher.swift
//  MimoBike
//
//  Created by Albert on 20.05.21.
//

import UIKit
import SDWebImage

extension UIImageView {
    func setImage(_ urlString: String?, defaultImage: UIImage) {
        
        guard let urlString = urlString, !urlString.isEmpty else {
            self.image = defaultImage
            return
        }
        
        guard let url = URL(string: urlString) else {
            self.image = defaultImage
            return
        }
        
        self.sd_imageIndicator = SDWebImageActivityIndicator.grayLarge
        self.sd_setImage(with: url) { (image, error, type, url) in
            self.sd_imageIndicator?.stopAnimatingIndicator()
            if error != nil {
                self.image = defaultImage
            }
        }
    }
    
//    func setImageWithoutCache(_ urlString: String?, defaultImage: UIImage) {
//        guard let urlString = urlString, !urlString.isEmpty else {
//            self.image = defaultImage
//            return
//        }
//        
//        guard let url = URL(string: urlString) else {
//            self.image = defaultImage
//            return
//        }
//        
//        let activityIndicatorView = UIActivityIndicatorView()
//        self.addSubview(activityIndicatorView)
//        activityIndicatorView.translatesAutoresizingMaskIntoConstraints = false
//        activityIndicatorView.centerXAnchor.constraint(
//            equalTo: self.centerXAnchor, constant: 0).isActive = true
//        activityIndicatorView.centerYAnchor.constraint(
//            equalTo: self.centerYAnchor, constant: 0).isActive = true
//        
//        activityIndicatorView.startAnimating()
//        activityIndicatorView.hidesWhenStopped = true
//        ImageDownloader.default.downloadImage(with: url) { [weak self]result in
//            activityIndicatorView.stopAnimating()
//            switch result {
//            case .success(let value):
//                self?.image = value.image
//            case .failure(let error):
//                print(error)
//            }
//        }
//    }
}
