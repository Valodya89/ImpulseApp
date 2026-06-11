//
//  NoInternetConnectionViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 08.04.24.
//

import UIKit

class NoInternetConnectionViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let noConnectionImageView = UIImageView(image: "no_connection".image)
        noConnectionImageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(noConnectionImageView)
        NSLayoutConstraint.activate([
            noConnectionImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 90),
            noConnectionImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noConnectionImageView.widthAnchor.constraint(equalToConstant: 200),
            noConnectionImageView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        let lostConnectionLabel = UILabel()
        lostConnectionLabel.translatesAutoresizingMaskIntoConstraints = false
        lostConnectionLabel.textAlignment = .center
        lostConnectionLabel.font = .systemFont(ofSize: 24, weight: .bold)
        lostConnectionLabel.textColor = .mimoDarkGray
        lostConnectionLabel.numberOfLines = 0
        lostConnectionLabel.text = "MOBILE_lostConnection_title".localized()
        
        view.addSubview(lostConnectionLabel)
        NSLayoutConstraint.activate([
            lostConnectionLabel.topAnchor.constraint(equalTo: noConnectionImageView.bottomAnchor, constant: 48),
            lostConnectionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            lostConnectionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.textAlignment = .center
        subtitleLabel.font = .systemFont(ofSize: 16, weight: .regular)
        subtitleLabel.textColor = .mimoBlackWith075alpha
        subtitleLabel.numberOfLines = 0
        subtitleLabel.text = "MOBILE_lostConnection_message".localized()
        
        view.addSubview(subtitleLabel)
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: lostConnectionLabel.bottomAnchor, constant: 20),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        
        let tryAgainButton = UIButton()
        tryAgainButton.translatesAutoresizingMaskIntoConstraints = false
        tryAgainButton.backgroundColor = .mimoYellow500
        tryAgainButton.setTitleColor(.mimoBlack, for: .normal)
        tryAgainButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        tryAgainButton.cornerRadius = 24
        tryAgainButton.setTitle("MOBILE_lostConnection_tryAgain".localized(), for: .normal)
        tryAgainButton.addAction(UIAction(handler: { _ in
            if Reachability.isConnectedToNetwork() {
                BaseRouter.shared.showSplashView()
            }
        }), for: .touchUpInside)
        
        view.addSubview(tryAgainButton)
        
        NSLayoutConstraint.activate([
            tryAgainButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tryAgainButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            tryAgainButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            tryAgainButton.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
}
