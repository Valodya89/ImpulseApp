//
//  SizedTableView.swift
//  LazerApplication
//
//  Created by Dose on 5/26/20.
//  Copyright © 2020 Dose. All rights reserved.
//

import UIKit

final class SizedTableView: UITableView {
    
    @IBInspectable var manualInvalidation: Bool = false
    @IBInspectable var maxHeight: CGFloat = CGFloat.infinity

    @IBOutlet weak var bottomSeparator: UIView?
        
    override func reloadData() {
        DispatchQueue.main.async {
            self.layoutIfNeeded()
        }
        
        super.reloadData()
        if !manualInvalidation {
            self.invalidateIntrinsicContentSize()
            DispatchQueue.main.async {
                self.layoutIfNeeded()
            }
        }
    }
    
    override var intrinsicContentSize: CGSize {
        setNeedsLayout()
        DispatchQueue.main.async {
            self.layoutIfNeeded()
        }
        
        let heightSized = contentSize.height
        let height = min(heightSized, maxHeight) + contentInset.bottom + contentInset.top
        return CGSize(width: contentSize.width, height: height)
    }
}
