//
//  MimoHomeViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 02.05.23.
//
//  Home screen: balance bar, stories, active sessions, the row of service hero
//  cards, the nearest-vehicles sheet and the scan button.
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
    
    // The storyboard's "I want" tile row. It is replaced by the hero cards and
    // stays hidden, but its outlets and actions must keep resolving.
    @IBOutlet private weak var servicesStackView: UIStackView!
    @IBOutlet private var servicesLoadingViews: [UIView]!
    @IBOutlet private var servicesViews: [UIView]!
    @IBOutlet private var productCloseButtons: [UIButton]!
    
    @IBOutlet private weak var storiesCollectionViewTopConstraint: NSLayoutConstraint!
    
    /// The services are full-width hero cards in a snapping carousel hosted in
    /// the storyboard's services container, one card per product plus an
    /// "add product" card while there is more to choose.
    private var servicesCarousel: HomeServicesCarouselViewModel?
    private var servicesCollectionView: UICollectionView?
    
    /// Pull-to-refresh on a screen without a scroll view: a pan on the hub
    /// drives the branded indicator and re-reads everything.
    private var pullToRefresh: MimoPullToRefreshGesture?
    
    /// Rents whose end-of-rent summary has already been presented from here.
    /// The socket can deliver RENT_ENDED more than once (a resubscribe after a
    /// reconnect), and every copy used to present another summary on top.
    private var shownSummaryRentIds = Set<String>()
    
    /// A station link waiting for the location permission answer (see
    /// `openPendingStationLink`); a newer link replaces it.
    private var stationLinkWait: AnyCancellable?
    
    private enum Hero {
        static let height: CGFloat = 196
        static let topInset: CGFloat = 8
        static let bottomInset: CGFloat = 16
        /// Side margin of a lone card.
        static let sideInset: CGFloat = 16
        /// Side margin when several cards share the row, so the next one peeks in.
        static let peekInset: CGFloat = 28
        static let spacing: CGFloat = 10
        /// The nearest-vehicles sheet height is tuned with fixed constants that
        /// assumed the 147pt tile row (10 + 117 + 20); the cards are this much taller.
        static let extraHeight: CGFloat = height + topInset + bottomInset - 147
    }
    
    var height: CGFloat {
        let bottomSafeArea = UIApplication.shared.keyWindowInConnectedScenes?.safeAreaBottom ?? 0
        let reserved: CGFloat = (viewModel!.activeTrips.isEmpty ? 400 : 508) + Hero.extraHeight
        return UIScreen.main.bounds.height - reserved - bottomSafeArea
    }
    
    var viewModel: MimoHomeViewModel?
    var storyViewModel: StoryViewModel = StoryViewModel(worker: Resolver.resolve())

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupViewModel()
        setupPullToRefresh()
        observeStationLinks()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // A station sticker link that cold-started the app has waited through
        // the splash for this moment.
        openPendingStationLink()
    }
    
    /// Drag down anywhere on the home content to refresh: the stories strip,
    /// the sessions carousel and the service cards slide with the finger; the
    /// nearest-vehicles sheet keeps its own drag.
    private func setupPullToRefresh() {
        let contentViews = [storiesContainerView, activeTripsCollectionView, servicesStackView.superview].compactMap { $0 }
        let refresh = MimoPullToRefreshGesture(hostView: view, contentViews: contentViews)
        refresh.onRefresh = { [weak self] completion in
            guard let self, let viewModel = self.viewModel else { return completion(false) }

            // Balance is the one fetch every rider notices; the indicator waits
            // for it (or an error) and the rest refreshes alongside.
            var delivered = false
            let loaded = viewModel.$walletInfo.dropFirst().map { _ in true }
            let failed = viewModel.$errorMessage.dropFirst().compactMap { $0 }.map { _ in false }
            loaded.merge(with: failed)
                .first()
                .timeout(.seconds(10), scheduler: DispatchQueue.main)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { result in
                    if case .finished = result, !delivered { completion(false) }
                }, receiveValue: { success in
                    delivered = true
                    completion(success)
                })
                .store(in: &self.cancellables)

            viewModel.loadBalance()
            viewModel.getActiveTrips()
            viewModel.getAvailableServices()
            self.loadStories()
        }
        pullToRefresh = refresh
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Whatever route got us here (login, email verification, splash), the home
        // screen has no text input - a keyboard left over from the previous screen
        // would just sit on top of the map.
        UIApplication.shared.dismissKeyboard()
        
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
        
        // The tile row (skeletons, tiles, edit-mode close buttons) never shows:
        // the hero cards replace it from the first paint.
        servicesLoadingViews.forEach { $0.isHidden = true }
        servicesViews.forEach { $0.isHidden = true }
        productCloseButtons.forEach { $0.isHidden = true }
        servicesStackView.isHidden = true
        
        embedServicesCarousel()
    }
    
    private func embedServicesCarousel() {
        guard let viewModel, servicesCollectionView == nil,
              let container = servicesStackView.superview else { return }
        
        let carousel = HomeServicesCarouselViewModel(homeViewModel: viewModel)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeServicesLayout(itemWidth: 1))
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        // The cards' shadows and the peeking neighbours draw past the cell.
        collectionView.clipsToBounds = false
        collectionView.register(HomeServiceCarouselCell.self, forCellWithReuseIdentifier: HomeServiceCarouselCell.reuseIdentifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: container.topAnchor, constant: Hero.topInset),
            collectionView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: Hero.bottomInset),
            collectionView.heightAnchor.constraint(equalToConstant: Hero.height)
        ])
        
        servicesCarousel = carousel
        servicesCollectionView = collectionView
        
        carousel.items
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateServicesLayoutIfNeeded()
                self?.servicesCollectionView?.reloadData()
            }
            .store(in: &cancellables)
    }
    
    private func makeServicesLayout(itemWidth: CGFloat) -> UPCarouselFlowLayout {
        let layout = UPCarouselFlowLayout()
        layout.scrollDirection = .horizontal
        layout.sideItemScale = 1
        layout.sideItemAlpha = 1
        layout.spacingMode = .fixed(spacing: Hero.spacing)
        layout.itemSize = CGSize(width: max(itemWidth, 1), height: Hero.height)
        return layout
    }
    
    /// A lone card takes the row; several share it with the next one peeking in.
    /// The carousel layout only recomputes its insets on a bounds change, so a
    /// new item width means a fresh layout.
    private func updateServicesLayoutIfNeeded() {
        guard let collectionView = servicesCollectionView,
              let layout = collectionView.collectionViewLayout as? UPCarouselFlowLayout,
              collectionView.bounds.width > 0 else { return }
        
        let itemCount = servicesCarousel?.items.value.count ?? 0
        let inset = itemCount > 1 ? Hero.peekInset : Hero.sideInset
        let itemWidth = max(collectionView.bounds.width - 2 * inset, 1)
        guard layout.itemSize.width != itemWidth else { return }
        
        collectionView.setCollectionViewLayout(makeServicesLayout(itemWidth: itemWidth), animated: false)
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
            // The hosting view defaults to systemBackground (black in dark mode);
            // the strip must sit directly on the home screen.
            hostingController.view.backgroundColor = .clear
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
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] charger in
                guard let self, let charger else { return }
                
                if charger.state == .rentEnded {
                    self.presentRentSummaryIfNeeded(charger)
                }
            })
            .store(in: &cancellables)
        
        // Putting the bank back happens with the phone in a pocket. Coming back
        // to the foreground on this tab fires no appearance callback, so the
        // socket is reconnected and the strip re-read here - a RENT_ENDED sent
        // while the socket was down would otherwise wait for the next visit.
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.viewIfLoaded?.window != nil else { return }
                self.viewModel?.resumeFromBackground()
            }
            .store(in: &cancellables)
        
        MILoader.show()
        self.viewModel?.checkForceUpdate()
        
        HomeRouter.shared.fastDecisionSheetAnimateIn(to: view, in: self, height: height, viewModel: viewModel, delegate: self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        (activeTripsCollectionView.collectionViewLayout as? UPCarouselFlowLayout)?.itemSize = CGSize(width: Constant.Width.width085, height: activeTripsCollectionView.frame.height)
        updateServicesLayoutIfNeeded()
        
        HomeRouter.shared.fastDecisionSheetAnimate(to: height)
        view.sendSubviewToBack(activeTripsCollectionView)
        view.sendSubviewToBack(storiesContainerView)
        view.bringSubviewToFront(scanButton)
    }
    
    private func loadStories() {
        guard ApplicationSettings.shared.isoCountryCode != nil else { return }
        
        storyViewModel.getStories()
    }
    
    // MARK: - Rent summary
    
    /// One summary per finished rent, presented over whatever is on screen as
    /// long as home is the top of its stack (the power-bank map presents its
    /// own when it is up, so this must not double it).
    private func presentRentSummaryIfNeeded(_ charger: RentedCharger) {
        guard let id = charger.data?.id, !shownSummaryRentIds.contains(id) else { return }
        guard navigationController?.topViewController === self else {
            MimoSocketLog.info(.charger, "summary left to the top screen", "rent=\(id)")
            return
        }
        
        var presenter: UIViewController = tabBarController ?? self
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        
        shownSummaryRentIds.insert(id)
        MimoSocketLog.info(.charger, "summary shown on home", "rent=\(id)")
        ChargerRouter.shared.showChargerSuccessViewController(presenter, currency: viewModel?.walletInfo?.currency, rentedCharger: charger)
    }
    
    // MARK: - Services
    
    private func openProduct(_ product: MimoProductType) {
        if !(viewModel?.isLocationAuthorized ?? false) {
            UIAlertController.showLocationDeniedAlert()
            return
        }
        
        switch product {
        case .scooter:
            ScooterRouter.shared.showScooterViewController(navigationController, leasedScooters: viewModel?.leasedScooters)
        case .bike:
            BikeRouter.shared.showBikeViewController(navigationController)
        case .charger:
            ChargerRouter.shared.showChargerViewController(navigationController)
        case .evCharger:
            EVChargerRouter.shared.showEvChargerViewController(navigationController, scanedStation: (nil,nil), isFromFastDecision: false)
        }
    }
    
    private func openProductSelection() {
        if !(viewModel?.isLocationAuthorized ?? false) {
            UIAlertController.showLocationDeniedAlert()
            return
        }
        
        HomeRouter.shared.showProductsSelectionScreen(navigationController)
    }
    
    private func removeProduct(_ product: MimoProductType) {
        viewModel?.removeProduct(at: product.rawValue)
    }
    
    /// Storyboard action of the hidden tile row; kept so the connections resolve.
    @IBAction private func mimoTypeAction(_ sender: UIButton) {
        if sender.tag == 4 {
            openProductSelection()
            return
        }
        
        guard let product = MimoProductType(rawValue: sender.tag) else { return }
        openProduct(product)
    }
    
    /// Storyboard action of the hidden tile row; kept so the connections resolve.
    @IBAction private func productCloseButtonTapped(_ sender: UIButton) {
        guard let product = MimoProductType(rawValue: sender.tag) else { return }
        removeProduct(product)
    }
    
    @IBAction private func scanAction() {
        ScanRouter.shared.showQrScanViewController(self, delegate: self)
    }
    
    // MARK: - Station App Link
    
    /// A link opened while the app is already running (Home exists, possibly
    /// under another screen or tab) is delivered at once.
    private func observeStationLinks() {
        NotificationCenter.default.publisher(for: Constant.Notifications.stationScanLink)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.openPendingStationLink()
            }
            .store(in: &cancellables)
    }
    
    /// Takes the parked station code (once) and opens the power-bank map on
    /// that station exactly as a code from the in-app scanner does: the same
    /// location check and the same charger screen; no rent is started.
    private func openPendingStationLink() {
        guard let code = HomeRouter.shared.takePendingStationCode() else { return }
        
        // Whatever is above Home (the scanner, a sheet, another product's map,
        // the profile tab) gives way, so the station screen never stacks.
        let presenter = tabBarController ?? navigationController ?? self
        presenter.presentedViewController?.dismiss(animated: false)
        presentedViewController?.dismiss(animated: false)
        tabBarController?.selectedIndex = 0
        navigationController?.popToRootViewController(animated: false)
        
        guard viewModel?.isLocationAuthorized != true else {
            didFinishScan(with: code, type: .charger)
            return
        }
        
        // On a cold start Home can appear before CoreLocation's first
        // authorization callback, or while the permission prompt is still up.
        // Wait for the grant, bounded; after that the scan runs anyway and
        // shows the same location alert a camera scan would.
        let granted = viewModel?.$isLocationAuthorized.filter { $0 }.map { _ in () }.eraseToAnyPublisher()
            ?? Empty<Void, Never>().eraseToAnyPublisher()
        let gaveUp = Just(()).delay(for: .seconds(5), scheduler: DispatchQueue.main).eraseToAnyPublisher()
        stationLinkWait = granted.merge(with: gaveUp)
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.stationLinkWait = nil
                self?.didFinishScan(with: code, type: .charger)
            }
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
        if collectionView === servicesCollectionView {
            return servicesCarousel?.items.value.count ?? 0
        }
        
        return viewModel?.activeTrips.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView === servicesCollectionView {
            return serviceCell(collectionView, cellForItemAt: indexPath)
        }
        
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
    
    private func serviceCell(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: HomeServiceCarouselCell.reuseIdentifier, for: indexPath) as? HomeServiceCarouselCell,
              let carousel = servicesCarousel,
              indexPath.item < carousel.items.value.count else { return UICollectionViewCell() }
        
        switch carousel.items.value[indexPath.item] {
        case .loading:
            cell.set(HomeServiceLoadingCardView())
        case .service(let product):
            let onRemove: (() -> Void)? = carousel.canRemoveProducts
                ? { [weak self] in self?.removeProduct(product) }
                : nil
            cell.set(HomeServiceHeroView(viewModel: carousel.card(for: product),
                                         onOpen: { [weak self] in self?.openProduct(product) },
                                         onRemove: onRemove))
        case .addProduct:
            cell.set(HomeAddProductCardView { [weak self] in self?.openProductSelection() })
        }
        
        return cell
    }
}

extension MimoHomeViewController: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView === servicesCollectionView {
            return (collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize ?? CGSize(width: collectionView.bounds.width, height: Hero.height)
        }
        
        return CGSize(width: Constant.Width.width085, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // The service cards handle their own taps (SwiftUI buttons).
        guard collectionView === activeTripsCollectionView else { return }
        
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
            EVChargerRouter.shared.showEvChargerViewController(navigationController, selectedId: selectedStation.station.id, scanedStation: (nil,nil), isFromFastDecision: false)
        }
    }
}
