//
//  ChargingStationSheetViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.11.23.
//

import UIKit
import CoreLocation

protocol ChargingStationSheetViewControllerDelegate: AnyObject {
    func didSelectTariffs()
    func didSelectScan()
}

class ChargingStationSheetViewController: MimoBaseViewController {
    
    @IBOutlet private weak var freeMinutesLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var workingHoursLabel: UILabel!
    @IBOutlet private weak var photosCollectionView: UICollectionView!
    @IBOutlet private weak var availableSlotsLabel: UILabel!
    @IBOutlet private weak var slotsToReturnLabel: UILabel!
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var photosCountLabel: UILabel!
    @IBOutlet private weak var instagramButton: UIButton!
    @IBOutlet private weak var facebookButton: UIButton!
    @IBOutlet private weak var linkedinButton: UIButton!
    @IBOutlet private weak var websiteButton: UIButton!
    
    var viewModel: ChargingStationDetailsViewModel?
    weak var delegate: ChargingStationSheetViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupData()
        setupBalance()
    }
    
    private func setupUI() {
        photosCollectionView.contentInset.left = 16
        photosCollectionView.contentInset.right = 16
        photosCollectionView.register(ImageCollectionViewCell.self)
    }
    
    private func setupData() {
        titleLabel.text = viewModel?.chargingStation?.destinationName
        addressLabel.text = viewModel?.chargingStation?.destinationAddress
        
        let slotsCount = viewModel?.chargingStation?.slotsCount ?? 0
        let availableSlotsCount = viewModel?.chargingStation?.powerBanksCount ?? 0
        availableSlotsLabel.text = "\(availableSlotsCount) \("MOBILE_charger_slotsAvailable".localized())"
        slotsToReturnLabel.text = "\(slotsCount - availableSlotsCount) \("MOBILE_charger_slotsToReturn".localized())"
        logoImageView.sd_setImage(with: viewModel?.chargingStation?.logo?.imageURL)
        
        photosCountLabel.text = "\(viewModel?.chargingStation?.images?.count ?? 0)"
        workingHoursLabel.text = viewModel?.chargingStation?.workingHours
        
        instagramButton.isHidden = viewModel?.chargingStation?.instagramUrl?.isEmpty ?? true
        facebookButton.isHidden = viewModel?.chargingStation?.facebookUrl?.isEmpty ?? true
        linkedinButton.alpha = (viewModel?.chargingStation?.linkedinUrl?.isEmpty ?? true) ? 0 : 1
        websiteButton.alpha = (viewModel?.chargingStation?.websiteUrl?.isEmpty ?? true) ? 0 : 1
    }
    
    private func setupBalance() {
        guard let walletInfo = viewModel?.walletInfo, let financialState = viewModel?.financialState else { return }
        
        if walletInfo.balance - (financialState.additional ?? 0) < 0 {
            balanceLabel.textColor = .red
        } else {
            balanceLabel.textColor = .mimoBlackWith075alpha
        }
        
        let balance = (walletInfo.balance - (financialState.additional ?? 0)).rounded()
        balanceLabel.text = String(format: "%.2f", balance)
        
        freeMinutesLabel.text = String(format: "%.2f", viewModel?.user?.minutes ?? 0)
    }
}

private extension ChargingStationSheetViewController {
    
    @IBAction private func socialNetworkAction(_ sender: UIButton) {
        let application = UIApplication.shared
        
        switch SocialNetworkType(rawValue: sender.tag) {
        case .instagram:
            guard let instagram = viewModel?.chargingStation?.instagramUrl else { return }
            let appURL = URL(string: "instagram://user?username=\(instagram)")!
            if application.canOpenURL(appURL) {
                application.open(appURL)
            } else {
                // if Instagram app is not installed, open URL inside Safari
                let webURL = URL(string: "https://instagram.com/\(instagram)")!
                application.open(webURL)
            }
        case .facebook:
            guard let facebook = viewModel?.chargingStation?.facebookUrl else { return }
            let appURL = URL(string: "fb://profile/\(facebook)")!
            if application.canOpenURL(appURL) {
                application.open(appURL)
            }
        case .linkedin:
            guard let linkedin = viewModel?.chargingStation?.linkedinUrl, let appURL = URL(string: "linkedin://\(linkedin)") else { return }
            if application.canOpenURL(appURL) {
                application.open(appURL)
            }
        case .web:
            guard let web = viewModel?.chargingStation?.websiteUrl, let webURL = URL(string: web) else { return }
            application.open(webURL)
        default:
            break
        }
    }

    @IBAction private func directionAction() {
        guard let latitude = viewModel?.chargingStation?.location?.latitude,
              let longitude = viewModel?.chargingStation?.location?.longitude else { return }
        
        OpenMapDirections.present(in: self, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
    }
    
    @IBAction private func scanAction() {
        delegate?.didSelectScan()
    }
    
    @IBAction private func tariffsAction() {
        delegate?.didSelectTariffs()
    }
    
    @IBAction private func replenishAction() {
        VibrateManager.vibrate()
        
        openWallet()
    }
}

extension ChargingStationSheetViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.chargingStation?.images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ImageCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.set(imageURL: viewModel?.chargingStation?.images?[indexPath.row].imageURL)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
    }
}

private extension ChargingStationSheetViewController {
    enum SocialNetworkType: Int {
        case instagram = 0
        case facebook = 1
        case linkedin = 2
        case web = 3
    }
}
