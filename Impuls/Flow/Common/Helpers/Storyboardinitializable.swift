//
//  Storyboardinitializable.swift
//  MimoBike
//
//  Created by Vardan on 15.04.21.
//

import UIKit

protocol StoryboardInitializable {
    static var storyboardIdentifier: String { get }
}

extension StoryboardInitializable where Self: UIViewController {
    static var storyboardIdentifier: String {
        return String(describing: Self.self)
    }

    static func initFromStoryboard(name: String) -> Self {

        let storyboard = UIStoryboard(name: name, bundle: Bundle.main)
        return storyboard.instantiateViewController(withIdentifier: storyboardIdentifier) as! Self
    }
}


// MARK: - Reuse Identifiable

/// We can see that we need to create a property cellId and then pass it wherever it is needed. But how could make this code more succinct? Consider this protocol and extensions conforming to it:
protocol ReuseIdentifiable {
    static func reuseIdentifier() -> String
    static func reuseIdentifire(from tableView: UITableView, indexPath: IndexPath) -> Self
    static func reuseIdentifire(from collectionView: UICollectionView, indexPath: IndexPath) -> Self
}

extension ReuseIdentifiable {
    
    static func reuseIdentifier() -> String {
        return String(describing: self)
    }
    
    static func reuseIdentifire(from tableView: UITableView, indexPath: IndexPath) -> Self {
        
        return tableView.dequeueReusableCell(withIdentifier: String(describing: self), for: indexPath) as! Self
    }
    
    static func reuseIdentifire(from collectionView: UICollectionView, indexPath: IndexPath) -> Self {
        return collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: self), for: indexPath) as! Self
    }
}


// MARK: - UITableViewCell & UICollectionViewCell

extension UITableViewCell: ReuseIdentifiable {}
extension UICollectionViewCell: ReuseIdentifiable {}
