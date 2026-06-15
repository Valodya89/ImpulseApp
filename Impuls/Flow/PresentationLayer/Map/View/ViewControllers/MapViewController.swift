//
//  MapViewController.swift
//  MimoBike
//
//  Created by Vardan on 20.04.21.
//

import UIKit
import CoreLocation
final class MapViewController: BaseViewController, StoryboardInitializable {

    
    //MARK: - Outlets
    
    @IBOutlet private weak var mapView: MimoMapView!
    @IBOutlet private weak var bikesContentView: UIView!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var registerAndEnjoyTextLabel: UILabel!
    
    @IBOutlet private weak var bikesBackView: UIView!
    @IBOutlet private weak var currentLocationContentView: UIView!
    @IBOutlet private weak var currentLocationBottomConstraint: NSLayoutConstraint!
    
    
    //MARK: - Variables

    private let homeViewModel = HomeViewModel()
    private var bottomSheet: SheetViewController?
    private var bikes = [BikeResult]()
    private var isAlreadyOpened = false
    
    private var locationManager: MALocation = .current
    
    var markers: [String: MimoMarker] = [:]
    var selectedIndex: IndexPath?
    private var singleBikeBookNowTapped = false
    
    var previousMarker: MimoMarker? {
        didSet {
            previousMarker?.iconView = UIImageView(image: #imageLiteral(resourceName: "ic_bike_marker"))
        }
    }
    var currentMarker: MimoMarker? {
        didSet {
            currentMarker?.iconView = UIImageView(image: #imageLiteral(resourceName: "ic_markerSelected"))
        }
    }

    
    //MARK: - Life cycles

    override func viewDidLoad() {
        super.viewDidLoad()
        
        MALocation.startLocationHeading()
        configureMapView()
        registerCell()
        configureDelegates()
        configureUI()
        configCollectionView()
        getBikes()
        openBottomSheet()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//            self.openBottomSheet()
            self.getZones()
            self.bikesContentView.isHidden = true
            self.bikesContentView.alpha = 0
            //self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
    }
 
    func getZones() {
        homeViewModel.getMapZones { result in
            switch result {
            case .success(let zones):
                print(zones)
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func drawZone() {
        let mapView = self.mapView

            //Add vertex's to Path like as shown bellow
            //get vertices from map
           // https://developers.google.com/maps/documentation/ios-sdk/shapes

        let path = MimoMutablePath()
        path.add(CLLocationCoordinate2D(latitude: 37.36, longitude: -122.0))
        path.add(CLLocationCoordinate2D(latitude: 37.45, longitude: -122.0))
        path.add(CLLocationCoordinate2D(latitude: 37.45, longitude: -122.2))
        path.add(CLLocationCoordinate2D(latitude: 37.36, longitude: -122.2))
        path.add(CLLocationCoordinate2D(latitude: 37.36, longitude: -122.0))

            let polyline = MimoPolyline(path: path)
            polyline.strokeColor = .blue
            polyline.strokeWidth = 5.0
            polyline.map = mapView
    }
    //MARK: - Methods
    
    /// configure user interface
    private func configureUI() {
        bikesContentView.isHidden = true
        bikesContentView.alpha = 0
        bikesBackView.layer.cornerRadius = Constant.CornerRadius.cornerRadius19
        currentLocationContentView.layer.cornerRadius = Constant.CornerRadius.cornerRadius19
        bikesBackView.addShadow(color: .mimoBlackWith025alpha)
        currentLocationContentView.addShadow(color: .mimoBlackWith025alpha)
        currentLocationBottomConstraint.constant = Constant.Constraint.constant184
        registerAndEnjoyTextLabel.colorString(text: registerAndEnjoyTextLabel.text, coloredText: ["enjoy."], color: .mimoBlack, font: UIFont(name: "Roboto-Bold", size: 17)!)
    }

    /// configure map view
    private func configureMapView() {
        mapView.isMyLocationEnabled = true
        mapView.delegate = self
    }
    
    /// configure user interface
    private func configCollectionView() {

        let floawLayout = UPCarouselFlowLayout()
        floawLayout.itemSize = CGSize(width: Constant.Width.width288, height: Constant.Height.height184)
        floawLayout.scrollDirection = .horizontal
        floawLayout.sideItemScale = 1
        floawLayout.sideItemAlpha = 0.7
        floawLayout.spacingMode = .fixed(spacing: 10.0)
        collectionView.collectionViewLayout = floawLayout
        collectionView.showsHorizontalScrollIndicator = false
    }
    
    /// configure Delegates
    private func configureDelegates() {
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    /// register collectionView cell
    private func registerCell() {
        collectionView.register(UINib(nibName: MapBikeCollectionViewCell.reuseIdentifier(), bundle: nil), forCellWithReuseIdentifier: MapBikeCollectionViewCell.reuseIdentifier())
    }
    
    private func centerMapOnCurrentLocation() {
        let camera = MimoCameraPosition.camera(withLatitude: (locationManager.currentLocation?.coordinate.latitude)!, longitude: (locationManager.currentLocation?.coordinate.longitude)!, zoom: 17.0)
        self.mapView?.animate(to: camera)
    }
    
    private func openBottomSheet() {
        
        bikesContentView.isHidden = true
        bikesContentView.alpha = 0
        currentLocationBottomConstraint.constant = Constant.Constraint.constant184
        
        let useInlineMode = view != nil

        let controller = MapJoinNowSheetViewController.initFromStoryboard(name: Constant.Storyboards.map)
        controller.delegate = self
        var options = SheetOptions()
        options.pullBarHeight = 10
        
        options.useInlineMode = useInlineMode
        bottomSheet?.didDismiss = nil
        bottomSheet = nil
        bottomSheet = SheetViewController(
            controller: controller,
            sizes: [.percent(0.1405), .percent(0.1405)],
            options: options)
        guard let bottomSheet = bottomSheet else {
            return
        }
        bottomSheet.sizeChanged = {[weak self] sheet, size, height in
            guard let self = self else { return }
            print("Changed to \(size) with a height of \(height)")
            if size == .percent(0.5222) {
                UIView.animate(withDuration: 0.3) {
                    self.bottomSheet?.dismissOnOverlayTap = true
                    self.bottomSheet?.overlayColor = UIColor.mimoBlackWith03alpha
                }
                
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.bottomSheet?.dismissOnOverlayTap = false
                    self.bottomSheet?.overlayColor = .clear
                }
            }
        }
        
        bottomSheet.allowPullingPastMaxHeight = false
        bottomSheet.allowPullingPastMinHeight = false
        bottomSheet.dismissOnPull = false
        bottomSheet.dismissOnOverlayTap = false
        bottomSheet.gripSize.height = 4
        bottomSheet.gripSize.width = 38
        bottomSheet.gripColor = .clear
        bottomSheet.overlayColor = UIColor.clear
//        bottomSheet.gripColor = UIColor.mimoBlackWith025alpha
        bottomSheet.view.addShadow(color: UIColor.mimoBlackWith025alpha)
        bottomSheet.allowGestureThroughOverlay = true
        
        if let view = view {
            bottomSheet.animateIn(to: view, in: self) {
                
            }
        } else {
            self.present(bottomSheet, animated: true, completion: nil)
        }
    }
    
    ///preview details bike
    func previewBike(result: BikeResult) {
        let useInlineMode = view != nil

        let controller = SingleBikeSheetViewController.initFromStoryboard(name: Constant.Storyboards.map)
        controller.delegate = self
        controller.bikeResult = result
        
        var options = SheetOptions()
        options.pullBarHeight = 10
        options.useInlineMode = useInlineMode
        
        bottomSheet?.didDismiss = nil
        bottomSheet?.attemptDismiss(animated: false)
        bottomSheet = nil
        bottomSheet = SheetViewController(
            controller: controller,
            sizes: [.percent(0.576355)],
            options: options)
        guard let bottomSheet = bottomSheet else {
            return
        }
        
        bottomSheet.didDismiss = {[weak self] controller in
            guard controller.childViewController is SingleBikeSheetViewController else {
                return
            }
            
            guard let self = self, self.bikesContentView.isHidden else { return }
            self.previousMarker = self.currentMarker
            
            self.openBottomSheet()
        }
        bottomSheet.allowPullingPastMaxHeight = false
        bottomSheet.dismissOnPull = true
        bottomSheet.gripSize.height = 4
        bottomSheet.gripSize.width = 38
        bottomSheet.gripColor = UIColor.mimoBlackWith025alpha
        bottomSheet.overlayColor = UIColor.mimoBlackWith03alpha
        bottomSheet.dismissOnOverlayTap = true
        
        bottomSheet.view.addShadow(color: UIColor.mimoBlackWith025alpha)
        
        if let view = view {
            bottomSheet.animateIn(to: view, in: self)
        } else {
            self.present(bottomSheet, animated: true, completion: nil)
        }
    }
    
    /// navigate to signIn screen
    private func goToSignInVC() {
        let signInVC = SignInViewController.initFromStoryboard(name: Constant.Storyboards.signIn)
        let nc = UINavigationController(rootViewController: signInVC)
        nc.modalPresentationStyle = .fullScreen
        self.present(nc, animated: true)
//        setRootViewController(nc)
    }
    
    /// Get bikes
    private func getBikes() {
        homeViewModel.getBikes { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let bikeResult):
                self.bikes = bikeResult.0
                if let state = (UserDefaults.standard.value(forKey: "BikeState") as? String), state == "bike" {
                    self.updateAllMarkers(type: bikeResult.1)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func updateAllMarkers(type: MarkerAction) {
        bikes.forEach { bike in
            switch type {
            case .add:
                self.addMarker(model: bike)
            case .update:
                self.updateMarker(model: bike)
            }
        }
    }
    
    private func updateMarker(model: BikeResult) {
        if model.updated {
            let marker = markers[model.id]
            
            marker?.map = nil
            
            marker?.position = CLLocationCoordinate2D(latitude: model.latitude, longitude: model.longitude)
            marker?.map = mapView
        }
    }
    
    private func addMarker(model: BikeResult) {
        let marker = MimoMarker()
        marker.position = CLLocationCoordinate2D(latitude: model.latitude, longitude: model.longitude)

//        let customMarker: CustomMarker = .fromNib()
//            customMarker.customInit(markerImage: #imageLiteral(resourceName: "ic_bike_marker"), batteryImage: UIImage(named: "ic_battery_H_25")!)
        marker.icon = #imageLiteral(resourceName: "ic_scooter_batarey_100")
        marker.map = mapView
        
        markers[model.id] = marker
        
        if model.id == self.bikes.first?.id {
            let location = CLLocation(latitude: model.latitude, longitude: model.longitude)
            self.centerMapOnLocation(location, mapView: mapView)
        }
    }
    
    func centerMapOnLocation(_ location: CLLocation, mapView: MimoMapView, zoom: Float = 10) {
        let camera = MimoCameraPosition.camera(withTarget: location.coordinate, zoom: zoom)
        mapView.animate(to: camera)
    }
    
    //MARK: - Actions
    
    @IBAction func infoTapped() {
        let onboardingView = OnboardingViewController.initFromStoryboard(name: "SignIn")
        navigationController?.pushViewController(onboardingView, animated: true)
    }
    

    @IBAction func bikeViewBackTapped(_ sender: UIButton) {
        openBottomSheet()
        bikesContentView.isHidden = true
        bikesContentView.alpha = 0
        collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: .centeredHorizontally, animated: true)
    }
    
    @IBAction func currentLocationTapped(_ sender: UIButton) {
        if locationManager.isAccessed, let location = locationManager.currentLocation {
            let camera = MimoCameraPosition.camera(withLatitude: (location.coordinate.latitude), longitude: location.coordinate.longitude, zoom: 17.0)
            mapView?.animate(to: camera)
        } else {
            locationManager.alertLocationAccess()
            locationManager.didChangeAuthStatus = {[weak self] state in
                if state {
                    self?.currentLocationTapped(UIButton())
                }
            }
        }
    }
}


//MARK: - collection view delegate and dataSource

extension MapViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.bikes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = MapBikeCollectionViewCell.reuseIdentifire(from: collectionView, indexPath: indexPath)
        cell.bikeResult = bikes[indexPath.item]
        cell.updateUI()
        
        if indexPath.item == 0 && !isAlreadyOpened {
            isAlreadyOpened = true
            cell.buttonContentView.backgroundColor = .mimoYellow500
        }
        
        if self.selectedIndex == indexPath {
            cell.buttonContentView.backgroundColor = .mimoYellow500
        }
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: Constant.Width.width288, height: Constant.Height.height184)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: Constant.Width.width15, bottom: 0, right: Constant.Width.width15)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        VibrateManager.vibrate()
        previewBike(result: self.bikes[indexPath.item])
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let visibleIndexPath = collectionView.getCurrentVisibleCellIndexPath()
        let cell = collectionView.cellForItem(at: visibleIndexPath) as!
            MapBikeCollectionViewCell
        guard let markerId = cell.bikeResult?.id,
              let marker = markers[markerId]
              else { return }
        
        self.makeSelectedMarker(previousMarker: self.currentMarker, currentMarker: marker, index: visibleIndexPath, cell: cell)
    }
    
    func makeSelectedMarker(previousMarker: MimoMarker?, currentMarker: MimoMarker, index: IndexPath, cell: MapBikeCollectionViewCell) {
        self.previousMarker = previousMarker
        self.currentMarker = currentMarker
        
        self.selectedIndex = index
        
        centerMapOnLocation(CLLocation(latitude: currentMarker.position.latitude, longitude: currentMarker.position.longitude), mapView: mapView, zoom: 15)
       
        for visibleCell in collectionView.visibleCells {
            let vCell = visibleCell as! MapBikeCollectionViewCell
            if vCell == cell {
                vCell.buttonContentView.backgroundColor = .mimoYellow500
            } else {
                vCell.buttonContentView.backgroundColor = .mimoBlackWith025alpha
            }
        }
    }
}


//MARK: -  join now sheet delegate

extension MapViewController: MapJoinNowSheetViewControllerDelegate {
    func didTappedButton(state: MapJoinNowSheetButtonsState) {
        bottomSheet?.attemptDismiss(animated: true)

        switch state {
        case .join:
            goToSignInVC()
        case .bike:
            currentLocationBottomConstraint.constant = Constant.Constraint.constant224
            bikesContentView.isHidden = false
            bikesContentView.alpha = 1
            
            collectionView.reloadData()
            
            guard let firstItem = bikes.first else { return }
            
            let cell = self.collectionView(collectionView, cellForItemAt: IndexPath(item: 0, section: 0))
            
            guard let currentMarker = self.markers[firstItem.id] else { return }
            
            self.makeSelectedMarker(previousMarker: nil, currentMarker: currentMarker, index: IndexPath(item: 0, section: 0), cell: cell as! MapBikeCollectionViewCell)
        }
    }
}


//MARK: -  prview one bike sheet delegate
extension MapViewController: SingleBikeSheetViewControllerDelegate {
    func didTappedJoinAndBook() {
        bottomSheet?.attemptDismiss(animated: true)
        goToSignInVC()
    }
}


//MARK: - collection view ceell join and book button tapped

extension MapViewController: MapBikeCollectionViewCellDelegate {
    func didJoinButtonTapped(cell: MapBikeCollectionViewCell) {
//        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        goToSignInVC()
    }
}


// MARK: - MimoMapViewDelegate -

extension MapViewController: MimoMapViewDelegate {
    
    func mapView(_ mapView: MimoMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        print("tappedcooordinate = \(coordinate)")
    }
    
    func mapView(_ mapView: MimoMapView, didTap marker: MimoMarker) -> Bool {
        if bikesContentView.isHidden {
            let cellIndex = bikes.firstIndex(where: { $0.latitude == marker.position.latitude && $0.longitude == marker.position.longitude }) ?? 0

            previewBike(result: self.bikes[cellIndex])
            
            centerMapOnLocation(CLLocation(latitude: marker.position.latitude, longitude: marker.position.longitude), mapView: mapView, zoom: 15)
        } else {
            let cellIndex = bikes.firstIndex(where: { $0.latitude == marker.position.latitude && $0.longitude == marker.position.longitude }) ?? 0
            let cellIndexPath = IndexPath(item: cellIndex, section: 0)
            
            
            
            self.collectionView.scrollToItem(at: cellIndexPath, at: .centeredHorizontally, animated: true)
            let cell = self.collectionView(collectionView, cellForItemAt: cellIndexPath) as! MapBikeCollectionViewCell
            
            
            self.makeSelectedMarker(previousMarker: self.currentMarker, currentMarker: marker, index: cellIndexPath, cell: cell)
        }
        
        return true
    }
}
