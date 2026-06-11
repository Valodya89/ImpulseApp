//
//  CountryCodeTableViewCell.swift
//  MimoBike
//
//  Created by Vardan on 22.04.21.
//

import UIKit

final class CountryCodeTableViewCell: UITableViewCell {
    
    
    //MARK: - Outlets

    @IBOutlet weak var flagImageView: UIImageView!
    @IBOutlet weak var countyTitle: UILabel!
    @IBOutlet weak var checkmarImage: UIImageView!
    
        
    //MARK: - Life cycle

    override func awakeFromNib() {
        super.awakeFromNib()
        configureUI()
    }
    
    //MARK: - Methods
    
    /// configure user interface
    private func configureUI() {
        selectionStyle = .none
    }
    
    /// set cell info
    func setInfo(item: CountryCodeResponse) {
        flagImageView.image = UIImage(named: item.flag ?? "")//item.imageFlag
        countyTitle.text = item.country
        if isSelected {
            checkmarImage.isHidden = false
            countyTitle.colorString(text: "(\(item.dial_code ?? "+374")) \(item.country ?? "")", coloredText: [item.country ?? ""], color: .mimoGreen)
        } else {
            checkmarImage.isHidden = true
            countyTitle.colorString(text: "(\(item.dial_code ?? "+374")) \(item.country ?? "")", coloredText: [item.country ?? ""], color: .mimoBlackWith05alpha)
        }
    }
}
