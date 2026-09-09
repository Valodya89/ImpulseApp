//
//  ChargingStationSheetViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.11.23.
//

import UIKit
import CoreLocation

protocol ChargingStationSheetViewControllerDelegate: AnyObject {
    func didSelectTariffs()
    func didSelectScan()
}

class ChargingStationSheetViewController: MimoBaseViewController {
    
    @IBOutlet private weak var freeMinutesLabel: UILabel!
    @IBOutlet private weak var balanceLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var workingHoursLabel: UILabel!
    @IBOutlet private weak var photosCollectionView: UICollectionView!
    @IBOutlet private weak var availableSlotsLabel: UILabel!
    @IBOutlet private weak var slotsToReturnLabel: UILabel!
    @IBOutlet private weak var logoImageView: UIImageView!
    @IBOutlet private weak var photosCountLabel: UILabel!
    @IBOutlet private weak var instagramButton: UIButton!
    @IBOutlet private weak var facebookButton: UIButton!
    @IBOutlet private weak var linkedinButton: UIButton!
    @IBOutlet private weak var websiteButton: UIButton!
    
    var viewModel: ChargingStationDetailsViewModel?
    weak var delegate: ChargingStationSheetViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupData()
        setupBalance()
    }
    
    private func setupUI() {
        photosCollectionView.contentInset.left = 16
        photosCollectionView.contentInset.right = 16
        photosCollectionView.register(ImageCollectionViewCell.self)
        
        logoImageView.isUserInteractionEnabled = true
        logoImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(logoAction)))
    }
    
    private func setupData() {
        titleLabel.text = viewModel?.chargingStation?.destinationName
        addressLabel.text = viewModel?.chargingStation?.destinationAddress
        
        let slotsCount = viewModel?.chargingStation?.slotsCount ?? 0
        let availableSlotsCount = viewModel?.chargingStation?.powerBanksCount ?? 0
        availableSlotsLabel.text = "\(availableSlotsCount) \("MOBILE_charger_slotsAvailable".localized())"
        slotsToReturnLabel.text = "\(slotsCount - availableSlotsCount) \("MOBILE_charger_slotsToReturn".localized())"
        logoImageView.sd_setImage(with: viewModel?.chargingStation?.logo?.imageURL)
        
        photosCountLabel.text = "\(viewModel?.chargingStation?.images?.count ?? 0)"
        workingHoursLabel.text = viewModel?.chargingStation?.workingHours
        
        instagramButton.isHidden = viewModel?.chargingStation?.instagramUrl?.isEmpty ?? true
        facebookButton.isHidden = viewModel?.chargingStation?.facebookUrl?.isEmpty ?? true
        linkedinButton.alpha = (viewModel?.chargingStation?.linkedinUrl?.isEmpty ?? true) ? 0 : 1
        websiteButton.alpha = (viewModel?.chargingStation?.websiteUrl?.isEmpty ?? true) ? 0 : 1
    }
    
    private func setupBalance() {
        guard let walletInfo = viewModel?.walletInfo, let financialState = viewModel?.financialState else { return }
        
        if walletInfo.balance - (financialState.additional ?? 0) < 0 {
            balanceLabel.textColor = .red
        } else {
            balanceLabel.textColor = .mimoBlackWith075alpha
        }
        
        let balance = (walletInfo.balance - (financialState.additional ?? 0)).rounded()
        balanceLabel.text = String(format: "%.2f", balance)
        
        freeMinutesLabel.text = String(format: "%.2f", viewModel?.user?.minutes ?? 0)
    }
}

private extension ChargingStationSheetViewController {
    
    @IBAction private func socialNetworkAction(_ sender: UIButton) {
        let application = UIApplication.shared
        
        switch SocialNetworkType(rawValue: sender.tag) {
        case .instagram:
            guard let instagram = viewModel?.chargingStation?.instagramUrl else { return }
            let appURL = URL(string: "instagram://user?username=\(instagram)")!
            if application.canOpenURL(appURL) {
                application.open(appURL)
            } else {
                // if Instagram app is not installed, open URL inside Safari
                let webURL = URL(string: "https://instagram.com/\(instagram)")!
                application.open(webURL)
            }
        case .facebook:
            guard let facebook = viewModel?.chargingStation?.facebookUrl else { return }
            let appURL = URL(string: "fb://profile/\(facebook)")!
            if application.canOpenURL(appURL) {
                application.open(appURL)
            }
        case .linkedin:
            guard let linkedin = viewModel?.chargingStation?.linkedinUrl, let appURL = URL(string: "linkedin://\(linkedin)") else { return }
            if application.canOpenURL(appURL) {
                application.open(appURL)
            }
        case .web:
            guard let web = viewModel?.chargingStation?.websiteUrl, let webURL = URL(string: web) else { return }
            application.open(webURL)
        default:
            break
        }
    }

    @IBAction private func directionAction() {
        guard let latitude = viewModel?.chargingStation?.location?.latitude,
              let longitude = viewModel?.chargingStation?.location?.longitude else { return }
        
        OpenMapDirections.present(in: self, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))
    }
    
    @IBAction private func scanAction() {
        delegate?.didSelectScan()
    }
    
    @IBAction private func tariffsAction() {
        delegate?.didSelectTariffs()
    }
    
    @objc func logoAction() {
        guard let logo = viewModel?.chargingStation?.logo else { return }
        
        VibrateManager.vibrate()
        present(ImagePreviewViewController(image: logo), animated: true)
    }
    
    @IBAction private func replenishAction() {
        VibrateManager.vibrate()
        
        openWallet()
    }
}

extension ChargingStationSheetViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.chargingStation?.images?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: ImageCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
        cell.set(imageURL: viewModel?.chargingStation?.images?[indexPath.row].imageURL)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let images = viewModel?.chargingStation?.images,
              images.indices.contains(indexPath.row) else { return }
        
        VibrateManager.vibrate()
        present(ImagePreviewViewController(images: images, startIndex: indexPath.row), animated: true)
    }
}

/// Full screen photo preview: swipe between the station's photos, pinch or
/// double tap to zoom. Kept in this file so the sheet gains the preview without
/// an Xcode project change; move it to `Flow/Common/v2/View` when another screen
/// needs it.
final class ImagePreviewViewController: UIViewController {
    
    private let images: [ImageObj]
    private var currentIndex: Int
    private var hasScrolledToStartIndex = false
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = .zero
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.contentInsetAdjustmentBehavior = .never
        
        return collectionView
    }()
    
    private let counterLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    
    init(images: [ImageObj], startIndex: Int = 0) {
        self.images = images
        self.currentIndex = min(max(startIndex, 0), max(images.count - 1, 0))
        
        super.init(nibName: nil, bundle: nil)
        
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    convenience init(image: ImageObj?) {
        self.init(images: [image].compactMap({ $0 }))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        
        setupCollectionView()
        setupCloseButton()
        setupCounterLabel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        guard collectionView.bounds.size != .zero,
              let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        
        if layout.itemSize != collectionView.bounds.size {
            layout.itemSize = collectionView.bounds.size
            layout.invalidateLayout()
        }
        
        // Opening on the tapped photo, once the page width is known.
        guard !hasScrolledToStartIndex else { return }
        hasScrolledToStartIndex = true
        collectionView.layoutIfNeeded()
        collectionView.setContentOffset(CGPoint(x: CGFloat(currentIndex) * collectionView.bounds.width, y: 0),
                                        animated: false)
    }
    
    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(ZoomableImageCell.self, forCellWithReuseIdentifier: ZoomableImageCell.identifier)
        view.addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupCloseButton() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        closeButton.layer.cornerRadius = 18
        closeButton.addTarget(self, action: #selector(closePreview), for: .touchUpInside)
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    private func setupCounterLabel() {
        counterLabel.translatesAutoresizingMaskIntoConstraints = false
        counterLabel.textColor = .white
        counterLabel.textAlignment = .center
        counterLabel.font = UIFont(name: "Roboto-Regular", size: 15) ?? .systemFont(ofSize: 15)
        counterLabel.isHidden = images.count < 2
        view.addSubview(counterLabel)
        
        NSLayoutConstraint.activate([
            counterLabel.centerYAnchor.constraint(equalTo: closeButton.centerYAnchor),
            counterLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        updateCounterLabel()
    }
    
    private func updateCounterLabel() {
        counterLabel.text = "\(currentIndex + 1) / \(images.count)"
    }
    
    @objc private func closePreview() {
        dismiss(animated: true)
    }
}

extension ImagePreviewViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZoomableImageCell.identifier, for: indexPath)
        
        guard let imageCell = cell as? ZoomableImageCell else { return cell }
        
        imageCell.set(image: images[indexPath.item])
        imageCell.onSingleTap = { [weak self] in
            self?.dismiss(animated: true)
        }
        
        return imageCell
    }
}

extension ImagePreviewViewController: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Only the paging scroll view reports here - the zooming ones inside the
        // cells are the cell's own delegate.
        guard scrollView === collectionView, collectionView.bounds.width > 0 else { return }
        
        let page = Int((scrollView.contentOffset.x / collectionView.bounds.width).rounded())
        guard page != currentIndex, images.indices.contains(page) else { return }
        
        currentIndex = page
        updateCounterLabel()
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        // A photo left zoomed in should come back fitted next time it is swiped to.
        (cell as? ZoomableImageCell)?.resetZoom()
    }
}

/// One page of the preview: the photo inside its own zooming scroll view.
private final class ZoomableImageCell: UICollectionViewCell {
    
    var onSingleTap: (() -> Void)?
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        resetZoom()
        imageView.image = nil
        onSingleTap = nil
    }
    
    func set(image: ImageObj?) {
        imageView.sd_setImage(with: image?.imageURL)
    }
    
    func resetZoom() {
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
    }
    
    private func setupViews() {
        contentView.backgroundColor = .clear
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 4
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        contentView.addSubview(scrollView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        scrollView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: contentView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            
            // The photo starts exactly one page wide, so zoom scale 1 is "fit".
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
    }
    
    private func setupGestures() {
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
        
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTapGesture.numberOfTapsRequired = 1
        singleTapGesture.require(toFail: doubleTapGesture)
        scrollView.addGestureRecognizer(singleTapGesture)
    }
    
    /// Tapping closes the preview, but only while zoomed out - otherwise a tap
    /// meant to pan the zoomed photo would throw the preview away.
    @objc private func handleSingleTap() {
        guard scrollView.zoomScale <= scrollView.minimumZoomScale else { return }
        
        onSingleTap?()
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard scrollView.zoomScale <= scrollView.minimumZoomScale else {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            return
        }
        
        let tapPoint = gesture.location(in: imageView)
        let zoomSize = CGSize(width: scrollView.bounds.width / 2, height: scrollView.bounds.height / 2)
        let zoomRect = CGRect(x: tapPoint.x - zoomSize.width / 2,
                              y: tapPoint.y - zoomSize.height / 2,
                              width: zoomSize.width,
                              height: zoomSize.height)
        
        scrollView.zoom(to: zoomRect, animated: true)
    }
}

extension ZoomableImageCell: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

private extension ChargingStationSheetViewController {
    enum SocialNetworkType: Int {
        case instagram = 0
        case facebook = 1
        case linkedin = 2
        case web = 3
    }
}
