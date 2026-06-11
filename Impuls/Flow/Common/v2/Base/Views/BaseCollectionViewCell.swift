//
//  BaseCollectionViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.05.23.
//

import Foundation
import UIKit

open class BaseCollectionViewCell: UICollectionViewCell, ReusableView, NibLoadableView {
    public var indexPath: IndexPath?
}
