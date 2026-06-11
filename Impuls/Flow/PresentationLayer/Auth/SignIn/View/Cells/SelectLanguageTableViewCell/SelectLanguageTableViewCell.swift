//
//  SelectLanguageTableViewCell.swift
//  MimoBike
//
//  Created by Vardan on 19.04.21.
//

import UIKit

final class SelectLanguageTableViewCell: UITableViewCell {

    
    //MARK: - Outlets
    
    @IBOutlet weak var flagImageView: UIImageView!
    @IBOutlet weak var languageTitle: UILabel!
    @IBOutlet weak var checkmarImage: UIImageView!
    
    
    //MARK: - Life cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }
    
    
    //MARK: - Methods
    
    /// configure user interface
    func configureUI() {
        selectionStyle = .none
    }
    
    /// set cell info
    func setInfo(item: LanguageResult) {
        languageTitle.text = item.name
        flagImageView.image = UIImage(data: item.flag)
        
        if item.isSelected {
            checkmarImage.isHidden = false
            languageTitle.textColor = .mimoGreen
        } else {
            checkmarImage.isHidden = true
            languageTitle.textColor = .mimoBlackWith075alpha
        }
    }
}
