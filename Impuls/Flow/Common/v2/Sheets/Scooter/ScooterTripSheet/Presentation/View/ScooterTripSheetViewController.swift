//
//  ScooterTripSheetViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 02.06.23.
//

import UIKit
import Combine
import CoreLocation

protocol ScooterTripSheetViewControllerDelegate: AnyObject {
    func didSelectScooter(with index: Int)
}

class ScooterTripSheetViewController: UIViewController {
    
    private var cancellables = Set<AnyCancellable>()
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var pageControl: UIPageControl!
    
    var viewModel: ScooterTripViewModel?
    weak var delegate: ScooterTripSheetViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViewModel()
        
        collectionView.register(ScooterTripCollectionViewCell.self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel?.pausedScooter.sink(receiveValue: { [weak self] scooter in
            self?.collectionView.reloadData()
            if let scooter {
                let pauseSum = (scooter.data?.pauses?.sum ?? 0) / 1000

                var lastPause: Double = 0
                if let _lastPause = scooter.data?.pauses?.first(where: { $0.end == nil })?.start {
                    lastPause = Double(_lastPause/1000)
                }

                ScooterPlanRouter.shared.showPauseViewController(self, lastPause: lastPause, pauseSum: Double(pauseSum), delegate: self)
            } else {
                ScooterPlanRouter.shared.pauseViewController?.dismiss(animated: true)
                ScooterPlanRouter.shared.pauseViewController = nil
            }
            
            MILoader.hide()
        })
        .store(in: &cancellables)
        
        viewModel?.continueScooter.sink(receiveValue: { [weak self] scooter in
            if let scooter {
                ScooterPlanRouter.shared.pauseViewController?.dismiss(animated: true)
                ScooterPlanRouter.shared.pauseViewController = nil
            }
            
            self?.collectionView.reloadData()
        })
        .store(in: &cancellables)
    }
    
    public func scrollToScooter(with index: Int) {
        collectionView.isPagingEnabled = false
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
        collectionView.isPagingEnabled = true
        pageControl.currentPage = index
        collectionView.reloadData()
    }
    
    private func setupViewModel() {
        viewModel?.getScooterDetails()
        
        viewModel?.$scooterDetails.sink(receiveValue: { [weak self] _ in
            self?.updateUI()
        })
        .store(in: &cancellables)
        
        viewModel?.$trips.sink(receiveValue: { [weak self] trips in
            self?.checkPause(trips: trips)
            self?.updateUI()
        })
        .store(in: &cancellables)
        
        viewModel?.$speedTarifChanged.sink(receiveValue: { [weak self] _ in
            MILoader.hide()
            self?.collectionView.reloadData()
        })
        .store(in: &cancellables)
        
        viewModel?.$errorMessage.sink { [weak self] errorMessage in
            guard let errorMessage else { return }
//            self?.showAlertMessage(errorMessage.localized(), actionText: "MOBILE_global_ok".localized(), action: { })
            self?.showErrorPopUp(message: errorMessage, service: .scooter)
            MILoader.hide()
        }
        .store(in: &cancellables)
    }
    
    private func updateUI() {
        UIView.performWithoutAnimation {
            self.collectionView.reloadData()
        }
        
        pageControl.numberOfPages = viewModel?.trips.count ?? 0
        pageControl.isHidden = (viewModel?.trips.count ?? 0) <= 1
    }
    
    private func checkPause(trips: [ScooterStateModel]) {
        let pausedTrips = trips.filter({ $0.state == .TripPaused })
        
        if !pausedTrips.isEmpty {
            viewModel?.pausedScooter.send(pausedTrips.first)
        }
    }
}

extension ScooterTripSheetViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.trips.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ScooterTripCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        let scooter = viewModel?.trips[indexPath.row]
        let tariffs = viewModel?.scooterDetails.first(where: { $0.scooter?.qr == scooter?.scooter?.qr })?.speedTariffs
        cell.set(data: scooter, pauseData: viewModel?.pausedScooter.value, continueData: viewModel?.continueScooter.value, tariffs: tariffs)
        
        cell.delegate = self
        
        return cell
    }
}

extension ScooterTripSheetViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
}

extension ScooterTripSheetViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
        let page = Int(floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1)
        
        pageControl.currentPage = page
        delegate?.didSelectScooter(with: page)
        collectionView.reloadData()
    }
}

extension ScooterTripSheetViewController: ScooterTripCollectionViewCellDelegate {
    func didSelectPause(for cell: ScooterTripCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell),
              let id = viewModel?.trips[indexPath.row].data?.id else { return }
        
        viewModel?.pauseScooter(with: id)
    }
    
    func didSelectEndRide(for cell: ScooterTripCollectionViewCell) {
        guard let viewModel else { return }
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let trip = viewModel.trips[indexPath.row]
        guard let id = trip.data?.id else { return }
        
        MILoader.show()
        viewModel.finishCheck(id: id)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.viewModel?.mimoError = error
                    MILoader.hide()
                default: break
                }
            } receiveValue: { [weak self] _ in
                guard let self else { return }
                MILoader.hide()
                CameraRouter.shared.showParkingPhotoCameraViewController(self, trip: trip)
            }
            .store(in: &cancellables)
    }
    
    func didChangeSpeedTarif(for cell: ScooterTripCollectionViewCell, tariffTag: Int) {
        guard let indexPath = collectionView.indexPath(for: cell),
              let id = viewModel?.trips[indexPath.row].data?.id,
        let scooterQR = viewModel?.trips[indexPath.row].scooter?.qr else { return }
        let tariffs = viewModel?.scooterDetails.first(where: { $0.scooter?.qr == scooterQR })?.speedTariffs
        let newTariff = tariffs?[tariffTag]
        
        if let newTariff, let mode = viewModel?.trips[indexPath.row].data?.billingModeTariff?.mode {
            VibrateManager.vibrate()
            ScooterRouter.shared.showSpeedTariffChangeViewController(self, speedTariff: newTariff, mode: ScooterPlanMode(rawValue: mode), tripId: id, delegate: self)
        }
    }
    
    func openInMaps(for cell: ScooterTripCollectionViewCell) {
        guard let indexPath = collectionView.indexPath(for: cell), let scooter = viewModel?.trips[indexPath.row].scooter,
              let latitude = scooter.located?.latitude, let longitude = scooter.located?.longitude else { return }
        
        OpenMapDirections.present(in: self, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
    }
}

extension ScooterTripSheetViewController: MimoPauseViewControllerDelegate {
    func continuePausedTrip() {
        guard let id = viewModel?.pausedScooter.value?.data?.id else { return }
        MILoader.show()
        viewModel?.continueScooter(with: id)
    }
}

extension ScooterTripSheetViewController: SpeedTariffChangeViewControllerDelegate {
    
    func didChangeSpeedTariff(tripId: String?, speedId: String?) {
        guard let tripId, let speedId else { return }
        
        MILoader.show()
        viewModel?.changeSpeedTarif(tripId: tripId, speedId: speedId)
    }
}
