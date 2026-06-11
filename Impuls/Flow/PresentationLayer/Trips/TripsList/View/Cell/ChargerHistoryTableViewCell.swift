//
//  ChargerHistoryTableViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.07.24.
//

import UIKit

final class ChargerHistoryTableViewCell: BaseTableViewCell {
    
    private var iconImageView: UIImageView!
    
    var startStationIdLabel: UILabel = UILabel()
    var endStationIdLabel: UILabel = UILabel()
    var amountContainerView: UIView = UIView()
    var amountLabel: UILabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        iconImageView.image = "mimo_charger_station".image
        contentView.addSubview(iconImageView)
        
        NSLayoutConstraint.activate([
            iconImageView.widthAnchor.constraint(equalToConstant: 42),
            iconImageView.heightAnchor.constraint(equalToConstant: 58),
            iconImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
        
        amountContainerView.backgroundColor = .mimoRed500
        amountContainerView.layer.cornerRadius = 4
        contentView.addSubview(amountContainerView)
        amountLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        amountLabel.textColor = .white
        amountContainerView.addSubview(amountLabel)
        
        NSLayoutConstraint.activate([
            amountLabel.leadingAnchor.constraint(equalTo: amountContainerView.leadingAnchor, constant: 10),
            amountLabel.trailingAnchor.constraint(equalTo: amountContainerView.trailingAnchor, constant: -10),
            amountLabel.topAnchor.constraint(equalTo: amountContainerView.topAnchor, constant: 5),
            amountLabel.trailingAnchor.constraint(equalTo: amountContainerView.trailingAnchor, constant: 5),
        ])
    }
}
