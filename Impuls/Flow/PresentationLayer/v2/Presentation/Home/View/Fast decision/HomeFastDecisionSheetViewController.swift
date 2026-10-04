//
//  HomeFastDecisionSheetViewController.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.06.23.
//
//  The nearest-vehicles bottom sheet on Home.
//
//  The sheet is laid out once at its open height (from just under the pinned
//  header to the bottom of the host) and slid between the collapsed peek and
//  the open position by a translation, so neither a drag nor the settle spring
//  re-lays the list out per frame. The list is a plain table view: only the
//  visible rows are built and the cells are reused. While peeking, the table's
//  own scrolling is switched off at the scroll-view level (not its touches), so
//  rows stay tappable and a drag that starts on a row moves the sheet. Open,
//  the list scrolls on its own; pulling it 60pt past its top with the finger
//  still down collapses the sheet, Maps/Uber style.
//

import UIKit
import Combine
import CoreLocation

protocol HomeFastDecisionSheetViewControllerDelegate: AnyObject {
    func didSelect(mimo: MimoResult, type: MimoProductType)
}

class HomeFastDecisionSheetViewController: UIViewController {

    private enum Layout {
        static let cornerRadius: CGFloat = 20
        static let grabberSize = CGSize(width: 38, height: 4)
        static let grabberTop: CGFloat = 8
        /// Gap between the pinned header (the host's safe area top) and the
        /// open sheet.
        static let openTopInset: CGFloat = 6
        /// How far past its top the list is pulled, finger down, before the
        /// sheet collapses.
        static let pullToCloseDistance: CGFloat = 60
        /// The sheet's spring: response 0.35s, damping ratio 0.85.
        static let springResponse: CGFloat = 0.35
        static let springDampingRatio: CGFloat = 0.85
        /// Pulling above the open position gives, but only this much of the drag.
        static let overdragResistance: CGFloat = 0.25
        /// The share of the release velocity (pt/s) projected onto the settle.
        static let velocityProjection: CGFloat = 0.2
    }

    private enum State {
        case collapsed
        case open
    }

    private var cancellables = Set<AnyCancellable>()

    @IBOutlet private weak var tableView: UITableView!
    /// Hairline under the sheet's title; shown only once the list has scrolled.
    @IBOutlet private weak var headerDivider: UIView!

    var viewModel: MimoHomeViewModel?
    weak var delegate: HomeFastDecisionSheetViewControllerDelegate?

    private let grabber = UIView()
    private let pan = UIPanGestureRecognizer()

    private var state: State = .collapsed
    /// Height of the sheet showing above the host's bottom while collapsed.
    private var peekHeight: CGFloat = 200
    private var animator: UIViewPropertyAnimator?
    /// Set by `animateIn`; before it the sheet rests below the screen.
    private var hasAnimatedIn = false

    // Drag bookkeeping.
    private var isPanning = false
    private var panStartOffset: CGFloat = 0
    /// The translation the recogniser reported when it began. A pan only
    /// starts once the finger has moved its threshold; subtracting that first
    /// report keeps the sheet under the finger instead of jumping by it.
    private var panFirstTranslation: CGFloat = 0

    private var isHeaderDividerShown = false
    /// One collapse per pull: armed when the list is pulled far enough, released
    /// when the finger brings the list back to its top or lets go.
    private var pullToCloseLatched = false

    /// Translation that leaves exactly the peek showing.
    private var collapsedOffset: CGFloat { max(0, view.bounds.height - peekHeight) }
    private var restingOffset: CGFloat { state == .open ? 0 : collapsedOffset }
    private var currentOffset: CGFloat { view.transform.ty }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupChrome()
        setupTableView()
        setupPan()
        bindViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // The shadow of a moving layer is re-rendered every frame unless it
        // has an explicit path.
        view.layer.shadowPath = UIBezierPath(
            roundedRect: view.bounds,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: Layout.cornerRadius, height: Layout.cornerRadius)
        ).cgPath

        // A new host size (first real layout, rotation) moves the resting
        // positions; a sheet that is not in the user's hand follows at once.
        guard hasAnimatedIn, !isPanning, animator == nil else { return }
        let resting = restingOffset
        if currentOffset != resting {
            view.transform = CGAffineTransform(translationX: 0, y: resting)
        }
    }

    private func setupChrome() {
        view.backgroundColor = .appBackground
        view.layer.cornerRadius = Layout.cornerRadius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        // The background fill honours the corner radius on its own; not
        // clipping keeps the shadow. The table starts below the rounded area.
        view.layer.masksToBounds = false
        view.addShadow(color: UIColor.alwaysBlack.withAlphaComponent(0.25))

        grabber.backgroundColor = .mimoBlackWith025alpha
        grabber.layer.cornerRadius = Layout.grabberSize.height / 2
        grabber.isUserInteractionEnabled = false
        grabber.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(grabber)
        NSLayoutConstraint.activate([
            grabber.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grabber.topAnchor.constraint(equalTo: view.topAnchor, constant: Layout.grabberTop),
            grabber.widthAnchor.constraint(equalToConstant: Layout.grabberSize.width),
            grabber.heightAnchor.constraint(equalToConstant: Layout.grabberSize.height)
        ])

        headerDivider.alpha = 0
    }

    private func setupTableView() {
        tableView.register(FastDecisionTableViewCell.self)
        // Every product now draws the same row, which brings its own inset
        // hairline - the table's edge-to-edge separator would double it.
        tableView.separatorStyle = .none
        // A fixed row height lets the table place rows without building them.
        tableView.rowHeight = FastDecisionTableViewCell.rowHeight
        tableView.estimatedRowHeight = FastDecisionTableViewCell.rowHeight
        // Short lists must still overscroll, or there is nothing to pull.
        tableView.alwaysBounceVertical = true
        applyScrollLock()
    }

    private func setupPan() {
        pan.addTarget(self, action: #selector(handlePan(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
    }

    private func bindViewModel() {
        viewModel?.$availableServices.sink { [weak self] services in
            guard let availableServices = services,
                  !availableServices.isEmpty else { return }
            self?.viewModel?.loadData(for: availableServices)
        }
        .store(in: &cancellables)

        // The only reload: a new list. Dragging and settling never touch the
        // table's layout.
        viewModel?.fastDecisions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }

    // MARK: - Hosting

    /// Adds the sheet to `hostView` as a child of `parent`, laid out at its
    /// open height: from just under the host's safe area (the pinned header)
    /// to the host's bottom. It rests below the screen until `animateIn`.
    func install(in parent: UIViewController, hostView: UIView, peekHeight: CGFloat) {
        self.peekHeight = peekHeight

        parent.addChild(self)
        hostView.addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: hostView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: hostView.trailingAnchor),
            view.topAnchor.constraint(equalTo: hostView.safeAreaLayoutGuide.topAnchor, constant: Layout.openTopInset),
            view.bottomAnchor.constraint(equalTo: hostView.bottomAnchor)
        ])
        didMove(toParent: parent)

        hostView.layoutIfNeeded()
        view.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
    }

    /// Removes the sheet from its parent and host.
    func remove() {
        animator?.stopAnimation(true)
        animator = nil
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }

    /// Slides the sheet up from below the screen to its peek.
    func animateIn() {
        view.superview?.layoutIfNeeded()
        hasAnimatedIn = true
        set(state: .collapsed, animated: true)
    }

    /// A new peek (the active-sessions strip came or went); a collapsed sheet
    /// follows it.
    func setPeekHeight(_ height: CGFloat, animated: Bool) {
        guard peekHeight != height else { return }
        peekHeight = height

        guard hasAnimatedIn, !isPanning, state == .collapsed else { return }
        set(state: .collapsed, animated: animated)
    }

    // MARK: - State

    private func set(state newState: State, animated: Bool, velocity: CGFloat = 0) {
        state = newState
        applyScrollLock()

        animator?.stopAnimation(true)
        animator = nil

        let target = restingOffset
        guard animated else {
            view.transform = CGAffineTransform(translationX: 0, y: target)
            return
        }

        let distance = target - currentOffset
        let initialVelocity = abs(distance) > 0.5
            ? CGVector(dx: 0, dy: velocity / distance)
            : .zero
        // Response and damping ratio expressed as the physical spring UIKit
        // takes: stiffness = (2π / response)², damping = 2 · ratio · √stiffness.
        let stiffness = pow(2 * CGFloat.pi / Layout.springResponse, 2)
        let damping = 2 * Layout.springDampingRatio * sqrt(stiffness)
        let spring = UISpringTimingParameters(mass: 1, stiffness: stiffness, damping: damping, initialVelocity: initialVelocity)

        let animator = UIViewPropertyAnimator(duration: 0, timingParameters: spring)
        animator.addAnimations { [weak self] in
            self?.view.transform = CGAffineTransform(translationX: 0, y: target)
        }
        animator.addCompletion { [weak self] position in
            guard let self, position == .end, self.animator === animator else { return }
            self.animator = nil
            // The host may have been laid out again meanwhile.
            self.view.transform = CGAffineTransform(translationX: 0, y: self.restingOffset)
        }
        animator.startAnimation()
        self.animator = animator
    }

    /// While peeking the list does not scroll on its own, so a drag anywhere
    /// on it moves the sheet and rows still take taps; collapsing also puts
    /// the list back at its first row.
    private func applyScrollLock() {
        let scrolls = state == .open
        if tableView.isScrollEnabled != scrolls {
            tableView.isScrollEnabled = scrolls
        }
        if !scrolls {
            pullToCloseLatched = false
            if tableView.contentOffset.y != 0 {
                tableView.setContentOffset(.zero, animated: false)
            }
        }
    }

    // MARK: - Drag

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view.superview).y

        switch gesture.state {
        case .began:
            animator?.stopAnimation(true)
            animator = nil
            isPanning = true
            panStartOffset = currentOffset
            panFirstTranslation = translation

        case .changed:
            let offset = panStartOffset + (translation - panFirstTranslation)
            view.transform = CGAffineTransform(translationX: 0, y: resisted(offset))

        case .ended, .cancelled, .failed:
            isPanning = false
            let velocity = gesture.velocity(in: view.superview).y
            let projected = currentOffset + velocity * Layout.velocityProjection
            let newState: State = projected > collapsedOffset / 2 ? .collapsed : .open
            set(state: newState, animated: true, velocity: velocity)

        default:
            break
        }
    }

    /// The sheet never drops below its peek; above the open position it gives
    /// a little and springs back.
    private func resisted(_ offset: CGFloat) -> CGFloat {
        if offset < 0 {
            return offset * Layout.overdragResistance
        }
        return min(offset, collapsedOffset)
    }
}

// MARK: - Gestures

extension HomeFastDecisionSheetViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === pan else { return true }

        let velocity = pan.velocity(in: view)
        guard abs(velocity.y) > abs(velocity.x) else { return false }

        // Open, the list owns the drags on itself (its own scrolling and the
        // pull-to-close below); the grabber and the title still drag the sheet.
        if state == .open, tableView.isScrollEnabled,
           tableView.bounds.contains(pan.location(in: tableView)) {
            return false
        }
        return true
    }

    // The home hub's pull-to-refresh is a pan on an ancestor view. A drag that
    // starts on the sheet belongs to the sheet: the hub's pan waits for this
    // one to fail, which it only does for a sideways drag or on the open list.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer === pan,
              otherGestureRecognizer is UIPanGestureRecognizer,
              let otherView = otherGestureRecognizer.view else { return false }
        return otherView !== view && !otherView.isDescendant(of: view)
    }
}

// MARK: - Table

extension HomeFastDecisionSheetViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        // One height for every product: the row is the same shape whatever it
        // describes, and a uniform rhythm is easier to scan than three sizes.
        return FastDecisionTableViewCell.rowHeight
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.fastDecisions.value.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel, indexPath.row < viewModel.fastDecisions.value.count else { return UITableViewCell() }
        let cell: FastDecisionTableViewCell = tableView.dequeueReusableCell(withIdentifier: "FastDecisionTableViewCell")

        let item = viewModel.fastDecisions.value[indexPath.row]
        if let scooter = item as? ScooterResult {
            cell.set(scooter: scooter, currentLocation: viewModel.currentLocation)
        } else if let bike = item as? BikeResult {
            cell.set(bike: bike, currentLocation: viewModel.currentLocation)
        } else if let charger = item as? ChargingStation {
            cell.set(charger: charger, currentLocation: viewModel.currentLocation)
        } else if let evCharger = item as? EVChargingStation {
            cell.set(evCharger: evCharger, currentLocation: viewModel.currentLocation)
        }

        return cell
    }
}

extension HomeFastDecisionSheetViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let viewModel, indexPath.row < viewModel.fastDecisions.value.count else { return }
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()

        let item = viewModel.fastDecisions.value[indexPath.row]
        if let scooter = item as? ScooterResult {
            delegate?.didSelect(mimo: scooter, type: .scooter)
        } else if let bike = item as? BikeResult {
            delegate?.didSelect(mimo: bike, type: .bike)
        } else if let charger = item as? ChargingStation {
            delegate?.didSelect(mimo: charger, type: .charger)
        } else if let evCharger = item as? EVChargingStation {
            delegate?.didSelect(mimo: evCharger, type: .evCharger)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // The title's hairline appears once the first row has slid under it;
        // written only when that flips, not on every frame.
        let scrolled = scrollView.contentOffset.y > 0
        if scrolled != isHeaderDividerShown {
            isHeaderDividerShown = scrolled
            UIView.animate(withDuration: 0.15) {
                self.headerDivider.alpha = scrolled ? 1 : 0
            }
        }

        // Pull-to-close: only while the finger is down and dragging. A flick
        // that overshoots the top (deceleration, bounce) is ignored.
        guard state == .open, scrollView.isTracking, scrollView.isDragging else { return }
        let overscroll = -(scrollView.contentOffset.y + scrollView.adjustedContentInset.top)

        if overscroll >= Layout.pullToCloseDistance {
            guard !pullToCloseLatched else { return }
            pullToCloseLatched = true
            MimoFeedback.shared.impactLight()
            // Not from inside the scroll callback: the table is still
            // delivering this drag.
            DispatchQueue.main.async { [weak self] in
                guard let self, self.state == .open else { return }
                self.set(state: .collapsed, animated: true)
            }
        } else if overscroll <= 0 {
            pullToCloseLatched = false
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        MimoFeedback.shared.prepareImpact()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        pullToCloseLatched = false
    }
}
