//
//  UIViewControllerExtension.swift
//  FittedSheets
//
//  Created by Gordon Tucker on 8/28/18.
//  Copyright © 2018 Gordon Tucker. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit

extension UIViewController {
    /// The sheet view controller presenting the current view controller heiarchy (if any)
    public var sheetViewController: SheetViewController? {
        var parent: UIViewController? = self//.parent
        while let currentParent = parent {
            if let sheetViewController = currentParent as? SheetViewController {
                return sheetViewController
            } else {
                parent = currentParent.parent
            }
        }
        return nil
    }
}

extension UIViewController {
    static func loadFromNib() -> Self {
        func instantiateFromNib<T: UIViewController>() -> T {
            return T.init(nibName: String(describing: T.self), bundle: nil)
        }
        
        return instantiateFromNib()
    }
}


#endif // os(iOS) || os(tvOS) || os(watchOS)
