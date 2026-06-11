//
//  UIStoryboard.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 04.05.23.
//

import Foundation

public extension UIStoryboard {
    
    func instantiate<T: UIViewController>(_ type: T.Type) -> T? {
        instantiateViewController(withIdentifier: type.identifier) as? T
    }
    
    func instantiate<T: UIViewController>() -> T? {
        instantiateViewController(withIdentifier: T.identifier) as? T
    }
}
