//
//  View+LoadFromNib.swift
//  Management App
//
//  Created by Vardan on 9/3/20.
//

import UIKit

extension UIView {
    
    @discardableResult
    func loadFromNib<T : UIView>() -> T? {
        guard let contentView = Bundle(for: type(of: self)).loadNibNamed(String(describing: self.classForCoder), owner: self, options: nil)?.first as? T else {
            // xib not loaded, or its top view is of the wrong type
            return nil
        }
        addSubviewSizedConstraints(view: contentView)
        return contentView
    }
    
    @discardableResult
    func loadViewsFromNib<T : UIView>() -> [T]? {
        guard let contentView = Bundle(for: type(of: self)).loadNibNamed(String(describing: self.classForCoder), owner: self, options: nil) as? [T] else {
            // xib not loaded, or its top view is of the wrong type
            return nil
        }
        return contentView
    }
    
    static func loadViewFromNib(named: String, owner: Any?, bundle: Bundle = .main) -> [UIView]? {
        return bundle.loadNibNamed(named, owner: owner, options: nil) as? [UIView]
    }
    
    @discardableResult
    func loadViewFromNib<T : UIView>(typeView: UIView.Type, from nibName: String) -> T? {
        guard let contentView = Bundle(for: type(of: self)).loadNibNamed(nibName, owner: self, options: nil) as? [T] else {
            // xib not loaded, or its top view is of the wrong type
            return nil
        }
        guard let view = contentView.first(where: { type(of: $0) == typeView}) else {
            return nil
        }
        addSubviewSizedConstraints(view: view)
        return view
    }
    
}
