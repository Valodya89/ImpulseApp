//
//  ChargerSelectedMarkerView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 17.07.24.
//

import UIKit

final class ChargerSelectedMarkerView: UIView {
    
    private let slotsCount: Int
    private let avaliablePBCount: Int
    private let discount: Int
    
    init(slotsCount: Int, avaliablePBCount: Int, discount: Int) {
        self.slotsCount = slotsCount
        self.avaliablePBCount = avaliablePBCount
        self.discount = discount
        super.init(frame: .init(origin: .zero, size: CGSize(width: 80, height: 63)))
        
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.widthAnchor.constraint(equalToConstant: 54),
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        let backgroundImageView = UIImageView(image: "charger_marker_background".image)
        contentView.addSubview(backgroundImageView)
        
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backgroundImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            backgroundImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
        
        let circleView = UIView()
        contentView.addSubview(circleView)
        
        circleView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            circleView.widthAnchor.constraint(equalToConstant: 38),
            circleView.heightAnchor.constraint(equalToConstant: 38),
            circleView.topAnchor.constraint(equalTo: topAnchor, constant: 5),
            circleView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
        
        let yellowCircleImageView = UIImageView(image: "charger_marker_circle_background".image)
        yellowCircleImageView.translatesAutoresizingMaskIntoConstraints = false
        circleView.addSubview(yellowCircleImageView)
        NSLayoutConstraint.activate([
            yellowCircleImageView.widthAnchor.constraint(equalTo: circleView.widthAnchor),
            yellowCircleImageView.heightAnchor.constraint(equalTo: circleView.heightAnchor),
            yellowCircleImageView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            yellowCircleImageView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor)
        ])
        
        let lineView = UIView()
        lineView.backgroundColor = .black
        lineView.translatesAutoresizingMaskIntoConstraints = false
        
        circleView.addSubview(lineView)
        NSLayoutConstraint.activate([
            lineView.widthAnchor.constraint(equalToConstant: 38),
            lineView.heightAnchor.constraint(equalToConstant: 0.7),
            lineView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            lineView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor),
        ])
        
        let pbCountAttrString = NSMutableAttributedString(
            string: "\(avaliablePBCount)",
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.mimoGreen,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .semibold)
            ]
        )
        let pbAttrString = NSMutableAttributedString(
            string: "PB",
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.mimoGreen,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 8, weight: .medium)
            ]
        )
        
        pbCountAttrString.append(pbAttrString)
        
        let pbCountsLabel = UILabel()
        pbCountsLabel.attributedText = pbCountAttrString
        pbCountsLabel.textAlignment = .center
        pbCountsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        circleView.addSubview(pbCountsLabel)
        NSLayoutConstraint.activate([
            pbCountsLabel.widthAnchor.constraint(equalToConstant: 38),
            pbCountsLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8)
        ])
        
        let slotsCountAttrString = NSMutableAttributedString(
            string: "\(slotsCount)",
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.mimoBlack,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .semibold)
            ]
        )
        let slAttrString = NSMutableAttributedString(
            string: "SL",
            attributes: [
                NSAttributedString.Key.foregroundColor: UIColor.mimoBlack,
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 8, weight: .medium)
            ]
        )
        
        slotsCountAttrString.append(slAttrString)
        
        let slotsCountsLabel = UILabel()
        slotsCountsLabel.attributedText = slotsCountAttrString
        slotsCountsLabel.textAlignment = .center
        slotsCountsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        circleView.addSubview(slotsCountsLabel)
        NSLayoutConstraint.activate([
            slotsCountsLabel.widthAnchor.constraint(equalToConstant: 38),
            slotsCountsLabel.bottomAnchor.constraint(equalTo: circleView.bottomAnchor, constant: -4)
        ])
        
        let shadowImageView = UIImageView(image: "charger_marker_shadow".image)
        shadowImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(shadowImageView)
        
        NSLayoutConstraint.activate([
            shadowImageView.widthAnchor.constraint(equalToConstant: 33),
            shadowImageView.heightAnchor.constraint(equalToConstant: 3),
            shadowImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            shadowImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
        ])
        
        guard discount > 0 else { return }
        
        let discountView = UIView()
        discountView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(discountView)
        
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
            discountView.leadingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            discountView.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -36)
        ])
        
        NSLayoutConstraint.activate([
            discountLabel.centerXAnchor.constraint(equalTo: discountView.centerXAnchor),
            discountLabel.centerYAnchor.constraint(equalTo: discountView.centerYAnchor),
        ])
        
        discountLabel.transform = CGAffineTransform(rotationAngle: CGFloat.pi/4)
        
        CATransaction.commit()
    }
}
