//
//  RentedChargerSheetViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.11.23.
//

import UIKit
import Combine

protocol RentedChargerSheetViewControllerDelegate: AnyObject {
    func didSelectCharger(with index: Int)
}

class RentedChargerSheetViewController: MimoBaseViewController {
    
    private var cancellables: Set<AnyCancellable> = .init()
    
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var pageControl: UIPageControl!
    
    var viewModel: RentedChargerViewModel?
    weak var delegate: RentedChargerSheetViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(RentedChargerCollectionViewCell.self)

        setupViewModel()
    }
    
    public func scrollToCharger(with index: Int) {
        collectionView.isPagingEnabled = false
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
        collectionView.isPagingEnabled = true
        pageControl.currentPage = index
        collectionView.reloadData()
    }

    private func setupViewModel() {
        viewModel?.rentedChargers.sink(receiveValue: { [weak self] rentedChargers in
            guard let self, let rentedChargers else { return }
            
            self.updateUI()
        })
        .store(in: &cancellables)
    }
    
    private func updateUI() {
        collectionView.reloadSections(IndexSet(integer: 0))
        
        pageControl.numberOfPages = viewModel?.rentedChargers.value?.count ?? 0
        pageControl.isHidden = (viewModel?.rentedChargers.value?.count ?? 0) <= 1
    }
}

extension RentedChargerSheetViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.rentedChargers.value?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: RentedChargerCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        
        if let rentedCharger = viewModel?.rentedChargers.value?[indexPath.item] {
            cell.set(rentedCharger: rentedCharger)
        }
        
        return cell
    }
}

extension RentedChargerSheetViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
    }
}

extension RentedChargerSheetViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
        let page = Int(floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1)
        
        pageControl.currentPage = page
        delegate?.didSelectCharger(with: page)
        collectionView.reloadData()
    }
}
