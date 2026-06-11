//
//  UINavigationController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.08.23.
//

import Foundation

extension UIViewController {
    
    func addCloseButton() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(_closeAction))
    }
}

fileprivate extension UIViewController {
    
    @objc func _closeAction() {
        self.dismiss(animated: true)
    }
}
