//
//  PlanCells.swift
//  MimoBike
//
//  Created by Dose on 6/5/21.
//

import UIKit

enum PlanCellTypes {
        
    case package
    case tarrif
    case student
    case extendTariff
    
    var type: UITableViewCell.Type {
        switch self {
        case .package:
            return PackageCell.self
        case .student:
            return StudentCell.self
        case .tarrif:
            return TarrifCell.self
        case .extendTariff:
            
            return TarrifEXTENDEDCell.self
        }
    }
    
    var nib: UINib {
        return UINib(nibName: String(describing: type.self), bundle: .main)
    }
}

final class PlanCells: UIView {

    private(set) var contentView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func commonInit(type: PlanCellTypes) {
        self.contentView = loadViewFromNib(typeView: type.type, from: String(describing: type.type))
    }
    
    func setup(_ model: PackageModel) {
        guard let packageView = self.contentView as? PackageCell else {
            return
        }
        
        packageView.setup(model, hideActiveButton: true)
    }

}
