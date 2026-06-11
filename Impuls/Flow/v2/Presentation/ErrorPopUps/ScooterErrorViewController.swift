//
//  ScooterErrorViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 04.04.24.
//

import UIKit

class ScooterErrorViewController: UIViewController {
    
    private let message: String
    private let isReplenishable: Bool
    private let onReplenish: () -> Void
    
    init(message: String, isReplenishable: Bool, onReplenish: @escaping () -> Void) {
        self.message = message
        self.isReplenishable = isReplenishable
        self.onReplenish = onReplenish
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white

        let leftYellowView = UIImageView(image: "ic_left_green".image)
        leftYellowView.translatesAutoresizingMaskIntoConstraints = false
        leftYellowView.contentMode = .scaleAspectFit
        
        view.addSubview(leftYellowView)
        NSLayoutConstraint.activate([
            leftYellowView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            leftYellowView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            leftYellowView.widthAnchor.constraint(equalToConstant: 150),
            leftYellowView.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        let rightYellowView = UIImageView(image: "ic_right_green".image)
        rightYellowView.translatesAutoresizingMaskIntoConstraints = false
        rightYellowView.contentMode = .scaleAspectFit
        
        view.addSubview(rightYellowView)
        NSLayoutConstraint.activate([
            rightYellowView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rightYellowView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -160),
            rightYellowView.widthAnchor.constraint(equalToConstant: 150),
            rightYellowView.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        let scooterImageView = UIImageView(image: "Mimo_scooter_New".image)
        scooterImageView.translatesAutoresizingMaskIntoConstraints = false
        scooterImageView.contentMode = .scaleAspectFit
        
        view.addSubview(scooterImageView)
        NSLayoutConstraint.activate([
            scooterImageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -190),
            scooterImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scooterImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            scooterImageView.heightAnchor.constraint(equalTo: scooterImageView.widthAnchor)
        ])
        
        let closeButton = UIButton()
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .black
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addAction(UIAction(handler: { [weak self] _ in
            self?.dismiss(animated: true)
        }), for: .touchUpInside)
        
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor)
        ])
        
        let hiFrendLabel = UILabel()
        hiFrendLabel.text = "\("SCOOTER_min_balanse_title".localized()) ✋"
        hiFrendLabel.font = .systemFont(ofSize: 24, weight: .bold)
        hiFrendLabel.textColor = .mimoBlack
        hiFrendLabel.translatesAutoresizingMaskIntoConstraints = false
        hiFrendLabel.textAlignment = .center
        
        view.addSubview(hiFrendLabel)
        NSLayoutConstraint.activate([
            hiFrendLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            hiFrendLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = .systemFont(ofSize: 16, weight: .regular)
        messageLabel.textColor = .mimoBlackWith05alpha
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        
        view.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: hiFrendLabel.bottomAnchor, constant: 20),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
        
        if isReplenishable {
            let replenishButton = UIButton()
            replenishButton.translatesAutoresizingMaskIntoConstraints = false
            replenishButton.cornerRadius = 24
            replenishButton.backgroundColor = .mimoYellow500
            replenishButton.setTitleColor(.mimoBlack, for: .normal)
            replenishButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
            replenishButton.setTitle("SCOOTER_replenish_balance".localized(), for: .normal)
            replenishButton.addAction(UIAction(handler: { [weak self] _ in
                self?.dismiss(animated: true, completion: {
                    self?.onReplenish()
                })
            }), for: .touchUpInside)
            
            view.addSubview(replenishButton)
            NSLayoutConstraint.activate([
                replenishButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
                replenishButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
                replenishButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
                replenishButton.heightAnchor.constraint(equalToConstant: 48),
            ])
        }
    }
}
