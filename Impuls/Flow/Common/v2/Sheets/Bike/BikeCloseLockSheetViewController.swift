//
//  BikeCloseLockSheetViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 08.04.24.
//

import UIKit

class BikeCloseLockSheetViewController: UIViewController {
    
    var closeTapped: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        let messageLabel = UILabel()
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = .systemFont(ofSize: 20, weight: .regular)
        messageLabel.textColor = .mimoDarkGray
        messageLabel.text = "MOBILE_lock_bike".localized()
        
        view.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        let closeButton = UIButton()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("SHARING_bike_popUp_closedIt".localized(), for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        closeButton.setTitleColor(.mimoBlack, for: .normal)
        closeButton.backgroundColor = .mimoYellow500
        closeButton.cornerRadius = 24
        closeButton.addAction(UIAction(handler: { [weak self] _ in
            self?.closeTapped?()
        }), for: .touchUpInside)
        
        view.addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 48),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            closeButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }

}
