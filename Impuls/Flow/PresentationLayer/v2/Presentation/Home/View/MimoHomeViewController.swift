//
//  MimoHomeViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 02.05.23.
//

import UIKit
import Combine
import SwiftUI

class MimoHomeViewController: MimoBaseViewController {
    
    private var cancellables = Set<AnyCancellable>()
    
    @IBOutlet private weak var activeTripsCollectionView: UICollectionView!
    @IBOutlet private weak var fastDecisionView: UIView!
    @IBOutlet private weak var scanButton: UIButton!
    @IBOutlet private weak var storiesContainerView: UIView!
    
    @IBOutlet private weak var servicesStackView: UIStackView!
    @IBOutlet private var servicesLoadingViews: [UIView]!
    @IBOutlet private var servicesViews: [UIView]!
    @IBOutlet private var productCloseButtons: [UIButton]!
    
    @IBOutlet private weak var storiesCollectionViewTopConstraint: NSLayoutConstraint!
    
    var height: CGFloat {
        let topSafeArea = UIApplication.shared.keyWindowInConnectedScenes?.safeAreaBottom ?? 0
        return UIScreen.main.bounds.height - (viewModel!.activeTrips.isEmpty ? 400 : 508) - topSafeArea
    }
    
    var viewModel: MimoHomeViewModel?
    var storyViewModel: StoryViewModel = StoryViewModel(worker: Resolver.resolve())
    private let generator = UIImpactFeedbackGenerator(style: .heavy)
    private var isProductEditMode: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel?.loadBalance()
        viewModel?.getActiveTrips()
        loadStories()
        NotificationCenter.default.addObserver(self, selector: #selector(updateFCMToken), name: NSNotification.Name("UpdateFCMToken"), object: nil)
        if (UIApplication.shared.delegate as? AppDelegate)?.isOpenedWithPushNotification ?? false {
            notificationAction()
        }
    }
    
    @objc func updateFCMToken() {
        if let fcmToken = (UIApplication.shared.delegate as? AppDelegate)?.fcmToken {
            viewModel?.updateDeviceInfo(fcmToken: fcmToken)
        }
    }
    
    private func setupUI() {
        let floawLayout = UPCarouselFlowLayout()
        floawLayout.itemSize = CGSize(width: Constant.Width.width085, height: 90)
        floawLayout.scrollDirection = .horizontal
        floawLayout.sideItemScale = 1
        floawLayout.sideItemAlpha = 1
        floawLayout.spacingMode = .fixed(spacing: 10.0)
        activeTripsCollectionView.collectionViewLayout = floawLayout
        activeTripsCollectionView.showsHorizontalScrollIndicator = false
        
        activeTripsCollectionView.register(ActiveTripCollectionViewCell.self)
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        makeNavigationBarWithProfileView()
        updateFCMToken()
    }
    
    private func setupViewModel() {
        viewModel?.$walletInfo.sink(receiveValue: { [weak self] balance in
            self?.set(balance: balance, financialState: self?.viewModel?.financialState)
        })
        .store(in: &cancellables)
        
        viewModel?.$financialState.sink(receiveValue: { [weak self] financialState in
            self?.set(balance: self?.viewModel?.walletInfo, financialState: financialState)
        })
        .store(in: &cancellables)
        
        viewModel?.$availableServices.sink(receiveValue: { [weak self] availableServices in
            guard let self, let availableServices = availableServices else { return }
            
            self.servicesLoadingViews.forEach({ $0.isHidden = true })
            
            if availableServices == [.charger] {
                self.servicesViews.first(where: {$0.tag == 4 })?.isHidden = true
                
                self.servicesViews.forEach { serviceView in
                    serviceView.isHidden = serviceView.tag != 22 // Charger full width view
                }
                
            } else {
                self.servicesViews.forEach { serviceView in
                    serviceView.isHidden = !availableServices.compactMap({ $0.rawValue }).contains(serviceView.tag)
                }
                
                self.servicesViews.first(where: {$0.tag == 4 })?.isHidden = availableServices.count == 4
            }
        })
        .store(in: &cancellables)
        
        viewModel?.$countryCode.sink { [weak self] countryCode in
            guard countryCode != nil else { return }
            
            self?.loadStories()
        }
        .store(in: &cancellables)
        
        viewModel?.$isForceUpdatedNeeded.sink(receiveValue: { [weak self] isForceUpdatedNeeded in
            guard let isForceUpdatedNeeded else { return }
            MILoader.hide()
            if isForceUpdatedNeeded {
                BaseRouter.shared.showForceUpdateViewController(self)
            }
        })
        .store(in: &cancellables)
        
        viewModel?.$activeTrips.sink(receiveValue: { [weak self] trips in
            guard let self else { return }
            self.fastDecisionView.tag = self.fastDecisionView.tag == 1 ? 2 : 0
            self.activeTripsCollectionView.reloadData()
            self.storiesCollectionViewTopConstraint.constant = trips.isEmpty ? 16 : 122
            self.activeTripsCollectionView.isHidden = trips.isEmpty
        })
        .store(in: &cancellables)
        
        storyViewModel.stories.sink(receiveValue: { [weak self] stories in
            guard let self else { return }
            
            let storiesThumbView = StoriesThumbView().environmentObject(storyViewModel)
            let hostingController = UIHostingController(rootView: storiesThumbView)
            hostingController.view.translatesAutoresizingMaskIntoConstraints = false
            self.storiesContainerView.subviews.forEach({ $0.removeFromSuperview() })
            self.storiesContainerView.addSubview(hostingController.view)
            
            NSLayoutConstraint.activate([
                hostingController.view.topAnchor.constraint(equalTo: self.storiesContainerView.topAnchor),
                hostingController.view.leadingAnchor.constraint(equalTo: self.storiesContainerView.leadingAnchor),
                hostingController.view.trailingAnchor.constraint(equalTo: self.storiesContainerView.trailingAnchor),
                hostingController.view.bottomAnchor.constraint(equalTo: self.storiesContainerView.bottomAnchor)
            ])
            
            hostingController.didMove(toParent: self)
        })
        .store(in: &cancellables)
        
        viewModel?.$rentedCharger
            .sink(receiveValue: { [weak self] charger in
                guard let self, let charger else { return }
                
                if charger.state == .rentEnded {
                    self.viewModel?.getActiveTrips()
                    
                    ChargerRouter.shared.showChargerSuccessViewController(self, currency: viewModel?.walletInfo?.currency, rentedCharger: charger)
                }
            })
            .store(in: &cancellables)
        
        MILoader.show()
        self.viewModel?.checkForceUpdate()
        
        HomeRouter.shared.fastDecisionSheetAnimateIn(to: view, in: self, height: height, viewModel: viewModel, delegate: self)
        
        servicesViews.forEach {
            if $0.tag == 4 { return }
            let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(aaaa))
            longPressGestureRecognizer.minimumPressDuration = 0.3
            $0.addGestureRecognizer(longPressGestureRecognizer)
        }
        
        generator.prepare()
    }
    
    @objc
    private func aaaa(sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        guard (viewModel?.availableServices?.count ?? 0) > 1 else { return }
        
        generator.impactOccurred()
        isProductEditMode.toggle()
        changeProductsState(isEditeMode: isProductEditMode)
    }
    
    private func changeProductsState(isEditeMode: Bool) {
        isProductEditMode = isEditeMode
        
        productCloseButtons.forEach { $0.isHidden = !isEditeMode }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        (activeTripsCollectionView.collectionViewLayout as? UPCarouselFlowLayout)?.itemSize = CGSize(width: Constant.Width.width085, height: activeTripsCollectionView.frame.height)
        
        HomeRouter.shared.fastDecisionSheetAnimate(to: height)
        view.sendSubviewToBack(activeTripsCollectionView)
        view.sendSubviewToBack(storiesContainerView)
        view.bringSubviewToFront(scanButton)
    }
    
    private func loadStories() {
        guard ApplicationSettings.shared.isoCountryCode != nil else { return }
        
        storyViewModel.getStories()
    }
    
    @IBAction private func mimoTypeAction(_ sender: UIButton) {
        if !(viewModel?.isLocationAuthorized ?? false) {
            UIAlertController.showLocationDeniedAlert()
            return
        }
        
        if sender.tag == 4 {
            HomeRouter.shared.showProductsSelectionScreen(navigationController)
            return
        }
        
        switch MimoProductType(rawValue: sender.tag) {
        case .scooter:
            ScooterRouter.shared.showScooterViewController(navigationController, leasedScooters: viewModel?.leasedScooters)
        case .bike:
            BikeRouter.shared.showBikeViewController(navigationController)
        case .charger:
            ChargerRouter.shared.showChargerViewController(navigationController)
        case .evCharger:
            EVChargerRouter.shared.showEvChargerViewController(navigationController, scanedStation: (nil,nil), isFromFastDecision: false)
        default:
            break
        }
    }
    
    @IBAction private func productCloseButtonTapped(_ sender: UIButton) {
        changeProductsState(isEditeMode: false)
        
        viewModel?.removeProduct(at: sender.tag)
    }
    
    
    @IBAction private func scanAction() {
        ScanRouter.shared.showQrScanViewController(self, delegate: self)
    }
}

extension MimoHomeViewController: MimoScanQrViewControllerDelegate {
    
    func didFinishScan(with value: String, type: MimoType) {
        if !(viewModel?.isLocationAuthorized ?? false) {
            UIAlertController.showLocationDeniedAlert()
            return
        }
        
        switch type {
        case .scooter:
            ScooterRouter.shared.showScooterViewController(navigationController, scannedQR: value, leasedScooters: viewModel?.leasedScooters)
        case .bike:
            BikeRouter.shared.showBikeViewController(navigationController, scannedQR: value)
        case .charger:
            ChargerRouter.shared.showChargerViewController(navigationController, scannedQR: value)
        case .evCharger:
            guard let scanedStation = viewModel?.getScanedStationData(code: value) else { return }
            EVChargerRouter.shared.showEvChargerViewController(navigationController, scanedStation: scanedStation, isFromFastDecision: false)
        }
    }
}

extension MimoHomeViewController: HomeFastDecisionSheetViewControllerDelegate {
    func didSelect(mimo: MimoResult, type: MimoProductType) {
        if !(viewModel?.isLocationAuthorized ?? false) {
            UIAlertController.showLocationDeniedAlert()
            return
        }
        
        switch type {
        case .scooter:
            if let qr = (mimo as? ScooterResult)?.qr {
                ScooterRouter.shared.showScooterViewController(navigationController, selectedQR: qr, leasedScooters: viewModel?.leasedScooters)
            }
        case .bike:
            if let qr = (mimo as? BikeResult)?.qr {
                BikeRouter.shared.showBikeViewController(navigationController, selectedQR: qr)
            }
        case .charger:
            if let qr = (mimo as? ChargingStation)?.id {
                ChargerRouter.shared.showChargerViewController(navigationController, selectedQR: qr)
            }
        case .evCharger:
            if let stationId = (mimo as? EVChargingStation)?.id {
                EVChargerRouter.shared.showEvChargerViewController(navigationController, selectedId: stationId, scanedStation: (nil,nil), isFromFastDecision: true)
            }
        }
    }
}

extension MimoHomeViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.activeTrips.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ActiveTripCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        
        if let scooter = viewModel?.activeTrips[indexPath.row] as? ScooterStateModel {
            cell.set(scooterState: scooter)
        } else if let bike = viewModel?.activeTrips[indexPath.row] as? TripActionModel {
            cell.set(bikeState: bike)
        } else if let charger = viewModel?.activeTrips[indexPath.row] as? RentedCharger {
            cell.set(charger: charger)
        } else if let evCharger = viewModel?.activeTrips[indexPath.row] as? EVStateMessagedDTO {
            cell.set(evCharger: evCharger)
        }
        
        return cell
    }
}

extension MimoHomeViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: Constant.Width.width085, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if !(viewModel?.isLocationAuthorized ?? false) {
            UIAlertController.showLocationDeniedAlert()
            return
        }
        
        if (viewModel?.activeTrips[indexPath.row] as? ScooterStateModel) != nil {
            ScooterRouter.shared.showScooterViewController(navigationController, leasedScooters: viewModel?.leasedScooters)
        } else if (viewModel?.activeTrips[indexPath.row] as? TripActionModel) != nil {
            BikeRouter.shared.showBikeViewController(navigationController)
        } else if (viewModel?.activeTrips[indexPath.row] as? RentedCharger) != nil {
            ChargerRouter.shared.showChargerViewController(navigationController)
        } else if let selectedStation = (viewModel?.activeTrips[indexPath.row] as? EVStateMessagedDTO) {
            print("selectedStation = ", )
            EVChargerRouter.shared.showEvChargerViewController(navigationController, selectedId: selectedStation.station.id, scanedStation: (nil,nil), isFromFastDecision: false)
        }
    }
}
