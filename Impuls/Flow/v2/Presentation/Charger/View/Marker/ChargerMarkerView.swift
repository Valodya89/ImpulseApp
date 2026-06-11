//
//  ChargerMarkerView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 15.07.24.
//

import UIKit

final class ChargerMarkerView: UIView {
    
    private let slotsCount: Int
    private let avaliablePBCount: Int
    private let discount: Int
    private let size: CGFloat
    
    init(slotsCount: Int, avaliablePBCount: Int, discount: Int, size: CGFloat = 60) {
        self.slotsCount = slotsCount
        self.avaliablePBCount = avaliablePBCount
        self.discount = discount
        self.size = size
        super.init(frame: .init(origin: .zero, size: CGSize(width: size, height: size)))
        
        setupUI()
        
        self.clipsToBounds = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        let size = self.size - 24
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        NSLayoutConstraint.activate([
            containerView.widthAnchor.constraint(equalToConstant: size),
            containerView.heightAnchor.constraint(equalToConstant: size),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor)
        ])
        
        let bgView = UIView()
        bgView.cornerRadius = size/2
        bgView.backgroundColor = .mimoYellow500
        bgView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(bgView)
        
        NSLayoutConstraint.activate([
            bgView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            bgView.topAnchor.constraint(equalTo: containerView.topAnchor),
            bgView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        let bgWhiteView = UIView()
        bgWhiteView.cornerRadius = (size - 4)/2
        bgWhiteView.backgroundColor = .mimoWhite
        bgWhiteView.borderWidth = 1
        bgWhiteView.borderColor = .mimoBlack
        bgWhiteView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(bgWhiteView)
        
        NSLayoutConstraint.activate([
            bgWhiteView.widthAnchor.constraint(equalToConstant: (size - 4)),
            bgWhiteView.heightAnchor.constraint(equalToConstant: (size - 4)),
            bgWhiteView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bgWhiteView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        let middleLineView = UIView()
        middleLineView.backgroundColor = .mimoBlack
        middleLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(middleLineView)
        
        NSLayoutConstraint.activate([
            middleLineView.widthAnchor.constraint(equalToConstant: (size - 4)),
            middleLineView.heightAnchor.constraint(equalToConstant: 1),
            middleLineView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            middleLineView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        let pbCountAttrString = NSMutableAttributedString(
            string: "\(avaliablePBCount)",
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.mimoGreen,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: size/4, weight: .semibold)
            ]
        )
        let pbAttrString = NSMutableAttributedString(
            string: "PB",
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.mimoGreen,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: size/6, weight: .semibold)
            ]
        )
        
        pbCountAttrString.append(pbAttrString)
        
        let pbCountsLabel = UILabel()
        pbCountsLabel.attributedText = pbCountAttrString
        pbCountsLabel.textAlignment = .center
        pbCountsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(pbCountsLabel)
        NSLayoutConstraint.activate([
            pbCountsLabel.widthAnchor.constraint(equalToConstant: size),
            pbCountsLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6)
        ])
        
        let slotsCountAttrString = NSMutableAttributedString(
            string: "\(slotsCount)",
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.mimoBlack,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: size/4, weight: .semibold)
            ]
        )
        let slAttrString = NSMutableAttributedString(
            string: "SL",
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.mimoBlack,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: size/6, weight: .semibold)
            ]
        )
        
        slotsCountAttrString.append(slAttrString)
        
        let slotsCountsLabel = UILabel()
        slotsCountsLabel.attributedText = slotsCountAttrString
        slotsCountsLabel.textAlignment = .center
        slotsCountsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(slotsCountsLabel)
        NSLayoutConstraint.activate([
            slotsCountsLabel.widthAnchor.constraint(equalToConstant: size),
            slotsCountsLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -6)
        ])
        
        guard discount > 0 else { CATransaction.commit(); return }
        
        let discountView = UIView()
        discountView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(discountView)
        
        let discountLabelBackgroundView = UIImageView(image: "charger_marker_discount_label".image)
        discountLabelBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        discountLabelBackgroundView.tintColor = discount == 100 ? .zoneGreen : .mimoRed500
        discountView.addSubview(discountLabelBackgroundView)
        
        let arcImageView = UIImageView(image: "discount_label_arc".image)
        arcImageView.translatesAutoresizingMaskIntoConstraints = false
        discountView.addSubview(arcImageView)
        
        let discountLabel = UILabel()
        discountLabel.translatesAutoresizingMaskIntoConstraints = false
        discountLabel.textColor = .white
        discountLabel.font = .systemFont(ofSize: 9, weight: .bold)
        discountLabel.text = discount == 100 ? "Free" : "\(discount)%"
        discountView.addSubview(discountLabel)
        
        NSLayoutConstraint.activate([
            arcImageView.widthAnchor.constraint(equalToConstant: 7),
            arcImageView.heightAnchor.constraint(equalToConstant: 7),
            arcImageView.leadingAnchor.constraint(equalTo: discountView.leadingAnchor),
            arcImageView.topAnchor.constraint(equalTo: discountView.topAnchor)
        ])
        
        NSLayoutConstraint.activate([
            discountLabelBackgroundView.leadingAnchor.constraint(equalTo: discountView.leadingAnchor),
            discountLabelBackgroundView.topAnchor.constraint(equalTo: arcImageView.bottomAnchor, constant: -6),
            discountLabelBackgroundView.bottomAnchor.constraint(equalTo: discountView.bottomAnchor),
            discountLabelBackgroundView.trailingAnchor.constraint(equalTo: discountView.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            discountView.widthAnchor.constraint(equalToConstant: 32),
            discountView.heightAnchor.constraint(equalToConstant: 32),
            discountView.leadingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
            discountView.topAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])
        
        NSLayoutConstraint.activate([
            discountLabel.centerXAnchor.constraint(equalTo: discountView.centerXAnchor),
            discountLabel.centerYAnchor.constraint(equalTo: discountView.centerYAnchor),
        ])
        
        discountLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi/4)
        
        CATransaction.commit()
    }
}
