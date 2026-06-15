//
//  ChargerViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 16.11.23.
//

import UIKit
import CoreLocation
//import GoogleMapsUtils
import Combine

class ChargerViewController: MimoBaseViewController {
    
    private var cancellables = Set<AnyCancellable>()
//    private var clusterManager: MimoClusterManager?
    
    //MARK: - Outlets
    @IBOutlet private weak var mapView: MimoMapView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewContainerView: UIView!
    @IBOutlet private weak var collectionBackButton: UIButton!
    @IBOutlet private weak var myLocationButton: UIButton!
    @IBOutlet private weak var discountsButton: UIButton!
    @IBOutlet private weak var multiRentView: MultiTransportView!
    
    @IBOutlet private weak var locationButtonBottomConstraint: NSLayoutConstraint!
    
    var viewModel: ChargerViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupPublishers()
//        setupMapCluster()
        
        viewModel?.socketConnect()
        viewModel?.getState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel?.loadBalance()
    }
    
    deinit {
        ChargerRouter.shared.reset()
        viewModel?.unsubscribe()
    }
    
    private func setupPublishers() {
        guard let viewModel else { return }
        
        viewModel.$errorMessage.sink { [weak self] errorMessage in
            guard let errorMessage else { return }
            self?.showErrorPopUp(message: errorMessage, service: .charger)
            
            MILoader.hide()
        }
        .store(in: &cancellables)
        
        viewModel.$viewState.sink { [weak self] viewState in
            self?.updateUI(for: viewState)
        }
        .store(in: &cancellables)
        
        viewModel.$startLocation.sink { [weak self] coordinate in
            guard let self, let coordinate else { return }
            
            if (viewModel.stations.value ?? []).isEmpty {
                viewModel.getChargingStations(currentLocation: coordinate)
            }
            
            let camera = MimoCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 18)
            self.mapView.animate(to: camera)
        }
        .store(in: &cancellables)
        
        viewModel.$walletInfo.sink { [weak self] walletInfo in
            ChargerRouter.shared.scanSheetViewController?.data?.walletInfo = walletInfo
            
            self?.set(balance: walletInfo, financialState: viewModel.financialState)
        }
        .store(in: &cancellables)
        
        viewModel.$financialState.sink { [weak self] financialState in
            ChargerRouter.shared.scanSheetViewController?.data?.financialState = financialState
            
            self?.set(balance: viewModel.walletInfo, financialState: financialState)
        }
        .store(in: &cancellables)
        
        viewModel.$user.sink { user in
            ChargerRouter.shared.scanSheetViewController?.data?.user = user
        }
        .store(in: &cancellables)
        
        viewModel.stations.sink { [weak self] stations in
            self?.collectionView.reloadData()
            
            if let preSelectedQR = viewModel.preSelectedQR {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
                    viewModel.selectedStation = stations?.first(where: { $0.id == preSelectedQR })
                    viewModel.preSelectedQR = nil
                }
            }
        }
        .store(in: &cancellables)
        
        viewModel.$stationsMarkers.sink { [weak self] stations in
            guard let stations else { return }
            
            self?.drawStations(stations)
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
            
            if let index = viewModel.stations.value?.firstIndex(where: { $0.id == self.viewModel?.selectedStation?.id }) {
                viewModel.viewState = .chargerList(index)
            }
        }
        .store(in: &cancellables)
        
        viewModel.$news.sink { [weak self] news in
            guard let news, !news.isEmpty else { return }
            
            BaseRouter.shared.showNewsViewController(self, news: news)
        }
        .store(in: &cancellables)
        
        viewModel.$rentedChargers.sink { [weak self] rentedChargers in
            guard let self else { return }
            
            MILoader.hide()
            
            let _rentedChargers = rentedChargers.filter({ $0.state == .rentStarted })
            let _rentEndedChargers = rentedChargers.filter({ $0.state == .rentEnded })
            let _rentScannedChargers = rentedChargers.filter({ $0.state == .rentScanned })
            
            if !_rentedChargers.isEmpty {
                self.viewModel?.viewState = .rent(rentedChargers)
            }
            
            if !_rentEndedChargers.isEmpty {
                ChargerRouter.shared.showChargerSuccessViewController(self, currency: viewModel.walletInfo?.currency, rentedCharger: _rentEndedChargers.first)
                
                if _rentedChargers.isEmpty && _rentScannedChargers.isEmpty {
                    self.viewModel?.viewState = .initial
                }
            }
            
            if !_rentScannedChargers.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self.viewModel?.getState()
                }
            }
            
            if rentedChargers.isEmpty {
                self.viewModel?.viewState = .initial
            }
        }
        .store(in: &cancellables)
        
        viewModel.$preScannedQR.sink { [weak self] qr in
            guard let qr else { return }
            self?.didFinishScan(with: qr, type: .charger)
        }
        .store(in: &cancellables)
        
        viewModel.$preSelectedQR.sink { id in
            guard let id else { return }
            
            viewModel.selectedStation = viewModel.stations.value?.first(where: { $0.id == id })
        }
        .store(in: &cancellables)
    }
    
    private func setupUI() {
        //MARK: - Global UI configs
        makeNavigationBarWithBackButton(rightButtons: [.notification], productType: .charger)
        collectionBackButton.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
        myLocationButton.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
        discountsButton.addShadow(color: .black.withAlphaComponent(0.4), offset: .init(width: 0, height: 4), shadowRadius: 12)
        discountsButton.isHidden = true

        //MARK: - MapView
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
        
        //MARK: - CollectionView
        setupCollectionView()
        
        //MARK: - Multi Rent
        multiRentView.service = .charger
        multiRentView.delegate = self
        multiRentView.maxCount = 4
    }
    
    private func setupCollectionView() {
        let floawLayout = UPCarouselFlowLayout()
        floawLayout.itemSize = CGSize(width: Constant.Width.width075, height: 194)
        floawLayout.scrollDirection = .horizontal
        floawLayout.sideItemScale = 1
        floawLayout.sideItemAlpha = 1
        floawLayout.spacingMode = .fixed(spacing: 10.0)
        collectionView.collectionViewLayout = floawLayout
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.register(ChargerCollectionViewCell.self)
    }
}

//MARK: - UI
extension ChargerViewController {
    
    private func updateUI(for state: MimoChargerViewState) {
        switch state {
        case .initial:
            ChargerRouter.shared.hideChargerDetailsSheet()
            ChargerRouter.shared.hideRentedChargerSheet()
            
            ChargerRouter.shared.showScanSheet(self, data: ScanSheetViewController.Data(
                mimoType: .charger,
                walletInfo: viewModel?.walletInfo,
                financialState: viewModel?.financialState,
                user: viewModel?.user
            ), delegate: self)
            
            collectionViewContainerView.fadeOut()
            viewModel?.selectedStation = nil
            updateLocationButtonPosition(constant: 100)
            multiRentView.isHidden = true
            viewModel?.selectedPowerBank = nil
        case .chargerList(let selectedIndex):
            ChargerRouter.shared.hideScanSheet()
            if collectionViewContainerView.alpha == 0 {
                collectionViewContainerView.fadeIn()
            }
            
            collectionView.scrollToItem(at: IndexPath(row: selectedIndex, section: 0), at: .centeredHorizontally, animated: true)
            updateLocationButtonPosition(constant: 210)
            
            multiRentView.isHidden = true
        case .rent(let rentedChargers):
            ChargerRouter.shared.hideScanSheet()
            ChargerRouter.shared.hideChargerDetailsSheet(force: false)
            
            ChargerRouter.shared.showRentedChargerSheet(self, rentedChargers: rentedChargers, currency: viewModel?.walletInfo?.currency ?? "₽‎", delegate: self)
            updateLocationButtonPosition(constant: 280)
            
            if viewModel?.selectedPowerBank == nil {
                viewModel?.selectedPowerBank = rentedChargers.first?.powerBank?.id
            }
            
            multiRentView.isHidden = false
            multiRentView.selected = viewModel?.selectedPowerBank
            multiRentView.data = rentedChargers.compactMap({ $0.powerBank?.id })
        }
    }
    
    private func updateLocationButtonPosition(constant: CGFloat) {
        locationButtonBottomConstraint.constant = constant
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func drawStations(_ stations: [MimoMarker]) {
        viewModel?.stationsMarkers?.forEach({ $0.map = nil })
        stations.forEach({ $0.map = mapView })
//        clusterManager?.clearItems()
//        stations.forEach { marker in
//            self.clusterManager?.add(marker)
//        }
//        
//        clusterManager?.cluster()
    }
    
//    private func setupMapCluster() {
//        let iconGenerator = MimoClusterIconGenerator()
//        let algorithm = MimoNonHierarchicalDistanceBasedAlgorithm(clusterDistancePoints: 100) ?? MimoNonHierarchicalDistanceBasedAlgorithm()
//        let renderer = MimoDefaultClusterRenderer(mapView: self.mapView, clusterIconGenerator: iconGenerator)
//        renderer.minimumClusterSize = 1
//        renderer.maximumClusterZoom = 16
//        renderer.animatesClusters = true
//        self.clusterManager = MimoClusterManager(map: self.mapView, algorithm: algorithm, renderer: renderer)
//        self.clusterManager?.setMapDelegate(self)
//    }
}

//MARK: - Actions
extension ChargerViewController {
    @IBAction private func stationsBackAction() {
        viewModel?.viewState = .initial
    }
    
    @IBAction private func myLocationAction() {
        viewModel?.updateMyLocation()
    }
    
    @IBAction private func specialDiscountsAction() {
        ChargerRouter.shared.showSpecialDiscountsScreen(self)
    }
}

//MARK: - BottomSheet
extension ChargerViewController: ScanSheetViewControllerDelegate {
    
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

extension ChargerViewController: MimoScanQrViewControllerDelegate {
    
    func didFinishScan(with value: String, type: MimoType) {
        guard let location = viewModel?.currentLocation else { return }
        
        MILoader.show()
        viewModel?.scan(stationId: value, currentLocation: location)
    }
}

extension ChargerViewController: ChargerCollectionViewCellDelegate {
    
    func didSelectChoose(cell: ChargerCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        ChargerRouter.shared.showChargerDetailsSheet(
            self,
            viewModel: ChargingStationDetailsViewModel(
                chargingStation: viewModel?.stations.value?[indexPath.row],
                walletInfo: viewModel?.walletInfo,
                financialState: viewModel?.financialState,
                user: viewModel?.user
            ),
            delegate: self
        )
    }
    
    func didSelectScan(cell: ChargerCollectionViewCell) {
        ScanRouter.shared.showQrScanViewController(self, delegate: self)
    }
}

extension ChargerViewController: ChargingStationSheetViewControllerDelegate {
    func didSelectTariffs() {
        RatesRouter.shared.showRatesViewController(self, supportedMimoTypes: [.charger], mimoType: .charger)
    }
    
    func didSelectScan() {
        ScanRouter.shared.showQrScanViewController(self, delegate: self)
    }
}

//MARK: - MimoMapViewDelegate
extension ChargerViewController: MimoMapViewDelegate {
    
    func mapView(_ mapView: MimoMapView, didTap marker: MimoMarker) -> Bool {
        
//        if marker.userData is MimoCluster {
//            mapView.animate(toLocation: marker.position)
//            mapView.animate(toZoom: 18)
//        } else {
            if let rentedChargers = viewModel?.rentedChargers, !rentedChargers.isEmpty {
//                if (marker.userData as? MimoCluster) == nil {
                    guard let station = viewModel?.stations.value?.first(where: { ($0.location?.latitude ?? 0) == marker.position.latitude && ($0.location?.longitude ?? 0) == marker.position.longitude }) else { return false }
                    
                    ChargerRouter.shared.showChargerDetailsSheet(
                        self,
                        viewModel: ChargingStationDetailsViewModel(
                            chargingStation: station,
                            walletInfo: viewModel?.walletInfo,
                            financialState: viewModel?.financialState,
                            user: viewModel?.user
                        ),
                        delegate: self,
                        autoHiddenDetailsSheet: false
                    )
//                }
                
                return false
            }
            
            guard let station = viewModel?.stations.value?.first(where: { ($0.location?.latitude ?? 0) == marker.position.latitude && ($0.location?.longitude ?? 0) == marker.position.longitude }) else { return false }
            viewModel?.selectedStation = station
//        }
        
        return true
    }
}

//MARK: - UICollectionViewDataSource
extension ChargerViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.stations.value?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ChargerCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.delegate = self
        
        if let station = viewModel?.stations.value?[indexPath.row] {
            cell.set(station: station)
        }
        
        return cell
    }
}

extension ChargerViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleIndexPath = collectionView.getCurrentVisibleCellIndexPath()
        viewModel?.selectedStation = viewModel?.stations.value?[visibleIndexPath.row]
    }
}

extension ChargerViewController: MultiTransportViewDelegate, RentedChargerSheetViewControllerDelegate {
    
    func didSelectCharger(with index: Int) {
        didSelectItem(with: index)
    }
    
    func didSelectItem(with index: Int) {
        ChargerRouter.shared.rentedChargerSheetViewController?.scrollToCharger(with: index)
        multiRentView.selected = viewModel?.rentedChargers[index].powerBank?.id
        viewModel?.selectedPowerBank = viewModel?.rentedChargers[index].powerBank?.id
        
        multiRentView.selectedIndex = index
    }
    
    func didSelectNewItem() {
        scanSheetAction(actionType: .scanQr)
    }
}
