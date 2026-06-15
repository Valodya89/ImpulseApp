//
//  EVChargerMapViewController.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/4/25.
//

import UIKit
import CoreLocation
import UIKit
import Combine
import SwiftMessages
import SwiftUI

class EVChargerMapViewController: MimoBaseViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var mapView: MimoMapView!
    @IBOutlet private weak var stationsCollectionView: UICollectionView!
    @IBOutlet private weak var collectionBackButton: UIButton!
    @IBOutlet private weak var collectionInfoButton: UIButton!
    @IBOutlet private weak var collectionFilterButton: UIButton!
    @IBOutlet private weak var collectionContainerView: UIView!
    @IBOutlet private weak var myLocationButton: UIButton!
    @IBOutlet private weak var supportView: UIView!
    
    @IBOutlet private weak var myLocationBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var activeChargingButton: UIButton!
    
    
    //MARK: - Private properties
    var viewModel: EVChargerMapViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var clusterManager: MimoClusterManager?
    
    private var isTransferDebtSelected: Bool = false
    private var hasLoadedInitialStations: Bool = false
    private var teamEnergyMarkers: [MimoMarker] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupMapCluster()
        setupPublishers()
        addTeamEnergyMarkers()
        viewModel?.viewDidLoaded()
//        viewModel?.socketConnect()
    }

    private func addTeamEnergyMarkers() {
        teamEnergyMarkers.forEach { $0.map = nil }
        teamEnergyMarkers = TeamEnergyProvider.loadLocations().map { location in
            let marker = TeamEnergyProvider.marker(for: location, animate: false)
            marker.map = mapView
            return marker
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel?.loadBalance()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    deinit {
        EVChargerRouter.shared.reset()
        viewModel?.unsubscribe()
    }
    
    private func setupPublishers() {
        guard let viewModel else { return }
        
        viewModel.$errorMessage.sink { [weak self] errorMessage in
            guard let errorMessage else { return }
            MILoader.hide()
            self?.showErrorPopUp(message: errorMessage, service: .scooter)
        }
        .store(in: &cancellables)
        
        viewModel.$viewState.sink { [weak self] viewState in
            self?.updateUI(for: viewState)
        }
        .store(in: &cancellables)
        
        viewModel.$startLocation.sink { [weak self] coordinate in
            guard let self, let coordinate else { return }

            let camera = MimoCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 16)
            self.mapView.animate(to: camera)
        }
        .store(in: &cancellables)
        
        viewModel.$stations.sink { [weak self] scooters in
            self?.stationsCollectionView.reloadData()

            if let scooters, scooters.isEmpty {
                self?.viewModel?.viewState = .initial
            }

//            if let selectedQR = viewModel.preSelectedQR {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
//                    viewModel.selectedStation = scooters?.first(where: { $0.qr == selectedQR })
//                    viewModel.preSelectedQR = nil
//                }
//            }
        }
        .store(in: &cancellables)

        viewModel.$stationMarkers.sink { [weak self] markers in
            self?.drawScooters(markers)
            
//            if let trip = viewModel.scooterStateData?.first(where: { $0.scooter?.qr == viewModel.selectedTrip?.scooter?.qr }) {
//                if let latitude = trip.scooter?.located?.latitude, let longitude = trip.scooter?.located?.longitude {
//                    self?.updateZoneStatus(currentLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), parkings: viewModel.parkingMarkers)
//                }
//            }
        }
        .store(in: &cancellables)
        
        
        viewModel.$walletInfo.sink { [weak self] walletInfo in
            ScooterRouter.shared.scanSheetViewController?.data?.walletInfo = walletInfo
            
            self?.set(balance: walletInfo, financialState: viewModel.financialState)
        }
        .store(in: &cancellables)
        
        viewModel.$financialState.sink { [weak self] financialState in
            ScooterRouter.shared.scanSheetViewController?.data?.financialState = financialState
            
            self?.set(balance: viewModel.walletInfo, financialState: financialState)
        }
        .store(in: &cancellables)
        
        viewModel.$user.sink { user in
            ScooterRouter.shared.scanSheetViewController?.data?.user = user
        }
        .store(in: &cancellables)
        
        viewModel.$walletState.sink { [weak self] state in
            guard let self else { return }
            
            if let scooterStateData = viewModel.scooterStateData, !scooterStateData.isEmpty {
                return
            }
            
            if (state == .Debt || state == .DebtOnDevice) && !self.isTransferDebtSelected {
                BaseRouter.shared.showDebtViewController(self,
                                                         debtAmount: viewModel.financialState?.additional,
                                                         debtWallets: viewModel.financialState?.wallets,
                                                         delegate: self)
            }
        }
        .store(in: &cancellables)
        
        viewModel.$selectedStationMarker.sink { [weak self] selectedMarker in
            guard let self else { return }
            
            mapView.selectedMarker = selectedMarker
            guard let position = selectedMarker?.position else { return }
            
            let point = mapView.projection.point(for: position)
            let camera = mapView.projection.coordinate(for: point)
            let cameraUpdate = MimoCameraUpdate.setTarget(camera, zoom: 18)
            mapView.animate(with: cameraUpdate)
            
            if viewModel.scooterStateData == nil || (viewModel.scooterStateData != nil && viewModel.scooterStateData!.isEmpty) {
                if let index = viewModel.stations?.firstIndex(where: { $0.id == self.viewModel?.selectedStation?.id }) {
                    viewModel.viewState = .scooterList(index)
                }
            }
        }
        .store(in: &cancellables)
        
        viewModel.$scooterStateData.sink { [weak self] data in
            guard let data, !data.isEmpty else { self?.viewModel?.viewState = .initial; return }
            
//            self?.viewModel?.viewState = .trip(data)
        }
        .store(in: &cancellables)
        
        viewModel.$scooterTripData.sink { [weak self] data in
            ScooterRouter.shared.scooterTripSheetViewController?.viewModel?.set(scooterStateModel: data)
            
//            if data?.scooter?.id == viewModel.selectedTrip?.scooter?.id {
//                if let latitude = data?.scooter?.located?.latitude, let longitude = data?.scooter?.located?.longitude {
//                    self?.updateZoneStatus(currentLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), parkings: viewModel.parkingMarkers)
//                }
//            }
        }
        .store(in: &cancellables)
        
        viewModel.$isUserInvited.sink { [weak self] isInvited in
            guard let isInvited, isInvited else { return }
            self?.showMimoAlert(.important(isSuccess: true, message: "User successfully invited"))
        }
        .store(in: &cancellables)
        
        viewModel.$showInfoMessage.sink { showInfoMessage in
            if showInfoMessage {
                var config = SwiftMessages.defaultConfig
                config.presentationStyle = .center
                config.duration = .forever
                config.interactiveHide = false
                
                let infoView = UIHostingController(rootView: InfoMessageView(
                    message: InfoMessage(
                        title: "SCOOTER_start_ride_message_title".localized(),
                        body: "SCOOTER_start_ride_message_body".localized()
                    ),
                    action: {
                        SwiftMessages.hide()
                    })
                ).view!
                infoView.backgroundColor = .clear
                SwiftMessages.show(config: config, view: infoView)
            }
        }
        .store(in: &cancellables)
        
        viewModel.$aciveChargings.sink { [weak self] hasActiveChargings in
            self?.activeChargingButton.isHidden = !hasActiveChargings
        }
        .store(in: &cancellables)
    }
    
//    override func transferToFriendViewControllerDismisses() {
//        viewModel?.loadBalance()
//    }
}

//MARK: - IBActions
extension EVChargerMapViewController {
    
    @IBAction private func scootersBackAction() {
        viewModel?.viewState = .initial
    }
    
    @IBAction private func infoAction() {
        viewModel?.coordinator.routeOnBoardingview()
    }
    
    @IBAction private func filterAction() {
        viewModel?.filterTapped()
    }
    
    @IBAction private func myLocationAction() {
        viewModel?.updateMyLocation()
    }
    
    @IBAction private func activeChargingAction() {
        viewModel?.activeChargingTapped()
    }
}

//MARK: - UI
extension EVChargerMapViewController {
    
    private func updateUI(for state: EvChargerViewState) {
        switch state {
        case .initial:
            EVChargerRouter.shared.showSheet(self)

            collectionContainerView.fadeOut()
            viewModel?.selectedStation = nil
            supportView.isHidden = false
            collectionBackButton.isHidden = true
            updateMyLocationPosition(constant: 100)
        case .scooterList(let selectedIndex):
            EVChargerRouter.shared.hideScanSheet()
            if collectionContainerView.alpha == 0 {
                collectionContainerView.fadeIn()
            }
            collectionBackButton.isHidden = false
//            stationsCollectionView.scrollToItem(at: IndexPath(item: selectedIndex, section: 0), at: .centeredHorizontally, animated: true)
            updateMyLocationPosition(constant: 240)
        }
    }
    
    private func setupUI() {
        makeNavigationBarWithBackButton(productType: .evCharger)
        
        if let balanceTitleView =  navigationItem.titleView?.viewWithTag(999) as? BalanceTitleView {
            balanceTitleView.plusButton.tintColor = .white
            balanceTitleView.plusButton.backgroundColor = UIColor(.evbrandCyan80)
        }
        
        setupSupportView()
        
        //MARK: - Global UI configs
        activeChargingButton.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
        collectionBackButton.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
        collectionInfoButton.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
        collectionFilterButton.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
        myLocationButton.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
        
        //MARK: - MapView
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        
        //MARK: - CollectionView
        setupCollectionView()
    }
    
    private func setupSupportView() {
        let swiftUIView = EVContactSupportButton()
        
        // Wrap it in a UIHostingController
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.view.backgroundColor = .clear
        
        // Add the hosting controller as a child
        addChild(hostingController)
        supportView.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Make sure it resizes correctly
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: supportView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: supportView.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: supportView.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: supportView.bottomAnchor)
        ])
    }
    
    private func updateMyLocationPosition(constant: CGFloat) {
        myLocationBottomConstraint.constant = constant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func setupCollectionView() {
        let floawLayout = UPCarouselFlowLayout()
        floawLayout.itemSize = CGSize(width: Constant.Width.width075, height: 174)
        floawLayout.scrollDirection = .horizontal
        floawLayout.sideItemScale = 1
        floawLayout.sideItemAlpha = 1
        floawLayout.spacingMode = .fixed(spacing: 10.0)
        stationsCollectionView.collectionViewLayout = floawLayout
        stationsCollectionView.showsHorizontalScrollIndicator = false
        
        stationsCollectionView.register(SwiftUICollectionViewCell.self, forCellWithReuseIdentifier: "StationCollectionViewCell")
    }
    
    private func setupMapCluster() {
        let iconGenerator = EVClusterIconGenerator()
        let algorithm = MimoNonHierarchicalDistanceBasedAlgorithm(clusterDistancePoints: 100) ?? MimoNonHierarchicalDistanceBasedAlgorithm()
        let renderer = MimoDefaultClusterRenderer(mapView: self.mapView, clusterIconGenerator: iconGenerator)
        renderer.minimumClusterSize = 1
        renderer.maximumClusterZoom = 16
        renderer.animatesClusters = true
        self.clusterManager = MimoClusterManager(map: self.mapView, algorithm: algorithm, renderer: renderer)
        self.clusterManager?.setMapDelegate(self)
    }
    
    private func drawScooters(_ markers: [MimoMarker]) {
        clusterManager?.clearItems()
        markers.forEach { marker in
            self.clusterManager?.add(marker)
        }
        clusterManager?.cluster()
    }

    private func currentMapRadius() -> Double {
        let region = mapView.projection.visibleRegion()
        let center = mapView.camera.target
        let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
        let cornerLocation = CLLocation(latitude: region.farLeft.latitude, longitude: region.farLeft.longitude)
        return centerLocation.distance(from: cornerLocation)
    }
}

//MARK: - MimoMapViewDelegate
extension EVChargerMapViewController: MimoMapViewDelegate {
    func mapView(_ mapView: MimoMapView, idleAt position: MimoCameraPosition) {
        guard let viewModel else { return }

        viewModel.mapRadius = currentMapRadius()

        if !hasLoadedInitialStations {
            guard let userLocation = viewModel.startLocation else { return }
            hasLoadedInitialStations = true
            viewModel.loadScooters(mapCenter: userLocation)
        } else {
            viewModel.loadScooters(mapCenter: position.target)
        }
    }
    
    func mapView(_ mapView: MimoMapView, didTap marker: MimoMarker) -> Bool {
//        if (marker.userData as? String)?.hasPrefix("Parking") != nil {
//            ScooterRouter.shared.showParkingInfo(self)
//            return false
//        }
//        
//        if (marker.userData as? ZoneType) == .FORBIDDEN {
//            ScooterRouter.shared.showZoneInfo(self, zoneType: .FORBIDDEN)
//            return false
//        }
        
        if let scooterStateData = viewModel?.scooterStateData, !scooterStateData.isEmpty {
            return false
        }

        if marker.userData is TeamEnergyLocation {
            mapView.animate(toLocation: marker.position)
            return false
        }

        if marker.userData is MimoCluster {
            mapView.animate(toLocation: marker.position)
            mapView.animate(toZoom: 18)
        } else {
            guard let stationData = viewModel?.stations?.first(where: {
                $0.location?.latitude == marker.position.latitude && $0.location?.longitude == marker.position.longitude
            }) else { return false }

            viewModel?.selectedStation = stationData
            viewModel?.coordinator.routeEVChargerDetailView(id: stationData.id)
        }

        return true
    }
    
    func mapView(_ mapView: MimoMapView, didChange position: MimoCameraPosition) {
//        guard let zones = viewModel?.mapZones else { return }
//        draw(zones: zones, withHoles: position.zoom > 11)
    }
    
    func mapView(_ mapView: MimoMapView, markerInfoWindow marker: MimoMarker) -> UIView? {
        return nil
    }
    
    func mapView(_ mapView: MimoMapView, didTapAt coordinate: CLLocationCoordinate2D) {
//        let zoneType = PolygonDrawer.shared.zoneType(for: coordinate)
//        ScooterRouter.shared.showZoneInfo(self, zoneType: zoneType)
    }
}

extension EVChargerMapViewController: ShowDebtViewControllerDdelegate {
    
    func didSelectPayDdebt() {
        self.openWallet()
    }
    
    func didSelectTransfer() {
        isTransferDebtSelected = true
    }
    
    func didSelectTransfer(wallet: WalletDebts) {
        MILoader.show()
        viewModel?.isMimoUser(phoneNumber: wallet.walletId ?? "", completion: { [weak self] mimoCheckStatus in
            guard let self else { return }
            MILoader.hide()
            self.isTransferDebtSelected = false
            
            switch mimoCheckStatus {
            case .isMimoUser(let user):
                BaseRouter.shared.showTransferToFirendViewController(self, phoneNumber: wallet.walletId ?? "", transferUser: user, debt: wallet.debtSum)
            case .noSuchUser:
                let inviteLocalized = "MOBILE_transfer_invite".localized()
                let phoneNumber = wallet.walletId ?? ""
                
                self.showAlertMessage("\(inviteLocalized) \(phoneNumber)", meassage: "MOBILE_transfer_invite_or_not".localized(), actionText: ["MOBILE_global_cancel".localized(), inviteLocalized]) { [weak self] action in
                    if action == inviteLocalized {
                        self?.viewModel?.inviteUser(phoneNumber: phoneNumber)
                    }
                }
            case .error:
                self.showErrorAlertMessage("Failed to check contact user")
            case .none:
                self.showErrorAlertMessage("Failed to check contact user")
            }
        })
    }
}

//MARK: - UICollectionViewDataSource
extension EVChargerMapViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.stations?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StationCollectionViewCell", for: indexPath) as? SwiftUICollectionViewCell,
              let station = viewModel?.stations?[indexPath.item] else { return UICollectionViewCell() }

        let distance = viewModel?.currentLocation?.clLocation.distance(from: station.coordinate.clLocation).prettyDistance ?? "-"

        let stationId = station.id
        let swiftUIView = ChargerStationView(station: station,
                                             distance: distance,
                                             chooseAction: { [weak self] in
            guard let self else { return }
            let visibleIndex = self.stationsCollectionView.getCurrentVisibleCellIndexPath().row
            let stations = self.viewModel?.stations ?? []
            let routedId = (visibleIndex >= 0 && visibleIndex < stations.count) ? stations[visibleIndex].id : stationId
            self.viewModel?.coordinator.routeEVChargerDetailView(id: routedId)
        })

        cell.host(view: swiftUIView, parent: self)
        return cell
    }
}

extension EVChargerMapViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleIndexPath = stationsCollectionView.getCurrentVisibleCellIndexPath()
        let location = viewModel?.stations?[visibleIndexPath.row]
        viewModel?.selectedStation = location
    }
}
