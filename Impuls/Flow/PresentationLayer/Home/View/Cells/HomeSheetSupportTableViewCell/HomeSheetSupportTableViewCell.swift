//
//  HomeSheetSupportTableViewCell.swift
//  MimoBike
//
//  Created by Vardan on 04.05.21.
//

import UIKit

final class HomeSheetSupportTableViewCell: UITableViewCell {

    
    //MARK: - Outlets
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bgView: UIView!
    
    
    //MARK: - Life cycles

    override func awakeFromNib() {
        super.awakeFromNib()
        cnfigureUI()
    }


    //MARK: - Methods
    //configure user interface
    func cnfigureUI() {
        selectionStyle = .none
        
        bgView.layer.cornerRadius = Constant.CornerRadius.cornerRadius8
        bgView.layer.borderWidth = 1
        bgView.layer.borderColor = UIColor.mimoBlackWith025alpha.cgColor
    }
}
