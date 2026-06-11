//
//  ScooterViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 02.05.23.
//

import UIKit
import GoogleMaps
import GoogleMapsUtils
import Combine
import SwiftMessages
import SwiftUI

class ScooterViewController: MimoBaseViewController {
    
    //MARK: - Outlets
    @IBOutlet private weak var mapView: GMSMapView!
    @IBOutlet private weak var scooterCollectionView: UICollectionView!
    @IBOutlet private weak var scooterCollectionBackButton: UIButton!
    @IBOutlet private weak var collectionContainerView: UIView!
    @IBOutlet private weak var multiScooterView: MultiTransportView!
    @IBOutlet private weak var myLocationButton: UIButton!
    @IBOutlet private weak var parkingsButton: UIButton!
    @IBOutlet private weak var supportView: MimoSupportView!
    @IBOutlet private weak var zoneStatusView: ZoneStatusView!
    
    @IBOutlet private weak var myLocationBottomConstraint: NSLayoutConstraint!
    
    private var forbiddenMarkers: [GMSMarker] = []

    //MARK: - Private properties
    var viewModel: MimoScooterViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var clusterManager: GMUClusterManager?
    
    private var isTransferDebtSelected: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupMapCluster()
        setupPublishers()
        registerTransferToFriendViewControllerObserver()
        
        viewModel?.loadParkings()
        viewModel?.socketConnect()
        viewModel?.fetchScooterTrips()
        viewModel?.getMapZones()
        viewModel?.getNews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel?.loadBalance()
    }
    
    deinit {
        ScooterRouter.shared.reset()
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
            
            if (viewModel.scooters ?? []).isEmpty {
                viewModel.loadScooters(currentLocation: coordinate)
            }
            
            let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 16)
            self.mapView.animate(to: camera)
        }
        .store(in: &cancellables)
        
        viewModel.$scooters.sink { [weak self] scooters in
            self?.scooterCollectionView.reloadData()
            
            if let selectedQR = viewModel.preSelectedQR {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    viewModel.selectedScooter = scooters?.first(where: { $0.qr == selectedQR })
                    viewModel.preSelectedQR = nil
                }
            }
        }
        .store(in: &cancellables)
        
        viewModel.$scooterMarkers.sink { [weak self] markers in
            self?.drawScooters(markers)
            
            if let trip = viewModel.scooterStateData?.first(where: { $0.scooter?.qr == viewModel.selectedTrip?.scooter?.qr }) {
                if let latitude = trip.scooter?.located?.latitude, let longitude = trip.scooter?.located?.longitude {
                    self?.updateZoneStatus(currentLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), parkings: viewModel.parkingMarkers)
                }
            }
        }
        .store(in: &cancellables)
        
        viewModel.$parkingMarkers.sink { [weak self] markers in
            self?.drawParkings(parkingMarkers: markers)
            
            if let latitude = viewModel.selectedTrip?.scooter?.located?.latitude, let longitude = viewModel.selectedTrip?.scooter?.located?.longitude {
                self?.updateZoneStatus(currentLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), parkings: markers)
            }
            
            ScooterRouter.shared.scooterTripSheetViewController?.viewModel?.parkingLocations = markers.compactMap({ $0.position })
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
        
        viewModel.$selectedScooterMarker.sink { [weak self] selectedMarker in
            guard let self else { return }
            
            mapView.selectedMarker = selectedMarker
            guard let position = selectedMarker?.position else { return }
            
            let point = mapView.projection.point(for: position)
            let camera = mapView.projection.coordinate(for: point)
            let cameraUpdate = GMSCameraUpdate.setTarget(camera, zoom: 18)
            mapView.animate(with: cameraUpdate)
            
            if viewModel.scooterStateData == nil || (viewModel.scooterStateData != nil && viewModel.scooterStateData!.isEmpty) {
                if let index = viewModel.scooters?.firstIndex(where: { $0.qr == self.viewModel?.selectedScooter?.qr }) {
                    viewModel.viewState = .scooterList(index)
                }
            }
        }
        .store(in: &cancellables)
        
        viewModel.$scooterStateData.sink { [weak self] data in
            guard let data, !data.isEmpty else { self?.viewModel?.viewState = .initial; return }
            
            self?.viewModel?.viewState = .trip(data)
        }
        .store(in: &cancellables)
        
        viewModel.$scooterTripData.sink { [weak self] data in
            ScooterRouter.shared.scooterTripSheetViewController?.viewModel?.set(scooterStateModel: data)
            
            if data?.scooter?.id == viewModel.selectedTrip?.scooter?.id {
                if let latitude = data?.scooter?.located?.latitude, let longitude = data?.scooter?.located?.longitude {
                    self?.updateZoneStatus(currentLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), parkings: viewModel.parkingMarkers)
                }
            }
        }
        .store(in: &cancellables)
        
        viewModel.$selectedTrip.sink { [weak self] trip in
            guard let trip else { return }
            
            self?.multiScooterView.selected = trip.scooter?.qr
            
            if let latitude = trip.scooter?.located?.latitude, let longitude = trip.scooter?.located?.longitude {
                let camera = GMSCameraPosition.camera(withLatitude: latitude, longitude: longitude, zoom: 17)
                self?.mapView.animate(to: camera)
                self?.updateZoneStatus(currentLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), parkings: viewModel.parkingMarkers)
            }
        }
        .store(in: &cancellables)
        
        viewModel.$mapZones.sink { [weak self] zones in
            guard let self, let zones else { return }
            self.draw(zones: zones, withHoles: true)
        }
        .store(in: &cancellables)
        
        viewModel.$preScannedQR.sink { [weak self] qr in
            guard let qr else { return }
            self?.didFinishScan(with: qr, type: .scooter)
        }
        .store(in: &cancellables)
        
        viewModel.$preSelectedQR.sink { [weak self] qr in
            guard let qr else { return }
            self?.viewModel?.selectedScooter = viewModel.scooters?.first(where: { $0.qr == qr })
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
    }
    
    override func transferToFriendViewControllerDismisses() {
        viewModel?.loadBalance()
    }
}

//MARK: - IBActions
extension ScooterViewController {
    
    @IBAction private func scootersBackAction() {
        viewModel?.viewState = .initial
    }
    
    @IBAction private func myLocationAction() {
        viewModel?.updateMyLocation()
    }
    
    @IBAction private func parkingsAction() {
        ScooterRouter.shared.showZoneInfo(self, zoneType: nil)
    }
}

//MARK: - UI
extension ScooterViewController {
    
    private func updateUI(for state: MimoScooterViewState) {
        switch state {
        case .initial:
            ScooterRouter.shared.hideScooterDetailsSheet()
            ScooterRouter.shared.hideScooterTripSheet()
            ScooterRouter.shared.showScanSheet(self, data: ScanSheetViewController.Data(mimoType: .scooter,
                                                                                        walletInfo: viewModel?.walletInfo,
                                                                                        financialState: viewModel?.financialState,
                                                                                        user: viewModel?.user
                                                                                       ), delegate: self)
            collectionContainerView.fadeOut()
            viewModel?.selectedScooter = nil
            multiScooterView.isHidden = true
            supportView.isHidden = false
            zoneStatusView.isHidden = true
            updateMyLocationPosition(constant: 100)
        case .scooterList(let selectedIndex):
            ScooterRouter.shared.hideScanSheet()
            if collectionContainerView.alpha == 0 {
                collectionContainerView.fadeIn()
            }
            multiScooterView.isHidden = true
            scooterCollectionView.scrollToItem(at: IndexPath(item: selectedIndex, section: 0), at: .centeredHorizontally, animated: true)
            updateMyLocationPosition(constant: 208)
        case .trip(let scooterTrips):
            guard let scooterTrips else { return }
            
            if !(viewModel?.bookingStartedList.isEmpty ?? false) {
                let args = ["scooterState": viewModel?.bookingStartedList.first as Any,
//                            "hasLeasedScooters": viewModel?.leasedScooters.contains(scooter.qr) ?? false,
                            "walletInfo": viewModel?.walletInfo as Any,
                            "financialState": viewModel?.financialState as Any,
                            "user": viewModel?.user as Any]
                
//                ScooterRouter.shared.hideScooterDetailsSheet()
                ScooterRouter.shared.showScooterDetailsSheet(self, viewModel: Resolver.optional(args: args), delegate: self, dismissible: false)
            } else {
                ScooterRouter.shared.hideScooterDetailsSheet()
                
                let scooterTripViewModel: ScooterTripViewModel? = Resolver.optional(args: scooterTrips)
                scooterTripViewModel?.parkingLocations = viewModel?.parkingMarkers.compactMap({ $0.position }) ?? []
                ScooterRouter.shared.showScooterTripSheet(self, viewModel: scooterTripViewModel, delegate: self)
                multiScooterView.isHidden = false
                multiScooterView.selected = viewModel?.selectedTrip?.scooter?.qr
                multiScooterView.data = scooterTrips.compactMap({ $0.scooter?.qr })
                
                if let trip = scooterTrips.first(where: { $0.scooter?.qr == viewModel?.selectedTrip?.scooter?.qr }) {
                    if let latitude = trip.scooter?.located?.latitude, let longitude = trip.scooter?.located?.longitude {
                        updateZoneStatus(currentLocation: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), parkings: viewModel?.parkingMarkers)
                    }
                }
            }
            
            supportView.isHidden = true
            updateMyLocationPosition(constant: 400)
        }
    }
    
    private func setupUI() {
        makeNavigationBarWithBackButton(productType: .scooter)
        
        //MARK: - Global UI configs
        scooterCollectionBackButton.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
        myLocationButton.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
        parkingsButton.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
        
        //MARK: - MapView
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        
        //MARK: - CollectionView
        setupCollectionView()
        
        //MARK: - MultiTransportView
        multiScooterView.delegate = self
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
        scooterCollectionView.collectionViewLayout = floawLayout
        scooterCollectionView.showsHorizontalScrollIndicator = false
        
        scooterCollectionView.register(ScooterCollectionViewCell.self)
    }
    
    private func setupMapCluster() {
        let iconGenerator = MimoClusterIconGenerator()
        let algorithm = GMUNonHierarchicalDistanceBasedAlgorithm(clusterDistancePoints: 100) ?? GMUNonHierarchicalDistanceBasedAlgorithm()
        let renderer = GMUDefaultClusterRenderer(mapView: self.mapView, clusterIconGenerator: iconGenerator)
        renderer.minimumClusterSize = 1
        renderer.maximumClusterZoom = 16
        renderer.animatesClusters = true
        self.clusterManager = GMUClusterManager(map: self.mapView, algorithm: algorithm, renderer: renderer)
        self.clusterManager?.setMapDelegate(self)
    }
    
    private func drawScooters(_ markers: [GMSMarker]) {
        clusterManager?.clearItems()
        markers.forEach { marker in
            self.clusterManager?.add(marker)
        }
        clusterManager?.cluster()
    }
    
    private func drawParkings(parkingMarkers: [GMSMarker]) {
        parkingMarkers.forEach { marker in
            if marker.isVisible(on: mapView) && mapView.camera.zoom > 12 {
                marker.map = mapView
            } else {
                marker.map = nil
            }
        }
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
                let marker = GMSMarker(position: center)
                marker.icon = "noRidingSmall".image
                marker.userData = ZoneType.FORBIDDEN
                
                self.forbiddenMarkers.append(marker)
            })
        }
        
        if withHoles {
            forbiddenMarkers.forEach({ $0.map = mapView })
        } else {
            forbiddenMarkers.forEach({ $0.map = nil })
        }
    }
    
    private func updateZoneStatus(currentLocation: CLLocationCoordinate2D?, parkings: [GMSMarker]?) {
        guard let currentLocation = currentLocation, !(viewModel?.scooterStateData?.isEmpty ?? false) else { zoneStatusView.isHidden = true; return }
        let parkings = parkings ?? viewModel?.parkingMarkers ?? []
        zoneStatusView.isHidden = parkings.isEmpty
        let parkingsLocations = parkings.compactMap({ $0.position })
        let nearParkings = parkingsLocations.filter({ $0.distance(to: currentLocation) <= 35 })
        self.zoneStatusView.isInParkingZone = !nearParkings.isEmpty
    }
}

//MARK: - BottomSheet
extension ScooterViewController: ScanSheetViewControllerDelegate {
    
    func scanSheetAction(actionType: ScanSheetAction) {
        switch actionType {
        case .scanQr:
            ScanRouter.shared.showQrScanViewController(self, delegate: self)
        case .rates:
//            viewModel.viewState = .scooterList
            break
        }
    }
}

extension ScooterViewController: MimoScanQrViewControllerDelegate {
    
    func didFinishScan(with value: String, type: MimoType) {
        ScooterPlanRouter.shared.showScooterPlanViewController(self, scooterId: value, leasedScooters: viewModel?.leasedScooters, delegate: self)
    }
}

extension ScooterViewController: ScooterPlanViewControllerDelegate {
    func didSelectBookNow(scooterId: String) {
        self.bookScooter(with: scooterId)
    }
    
    func didStartLeasedScooter(with scooterId: String) {
        guard let qr = viewModel?.scooters?.first(where: { $0.qr == scooterId })?.id else { return }
        viewModel?.startLeasedScooter(id: qr)
    }
    
    func didStopLeasedScooter(with scooterId: String) {
        guard let qr = viewModel?.scooters?.first(where: { $0.qr == scooterId })?.id else { return }
        viewModel?.stopLeasedScooter(id: qr)
    }
    
    func didOpenLeasedScooter(with scooterId: String) {
        guard let qr = viewModel?.scooters?.first(where: { $0.qr == scooterId })?.id else { return }
        viewModel?.openLeasedScooter(id: qr)
    }
}

//MARK: - GMSMapViewDelegate
extension ScooterViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        drawParkings(parkingMarkers: viewModel?.parkingMarkers ?? [])
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        if (marker.userData as? String)?.hasPrefix("Parking") != nil {
            ScooterRouter.shared.showParkingInfo(self)
            return false
        }
        
        if (marker.userData as? ZoneType) == .FORBIDDEN {
            ScooterRouter.shared.showZoneInfo(self, zoneType: .FORBIDDEN)
            return false
        }
        
        if let scooterStateData = viewModel?.scooterStateData, !scooterStateData.isEmpty {
            return false
        }
        
        if marker.userData is GMUCluster {
            mapView.animate(toLocation: marker.position)
            mapView.animate(toZoom: 18)
        } else {
            guard let scooterData = viewModel?.scooters?.first(where: { $0.latitude == marker.position.latitude && $0.longitude == marker.position.longitude }) else { return false }
            viewModel?.selectedScooter = scooterData
        }
        
        return true
    }
    
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        guard let zones = viewModel?.mapZones else { return }
        draw(zones: zones, withHoles: position.zoom > 11)
    }
    
    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
        return nil
    }
    
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        let zoneType = PolygonDrawer.shared.zoneType(for: coordinate)
        ScooterRouter.shared.showZoneInfo(self, zoneType: zoneType)
    }
}

//MARK: - ScooterDetailsSheetViewControllerDelegate
extension ScooterViewController: ScooterDetailsSheetViewControllerDelegate {
    
    func bookScooter(with id: String) {
        guard let location = viewModel?.currentLocation else { return }
        viewModel?.bookScooter(id: id, location: location)
    }
    
    func cancelScooterBooking(with id: String) {
        viewModel?.cancelScooterBooking(id: id)
    }
    
    func startRide(with scooterId: String) {
        ScooterPlanRouter.shared.showScooterPlanViewController(self, scooterId: scooterId, leasedScooters: viewModel?.leasedScooters, delegate: self)
    }
    
    func startLeasedScooter(with scooterId: String) {
        viewModel?.startLeasedScooter(id: scooterId)
    }
    
    func stopLeasedScooter(with scooterId: String) {
        viewModel?.stopLeasedScooter(id: scooterId)
    }
    
    func openLeasedScooter(with scooterId: String) {
        viewModel?.openLeasedScooter(id: scooterId)
    }
    
    func scooterBookingEnded() {
        viewModel?.fetchScooterTrips()
    }
}

//MARK: - UICollectionViewDataSource
extension ScooterViewController: ScooterCollectionViewCellDelegate {
    
    func chooseScooterAction(for cell: ScooterCollectionViewCell) {
        guard let indexPath = scooterCollectionView.indexPath(for: cell),
                let scooter = viewModel?.scooters?[indexPath.row] else { return }
        
        viewModel?.selectedScooter = scooter
        let args = ["scooterData": scooter,
                    "hasLeasedScooters": viewModel?.leasedScooters.contains(scooter.qr) ?? false,
                    "walletInfo": viewModel?.walletInfo as Any,
                    "financialState": viewModel?.financialState as Any,
                    "user": viewModel?.user as Any]
        
        ScooterRouter.shared.showScooterDetailsSheet(self, viewModel: Resolver.optional(args: args), delegate: self)
    }
    
    func bookScooterAction(for cell: ScooterCollectionViewCell) {
        guard let indexPath = scooterCollectionView.indexPath(for: cell),
                let scooter = viewModel?.scooters?[indexPath.row] else { return }
        
        self.bookScooter(with: scooter.id)
    }
}

extension ScooterViewController: MultiTransportViewDelegate, ScooterTripSheetViewControllerDelegate {
    
    func didSelectScooter(with index: Int) {
        didSelectItem(with: index)
    }
    
    func didSelectItem(with index: Int) {
        ScooterRouter.shared.scooterTripSheetViewController?.scrollToScooter(with: index)
        viewModel?.updateSelectedTrip(with: index)
    }
    
    func didSelectNewItem() {
        scanSheetAction(actionType: .scanQr)
    }
}

extension ScooterViewController: ShowDebtViewControllerDdelegate {
    
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
extension ScooterViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == scooterCollectionView {
            return viewModel?.scooters?.count ?? 0
        } else {
            return 1
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ScooterCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.set(scooter: viewModel?.scooters?[indexPath.item])
        cell.delegate = self
        
        return cell
    }
}

extension ScooterViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleIndexPath = scooterCollectionView.getCurrentVisibleCellIndexPath()
        viewModel?.selectedScooter = viewModel?.scooters?[visibleIndexPath.row]
    }
}

