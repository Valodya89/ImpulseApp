//
//  ProfileActivityView.swift
//  MimoBike
//
//  Created by Dose on 6/3/21.
//

import UIKit

final class ProfileActivityView: UIView {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var decimalLabel: UILabel!
    @IBOutlet weak var decimalCurrencyLabel: UILocalizedLabel!
    @IBOutlet weak var decimalDescriptionLabel: UILocalizedLabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        loadFromNib()
    }
    
    func setup(iconImageView: UIImage, decimal: String, currency: String?, decimalDescription: String) {
        self.iconImageView.image = iconImageView
        self.decimalLabel.text = decimal
        self.decimalCurrencyLabel.isHidden = currency == nil
        self.decimalCurrencyLabel.text = currency
        self.decimalDescriptionLabel.text = decimalDescription
    }
    
    func update(decimal: String) {
        self.decimalLabel.text = decimal
    }
}
