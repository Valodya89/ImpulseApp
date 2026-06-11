//
//  ReusableView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.05.23.
//

import Foundation
import UIKit

public protocol ReusableView: AnyObject {
    
    var indexPath: IndexPath? { get set }
    static var reuseIdentifier: String { get }
}

public protocol NibLoadableView: AnyObject {
    
    static var nibName: String { get }
}

extension ReusableView where Self: UIView {
    
    public static var reuseIdentifier: String {
        return String(describing: self)
    }
}

extension NibLoadableView where Self: UIView {
    
    public static var nibName: String {
        return String(describing: self)
    }
}

extension UITableView {
    
    public func register<T: UITableViewCell>(_: T.Type) where T: ReusableView {
        register(T.self, forCellReuseIdentifier: T.reuseIdentifier)
    }
    
    public func registerHeaderFooterView<T: UITableViewHeaderFooterView>(_: T.Type) where T: ReusableView {
        
        register(T.self, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
    }
    
    public func register<T: UITableViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView {
        
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        register(nib, forCellReuseIdentifier: T.reuseIdentifier)
    }
    
    public func registerHeaderFooterView<T: UITableViewHeaderFooterView>(_: T.Type) where T: ReusableView, T: NibLoadableView {
        
        register(T.self, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
        
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        register(nib, forHeaderFooterViewReuseIdentifier: T.reuseIdentifier)
    }
    
    public func dequeueReusableCell<T: UITableViewCell>(for indexPath: IndexPath) -> T where T: ReusableView {
        
        guard
            let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
                fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        cell.indexPath = indexPath
        
        return cell
    }
    
    public func dequeueReusableCell<T: UITableViewCell>(withIdentifier identifier: String) -> T where T: ReusableView {
        guard
            let cell = dequeueReusableCell(withIdentifier: T.reuseIdentifier) as? T else {
                fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        
        return cell
    }
    
    public func dequeueReusableHeaderFooterView<T: UITableViewHeaderFooterView>() -> T where T: ReusableView {
        
        guard
            let headerFooterView = dequeueReusableHeaderFooterView(withIdentifier: T.reuseIdentifier) as? T else {
                fatalError("Could not dequeue HeaderFooterView with identifier: \(T.reuseIdentifier)")
        }
        
        return headerFooterView
    }
}

extension UICollectionView {
    
    public func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView {
        register(T.self, forCellWithReuseIdentifier: T.reuseIdentifier)
    }
    
    public func register<T: UICollectionViewCell>(_: T.Type) where T: ReusableView, T: NibLoadableView {
        
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        register(nib, forCellWithReuseIdentifier: T.reuseIdentifier)
    }
    
    public func registerReusableView<T: UICollectionReusableView>(_: T.Type, kind: String) where T: ReusableView, T: NibLoadableView {
        
        register(T.self, forSupplementaryViewOfKind: kind, withReuseIdentifier: T.reuseIdentifier)
        
        let bundle = Bundle(for: T.self)
        let nib = UINib(nibName: T.nibName, bundle: bundle)
        
        register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: T.reuseIdentifier)
    }
    
    public func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T where T: ReusableView {
        
        guard
            let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
                fatalError("Could not dequeue cell with identifier: \(T.reuseIdentifier)")
        }
        
        return cell
    }
    
    public func dequeueCollectionReusableView<T: UICollectionReusableView>(with kind: String, indexPath: IndexPath) -> T where T: ReusableView {
        
        guard
            let reuableView = dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
                fatalError("Could not dequeue reusableView with identifier: \(T.reuseIdentifier)")
        }
        
        return reuableView
    }
}
