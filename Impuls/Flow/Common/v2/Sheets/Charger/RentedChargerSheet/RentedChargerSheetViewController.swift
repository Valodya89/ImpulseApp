//
//  RentedChargerSheetViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.11.23.
//
//  The active power-bank rents sheet: one card per rent. A single rent keeps
//  the full-width page; with two or more the cards become a peeking carousel
//  (centre card 84% wide, neighbours visible at the sides and scaled to 0.95,
//  one card per swipe) with the page control under it. The centred index is
//  reported to the delegate exactly as before, so the map's chip row for the
//  rents keeps following, and `scrollToCharger(with:)` still brings a chip's
//  rent to the centre.
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

    private let carouselLayout = RentedChargerCarouselFlowLayout()

    var viewModel: RentedChargerViewModel?
    weak var delegate: RentedChargerSheetViewControllerDelegate?

    private var rentedChargersCount: Int {
        return viewModel?.rentedChargers.value?.count ?? 0
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .appSecondaryBackground
        collectionView.backgroundColor = .clear
        collectionView.register(RentedChargerCollectionViewCell.self)
        collectionView.collectionViewLayout = carouselLayout
        collectionView.clipsToBounds = false
        collectionView.showsHorizontalScrollIndicator = false

        pageControl.currentPageIndicatorTintColor = UIColor(named: "BrandYellow") ?? .mimoYellow500
        pageControl.pageIndicatorTintColor = .appSeparator
        pageControl.isUserInteractionEnabled = false

        setupViewModel()
    }

    /// Programmatic: the map asked for a rent. Must not echo back through the
    /// delegate, so it goes through `scrollToItem`, which never produces
    /// `scrollViewDidEndDecelerating`.
    public func scrollToCharger(with index: Int) {
        guard index >= 0, index < rentedChargersCount else { return }

        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
        pageControl.currentPage = index
    }

    private func setupViewModel() {
        viewModel?.rentedChargers.sink(receiveValue: { [weak self] rentedChargers in
            guard let self, let rentedChargers else { return }

            self.updateUI()
        })
        .store(in: &cancellables)
    }

    private func updateUI() {
        let count = rentedChargersCount

        carouselLayout.isPeeking = count > 1
        collectionView.isPagingEnabled = count <= 1
        collectionView.decelerationRate = count > 1 ? .fast : .normal
        carouselLayout.invalidateLayout()
        collectionView.reloadSections(IndexSet(integer: 0))

        pageControl.numberOfPages = count
        pageControl.isHidden = count <= 1
        pageControl.currentPage = min(pageControl.currentPage, max(count - 1, 0))
    }

    /// The index of the card sitting at the centre of the collection view.
    private func centredIndex(of scrollView: UIScrollView) -> Int {
        let step = carouselLayout.pageStep
        guard step > 0, rentedChargersCount > 0 else { return 0 }

        let page = Int((scrollView.contentOffset.x / step).rounded())
        return min(max(page, 0), rentedChargersCount - 1)
    }

    private func reportCentredCard(of scrollView: UIScrollView) {
        let page = centredIndex(of: scrollView)

        pageControl.currentPage = page
        delegate?.didSelectCharger(with: page)
        collectionView.reloadData()
    }
}

extension RentedChargerSheetViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rentedChargersCount
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: RentedChargerCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)

        if let rentedCharger = viewModel?.rentedChargers.value?[indexPath.item] {
            cell.set(rentedCharger: rentedCharger, currency: viewModel?.currency ?? "₽‎")
        }

        return cell
    }
}

extension RentedChargerSheetViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return carouselLayout.cardSize
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return carouselLayout.cardInsets
    }
}

extension RentedChargerSheetViewController: UIScrollViewDelegate {

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        carouselLayout.dragStartOffsetX = scrollView.contentOffset.x
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }

        reportCentredCard(of: scrollView)
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        reportCentredCard(of: scrollView)
    }
}

// MARK: - Peeking carousel layout

/// A horizontal flow layout whose cards are `widthFraction` of the collection
/// view when `isPeeking`, centred by the section insets so the neighbours show
/// at both sides, scaled down towards `neighbourScale` as they leave the
/// centre, and snapped one card per swipe. With `isPeeking` off it is a plain
/// full-width paging layout.
private final class RentedChargerCarouselFlowLayout: UICollectionViewFlowLayout {

    var isPeeking = false
    var widthFraction: CGFloat = 0.84
    var neighbourScale: CGFloat = 0.95
    /// Set by the controller when a drag starts: a swipe moves exactly one card
    /// away from the card that was centred then, however far the finger went.
    var dragStartOffsetX: CGFloat = 0

    override init() {
        super.init()

        scrollDirection = .horizontal
        minimumLineSpacing = 0
        minimumInteritemSpacing = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var cardSize: CGSize {
        guard let collectionView else { return .zero }

        let width = collectionView.bounds.width
        let cardWidth = isPeeking ? floor(width * widthFraction) : width
        return CGSize(width: max(cardWidth, 0), height: collectionView.bounds.height)
    }

    var cardInsets: UIEdgeInsets {
        guard let collectionView, isPeeking else { return .zero }

        let inset = max((collectionView.bounds.width - cardSize.width) / 2, 0)
        return UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
    }

    /// Content offset distance between two consecutive centred cards.
    var pageStep: CGFloat {
        return cardSize.width + minimumLineSpacing
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let superAttributes = super.layoutAttributesForElements(in: rect) else { return nil }

        let attributes = superAttributes.compactMap { $0.copy() as? UICollectionViewLayoutAttributes }
        attributes.forEach(applyPeekTransform)
        return attributes
    }

    override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let attributes = super.layoutAttributesForItem(at: indexPath)?.copy() as? UICollectionViewLayoutAttributes else { return nil }

        applyPeekTransform(attributes)
        return attributes
    }

    private func applyPeekTransform(_ attributes: UICollectionViewLayoutAttributes) {
        guard isPeeking, attributes.representedElementCategory == .cell, let collectionView else {
            attributes.transform = .identity
            return
        }

        let centre = collectionView.contentOffset.x + collectionView.bounds.width / 2
        let distance = abs(attributes.center.x - centre)
        let ratio = min(distance / max(pageStep, 1), 1)
        let scale = 1 - (1 - neighbourScale) * ratio

        attributes.transform = CGAffineTransform(scaleX: scale, y: scale)
        attributes.zIndex = Int((1 - ratio) * 10)
    }

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard isPeeking, let collectionView, pageStep > 0 else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }

        let count = collectionView.numberOfItems(inSection: 0)
        guard count > 0 else { return proposedContentOffset }

        let startPage = Int((dragStartOffsetX / pageStep).rounded())
        var targetPage: Int

        if velocity.x > 0.2 {
            targetPage = startPage + 1
        } else if velocity.x < -0.2 {
            targetPage = startPage - 1
        } else {
            targetPage = Int((proposedContentOffset.x / pageStep).rounded())
            targetPage = min(max(targetPage, startPage - 1), startPage + 1)
        }

        targetPage = min(max(targetPage, 0), count - 1)

        return CGPoint(x: CGFloat(targetPage) * pageStep, y: proposedContentOffset.y)
    }
}
