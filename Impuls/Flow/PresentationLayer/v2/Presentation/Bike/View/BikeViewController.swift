//
//  BikeViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 30.06.23.
//

import UIKit
import Combine
import CoreLocation
import UIKit
class BikeViewController: MimoBaseViewController {
    
    private var cancellables = Set<AnyCancellable>()
    private var clusterManager: MimoClusterManager?
    
    var viewModel: BikeViewModel?
    
    @IBOutlet private weak var mapView: MimoMapView!
    @IBOutlet private weak var bikesCollectionView: UICollectionView!
    @IBOutlet private weak var bikesCollectionContainerView: UIView!
    @IBOutlet private weak var bikesCollectionBackButton: UIButton!
    @IBOutlet private weak var myLocationButton: UIButton!
    @IBOutlet private weak var infoButton: UIButton!
    @IBOutlet private weak var supportView: MimoSupportView!
    @IBOutlet private weak var zoneStatusView: ZoneStatusView!

    @IBOutlet private weak var infoButtonBottomConstraint: NSLayoutConstraint!
    
    private var isTransferDebtSelected: Bool = false
    
    private var forbiddenMarkers: [MimoMarker] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupMapCluster()
        configureDelegates()
        setupPublishers()
        
        viewModel?.socketConnect()
        viewModel?.getBikeState()
        viewModel?.getMapZones()
        viewModel?.getNews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel?.loadBalance()
    }
    
    deinit {
        viewModel?.unsubscribe()
        BikeRouter.shared.reset()
    }
    
    private func setupUI() {
        //MARK: - Global UI configs
        makeNavigationBarWithBackButton(rightButtons: [.notification], productType: .bike)
        bikesCollectionBackButton.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
        myLocationButton.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
        infoButton.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
        
        //MARK: - MapView
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        
        //MARK: - CollectionView
        setupCollectionView()
    }
    
    private func updateInfoButtonPosition(constant: CGFloat) {
        infoButtonBottomConstraint.constant = constant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func updateUI(for state: BikeViewState) {
        switch state {
        case .initial:
            BikeRouter.shared.hideBikeTripSheet()
            BikeRouter.shared.showScanSheet(self, data: ScanSheetViewController.Data(mimoType: .bike), delegate: self)
            
            bikesCollectionContainerView.fadeOut()
            viewModel?.selectedBike = nil
            updateInfoButtonPosition(constant: 100)
            
            supportView.isHidden = false
            zoneStatusView.isHidden = true
            
        case .bikeList(let selectedIndex):
            BikeRouter.shared.hideScanSheet()
            if bikesCollectionContainerView.alpha == 0 {
                bikesCollectionContainerView.fadeIn()
            }
            bikesCollectionView.scrollToItem(at: IndexPath(item: selectedIndex, section: 0), at: .centeredHorizontally, animated: true)
            updateInfoButtonPosition(constant: 208)
        case .trip(let data):
            BikeRouter.shared.hideScanSheet()
            BikeRouter.shared.showBikeTripSheet(self, data: data)
            updateInfoButtonPosition(constant: 270)
            supportView.isHidden = true
        }
    }
    
    private func setupCollectionView() {
        let floawLayout = UPCarouselFlowLayout()
        floawLayout.itemSize = CGSize(width: Constant.Width.width075, height: 174)
        floawLayout.scrollDirection = .horizontal
        floawLayout.sideItemScale = 1
        floawLayout.sideItemAlpha = 1
        floawLayout.spacingMode = .fixed(spacing: 10.0)
        bikesCollectionView.collectionViewLayout = floawLayout
        bikesCollectionView.showsHorizontalScrollIndicator = false
        
        bikesCollectionView.register(BikeCollectionViewCell.self)
    }
    
    private func draw(zones: [Zone], withHoles: Bool) {
        viewModel?.zoneDrawerData?.ridePolygon.forEach({ $0.map = nil })
        viewModel?.zoneDrawerData?.restrictedPolygon.forEach({ $0.map = nil })
        viewModel?.zoneDrawerData?.forbiddenPolygon.forEach({ $0.map = nil })
        
        viewModel?.zoneDrawerData?.ridePolyline.forEach({ $0.map = nil })
        viewModel?.zoneDrawerData?.restrictedPolyline.forEach({ $0.map = nil })
        viewModel?.zoneDrawerData?.forbiddenPolyline.forEach({ $0.map = nil })
        
        viewModel?.zoneDrawerData = nil
        
        viewModel?.zoneDrawerData = PolygonDrawer.shared.polygon(with: zones, withHoles: withHoles)
        viewModel?.zoneDrawerData?.ridePolygon.forEach({ $0.map = mapView })
        viewModel?.zoneDrawerData?.restrictedPolygon.forEach({ $0.map = mapView })
        viewModel?.zoneDrawerData?.forbiddenPolygon.forEach({ $0.map = mapView })
        
        viewModel?.zoneDrawerData?.ridePolyline.forEach({ $0.map = mapView })
        viewModel?.zoneDrawerData?.restrictedPolyline.forEach({ $0.map = mapView })
        viewModel?.zoneDrawerData?.forbiddenPolyline.forEach({ $0.map = mapView })
        
        if self.forbiddenMarkers.isEmpty {
            PolygonDrawer.shared.forbiddenCoordinates.forEach({
                let center = $0.center()
                let marker = MimoMarker(position: center)
                marker.icon = "noRidingSmall".image
                
                self.forbiddenMarkers.append(marker)
            })
        }
        
        if withHoles {
            forbiddenMarkers.forEach({ $0.map = mapView })
        } else {
            forbiddenMarkers.forEach({ $0.map = nil })
        }
    }
    
    private func setupMapCluster() {
        let iconGenerator = MimoClusterIconGenerator()
        let algorithm = MimoNonHierarchicalDistanceBasedAlgorithm(clusterDistancePoints: 100) ?? MimoNonHierarchicalDistanceBasedAlgorithm()
        let renderer = MimoDefaultClusterRenderer(mapView: self.mapView, clusterIconGenerator: iconGenerator)
        renderer.minimumClusterSize = 1
        renderer.maximumClusterZoom = 16
        renderer.animatesClusters = true
        self.clusterManager = MimoClusterManager(map: self.mapView, algorithm: algorithm, renderer: renderer)
        self.clusterManager?.setMapDelegate(self)
    }
    
    private func configureDelegates() {
        BLEManager.shareInstance.delegate = self
    }
    
    private func setupPublishers() {
        guard let viewModel else { return }
        
        viewModel.$errorMessage.sink { [weak self] errorMessage in
            guard let errorMessage else { return }
            MILoader.hide()
            self?.showErrorPopUp(message: errorMessage, service: .bike)
        }
        .store(in: &cancellables)
        
        viewModel.$viewState.sink { [weak self] state in
            self?.updateUI(for: state)
        }
        .store(in: &cancellables)
        
        viewModel.$startLocation.sink { [weak self] coordinate in
            guard let self, let coordinate else { return }
            
            if (viewModel.bikes ?? []).isEmpty {
                viewModel.loadBikes(currentLocation: coordinate)
            }
            
            let camera = MimoCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 16)
            self.mapView.animate(to: camera)
        }
        .store(in: &cancellables)
        
        viewModel.$currentLocation.sink { [weak self] currentLocation in
            self?.updateZoneStatus(currentLocation: currentLocation, mapZones: self?.viewModel?.mapZones)
        }
        .store(in: &cancellables)
        
        viewModel.$walletInfo.sink { [weak self] walletInfo in
            BikeRouter.shared.scanSheetViewController?.data?.walletInfo = walletInfo
            BikeRouter.shared.bikeDetailsSheetViewController?.viewModel?.walletInfo = walletInfo
            
            self?.set(balance: walletInfo, financialState: viewModel.financialState)
        }
        .store(in: &cancellables)
        
        viewModel.$financialState.sink { [weak self] financialState in
            BikeRouter.shared.scanSheetViewController?.data?.financialState = financialState
            BikeRouter.shared.bikeDetailsSheetViewController?.viewModel?.financialState = financialState
            
            self?.set(balance: viewModel.walletInfo, financialState: financialState)
        }
        .store(in: &cancellables)
        
        viewModel.$user.sink { user in
            BikeRouter.shared.scanSheetViewController?.data?.user = user
        }
        .store(in: &cancellables)
        
        viewModel.$walletState.sink { [weak self] state in
            guard let self else { return }
            
            if state == .Debt || state == .DebtOnDevice {
                BaseRouter.shared.showDebtViewController(self,
                                                         debtAmount: viewModel.financialState?.additional,
                                                         debtWallets: viewModel.financialState?.wallets,
                                                         delegate: self)
            }
        }
        .store(in: &cancellables)
        
        viewModel.$bikes.sink { [weak self] bikes in
            self?.drawBikes()
            self?.bikesCollectionView.reloadData()
            
            if let preSelectedQR = viewModel.preSelectedQR {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    viewModel.selectedBike = bikes?.first(where: { $0.qr == preSelectedQR })
                    viewModel.preSelectedQR = nil
                }
            }
        }
        .store(in: &cancellables)
        
        viewModel.$selectedBikeMarker.sink { [weak self] selectedMarker in
            guard let self else { return }
            
            mapView.selectedMarker = selectedMarker
            guard let position = selectedMarker?.position else { return }
            
            let point = mapView.projection.point(for: position)
            let camera = mapView.projection.coordinate(for: point)
            let cameraUpdate = MimoCameraUpdate.setTarget(camera, zoom: 18)
            mapView.animate(with: cameraUpdate)
            
            if let index = viewModel.bikes?.firstIndex(where: { $0.qr == viewModel.selectedBike?.qr }) {
                viewModel.viewState = .bikeList(index)
            }
        }
        .store(in: &cancellables)
        
        viewModel.$scanData.sink { [weak self] tripData in
            guard let self, let tripData else { return }
            
            guard let mac = tripData.bikeDto?.mac, let bikeID = tripData.bikeDto?.id else {
                self.showAlertMessage("Failed to scan qr", actionText: "Ok", action: { })
                return
            }
            
            if tripData.action == .TripScanned || tripData.action == .TripStarted {
                BLEManager.shareInstance.scan(for: mac,
                                              bikeID: bikeID,
                                              workOption: BLEOption(afterConnectOption: BLEOption.AfterConnect(unlockDevice: true, updateDeviceState: false)))
            }
            
            MILoader.hide()
        }
        .store(in: &cancellables)
        
        viewModel.$tripData.sink { [weak self] tripData in
            guard let self else { return }
            
            if let tripData, tripData.data != nil {
                if tripData.action == .Booking_Started {
                    if let bikeData = tripData.bikeDto {
                        let data = BikeDetailsData(bikeData: HomeMapper.toBikeResults(from: [bikeData]).first,
                                                   walletInfo: viewModel.walletInfo,
                                                   financialState: viewModel.financialState,
                                                   bikeState: tripData, 
                                                   user: viewModel.user)
                        BikeRouter.shared.showBikeDetailsSheet(self, data: data, delegate: self)
                    }
                } else if tripData.action == .BookingEnded {
                    BikeRouter.shared.hideBikeDetailsSheet()
                } else if tripData.action == .TripStarted {
                    viewModel.viewState = .trip(tripData)
                } else if tripData.action == .TripEnded {
                    viewModel.viewState = .initial
                } else {
                    BikeRouter.shared.bikeDetailsSheetViewController?.viewModel?.bikeState = nil
                    BikeRouter.shared.hideBikeDetailsSheet()
                }
            } else {
                switch viewModel.viewState {
                case .trip:
                    viewModel.viewState = .initial
                default:
                    break
                }
            }
        }
        .store(in: &cancellables)
        
        viewModel.$mapZones.sink { [weak self] zones in
            guard let zones else { return }
            self?.draw(zones: zones, withHoles: true)
            self?.updateZoneStatus(currentLocation: viewModel.currentLocation, mapZones: zones)
        }
        .store(in: &cancellables)
        
        viewModel.$preScannedQR.sink { [weak self] qr in
            guard let qr else { return }
            self?.didFinishScan(with: qr, type: .bike)
        }
        .store(in: &cancellables)
        
        viewModel.$preSelectedQR.sink { qr in
            guard let qr else { return }
            
            viewModel.selectedBike = viewModel.bikes?.first(where: { $0.qr == qr })
        }
        .store(in: &cancellables)
        
        viewModel.$isUserInvited.sink { [weak self] isInvited in
            guard let isInvited, isInvited else { return }
            self?.showMimoAlert(.important(isSuccess: true, message: "User successfully invited"))
        }
        .store(in: &cancellables)
        
        viewModel.$news.sink { [weak self] news in
            guard let news, !news.isEmpty else { return }
            
            BaseRouter.shared.showNewsViewController(self, news: news)
        }
        .store(in: &cancellables)
    }
    
    override func transferToFriendViewControllerDismisses() {
        viewModel?.loadBalance()
    }
}

//MARK: - Actions
extension BikeViewController {
    
    @IBAction private func bikesBackAction() {
        viewModel?.viewState = .initial
    }
    
    @IBAction private func myLocationAction() {
        viewModel?.updateMyLocation()
    }
    
    @IBAction private func infoAction() {
        BikeRouter.shared.showOnboardingViewController(self)
    }
}

extension BikeViewController {
    func drawBikes() {
        clusterManager?.clearItems()
        viewModel?.bikesMarkers.forEach { marker in
            self.clusterManager?.add(marker)
        }
        clusterManager?.cluster()
    }
    
    func updateZoneStatus(currentLocation: CLLocationCoordinate2D?, mapZones: [Zone]?) {
        guard let currentLocation, viewModel?.tripData?.data != nil else { zoneStatusView.isHidden = true; return }
        let zones = mapZones ?? viewModel?.mapZones ?? []
        zoneStatusView.isHidden = zones.isEmpty
        supportView.isHidden = !zoneStatusView.isHidden
        let isInParkingZone = PolygonDrawer.shared.zoneType(for: currentLocation) == .RIDE
        zoneStatusView.isInParkingZone = isInParkingZone
    }
}

extension BikeViewController: ScanSheetViewControllerDelegate {
    func scanSheetAction(actionType: ScanSheetAction) {
        BLEManager.shareInstance.checkBluetoothConnectionState = { [weak self] state in
            guard let self = self else { return }
            
            switch state {
            case .poweredOn:
                ScanRouter.shared.showQrScanViewController(self, type: .bike, delegate: self)
            case .poweredOff, .resetting, .unauthorized, .unsupported, .unknown:
                self.openAppOrSystemSettingsAlert(title: "MimoBike would like to use Bluetooth for new conection",
                                                  message: "You can allow connection in Settings")
            @unknown default:
                print("")
            }
            
            print(state)
            
            if state == .poweredOff {
                //TODO: Update this property in an App Manager class
                
            }
        }
        
        BLEManager.shareInstance.configBLE()
    }
}

extension BikeViewController: MimoScanQrViewControllerDelegate {
    
    func didFinishScan(with value: String, type: MimoType) {
        guard let currentLocation = viewModel?.currentLocation else { return }
        
        MILoader.show()
        viewModel?.scanBike(code: value, location: currentLocation)
    }
}

extension BikeViewController: MimoMapViewDelegate {
    func mapView(_ mapView: MimoMapView, didTap marker: MimoMarker) -> Bool {
        if marker.userData is MimoCluster {
            mapView.animate(toLocation: marker.position)
            mapView.animate(toZoom: 18)
        } else {
            guard let bikeData = viewModel?.bikes?.first(where: { $0.latitude == marker.position.latitude && $0.longitude == marker.position.longitude }) else { return false }
            viewModel?.selectedBike = bikeData
        }
        
        return true
    }
    
    func mapView(_ mapView: MimoMapView, didChange position: MimoCameraPosition) {
        guard let zones = viewModel?.mapZones else { return }
        draw(zones: zones, withHoles: position.zoom > 11)
    }
    
    func mapView(_ mapView: MimoMapView, markerInfoWindow marker: MimoMarker) -> UIView? {
        return nil
    }
    
    func mapView(_ mapView: MimoMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        let zoneType = PolygonDrawer.shared.zoneType(for: coordinate)
        ScooterRouter.shared.showZoneInfo(self, zoneType: zoneType)
    }
}

extension BikeViewController: ShowDebtViewControllerDdelegate {
    
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

extension BikeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.bikes?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: BikeCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        
        if let bike = viewModel?.bikes?[indexPath.row] {
            cell.set(bike: bike)
        }
        
        cell.delegate = self
        
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleIndexPath = bikesCollectionView.getCurrentVisibleCellIndexPath()
        viewModel?.selectedBike = viewModel?.bikes?[visibleIndexPath.row]
    }
}

extension BikeViewController: BikeCollectionViewCellDelegate {
    
    func bookAction(for cell: BikeCollectionViewCell) {
        guard let indexPath = bikesCollectionView.indexPath(for: cell),
              let bike = viewModel?.bikes?[indexPath.row] else { return }
        
        bookAction(id: bike.id)
    }
    
    func takeAction(for cell: BikeCollectionViewCell) {
        guard let indexPath = bikesCollectionView.indexPath(for: cell),
                let bike = viewModel?.bikes?[indexPath.row] else { return }
        
        let data = BikeDetailsData(
            bikeData: bike,
            walletInfo: viewModel?.walletInfo,
            financialState: viewModel?.financialState,
            bikeState: viewModel?.tripData,
            user: viewModel?.user
        )
        BikeRouter.shared.showBikeDetailsSheet(self, data: data, delegate: self)
    }
}

extension BikeViewController: BikeDetailsSheetViewControllerDelegate {
    
    func bookAction(id: String) {
        guard let currentLocation = viewModel?.currentLocation else { return }
        viewModel?.bookBike(id: id, location: currentLocation)
        viewModel?.viewState = .initial
    }
    
    func cancelBooking(id: String) {
        viewModel?.cancelBikeBooking(id: id)
    }
    
    func tariffsAction() {
        BikeRouter.shared.showTariffsViewController(self)
    }
}

extension BikeViewController: BLEManagerDelegate {
    
    func changeBleState(bleState: BleDeviceState) {
        
        switch bleState {
        case .locked:
            BLEManager.shareInstance.dinsconnect()
        case .unLocked:
            break
        case .connectionLost:
//            if case .scan = self.state {
//                sendNotification()
//            }
            break
        }
    }
}
