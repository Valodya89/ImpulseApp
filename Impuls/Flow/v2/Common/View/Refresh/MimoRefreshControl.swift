//
//  MimoRefreshControl.swift
//  Impuls
//
//  Pull-to-refresh for any UIScrollView, showing the Mimo indicator and driving
//  the haptic + sound feedback:
//
//    pull  -> ring fills with the drag (0-80 pt)
//    80 pt -> light impact + tick, disc turns yellow
//    load  -> ring spins, shown at least 600 ms so it never flickers
//    done  -> check, success haptic + pop, then fades out
//
//  Deliberately NOT a UIRefreshControl, and deliberately touching neither
//  `contentInset` nor `contentOffset`. On the UIScrollView behind a SwiftUI
//  ScrollView (`HostingScrollView`) SwiftUI owns all three and writes its own
//  values back on its next layout pass. Measured on iOS 18.4: a refresh control
//  assigned there is dropped and deallocated inside half a second, and an added
//  `contentInset.top` is gone in under 100 ms. So this class owns nothing but
//  its own subview - it reads `contentOffset`, places the indicator in the
//  visible area itself, and lets the scroll view bounce the way it always did.
//

import UIKit

final class MimoRefreshControl: NSObject {

    static let threshold: CGFloat = 80
    static let minimumVisibleTime: TimeInterval = 0.6
    static let doneHoldTime: TimeInterval = 0.4

    /// How far below the top of the visible area the indicator travels with the
    /// pull, and where it settles while the refresh runs.
    private static let maximumTravel: CGFloat = 52
    private static let restingTravel: CGFloat = 34
    private static let fadeDuration: TimeInterval = 0.25
    /// Pull distance over which the indicator fades in.
    private static let fadeInDistance: CGFloat = 24

    /// Called when the rider releases past the threshold. Call the completion
    /// when the data is back; the control ends itself.
    var onRefresh: ((_ completion: @escaping (_ success: Bool) -> Void) -> Void)?

    private(set) var isRefreshing = false

    private let indicator = MimoRefreshIndicatorView(frame: .zero)
    private weak var scrollView: UIScrollView?
    private var observation: NSKeyValueObservation?

    private var refreshStartedAt: Date?
    private var didAnnounceReady = false

    deinit { observation = nil }

    // MARK: - Attaching

    /// Takes over pull-to-refresh on `scrollView`. Safe to call repeatedly with
    /// the same scroll view; re-attaching moves the indicator to the new one.
    func attach(to scrollView: UIScrollView) {
        guard self.scrollView !== scrollView else { return }
        detach()

        self.scrollView = scrollView

        indicator.alpha = 0
        indicator.layer.zPosition = 1_000
        // The indicator floats over the content rather than sitting in a gap
        // held open by an inset, so it needs to lift off it. Same shadow as
        // `.mimoCard()`, which is what everything else in the app floats with.
        indicator.layer.shadowColor = UIColor.black.cgColor
        indicator.layer.shadowOpacity = 0.10
        indicator.layer.shadowRadius = 8
        indicator.layer.shadowOffset = CGSize(width: 0, height: 2)
        scrollView.addSubview(indicator)

        observation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] scrollView, _ in
            self?.didScroll(scrollView)
        }
        // The scroll view's own pan says exactly when the finger lifts - no
        // extra recogniser to arbitrate with.
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePan))

        layout(in: scrollView)
    }

    func detach() {
        observation = nil
        scrollView?.panGestureRecognizer.removeTarget(self, action: #selector(handlePan))
        indicator.removeFromSuperview()
        scrollView = nil
        isRefreshing = false
    }

    // MARK: - Geometry

    /// Content-space y of the top of the visible area. Negative while the rider
    /// is pulling past the top, and then its size is the pull distance.
    private func visibleTop(in scrollView: UIScrollView) -> CGFloat {
        scrollView.contentOffset.y + scrollView.adjustedContentInset.top
    }

    private func layout(in scrollView: UIScrollView) {
        // Both re-applied rather than set once: SwiftUI rebuilds its scroll
        // view whenever the content changes, and a refresh is precisely that.
        if indicator.superview !== scrollView { scrollView.addSubview(indicator) }
        if !scrollView.alwaysBounceVertical { scrollView.alwaysBounceVertical = true }

        let top = visibleTop(in: scrollView)
        let pulled = max(0, -top)
        // Follows the finger at half rate, then stops. While refreshing it
        // settles no higher than `restingTravel`, so the hand-off from the pull
        // to the spin has no jump in it.
        let travel = isRefreshing
            ? max(min(pulled / 2, Self.maximumTravel), Self.restingTravel)
            : min(pulled / 2, Self.maximumTravel)

        let size = MimoRefreshIndicatorView.size
        indicator.bounds = CGRect(x: 0, y: 0, width: size, height: size)
        indicator.center = CGPoint(x: scrollView.bounds.width / 2, y: top + travel)

        if !isRefreshing {
            indicator.alpha = max(0, min(1, pulled / Self.fadeInDistance))
        }
    }

    // MARK: - Pull

    private func didScroll(_ scrollView: UIScrollView) {
        layout(in: scrollView)

        guard !isRefreshing else { return }

        let pulled = -visibleTop(in: scrollView)
        guard pulled > 0 else {
            if case .idle = indicator.state {} else { indicator.apply(.idle) }
            didAnnounceReady = false
            return
        }

        let progress = pulled / Self.threshold
        if progress >= 1 {
            if !didAnnounceReady {
                didAnnounceReady = true
                indicator.apply(.ready)
                MimoFeedback.shared.impactLight()
                MimoFeedback.shared.play(.refreshTick)
            }
        } else {
            if didAnnounceReady { didAnnounceReady = false }
            if progress > 0.05 { MimoFeedback.shared.prepareImpact() }
            indicator.apply(.pulling(progress), animated: false)
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard gesture.state == .ended, !isRefreshing, let scrollView else { return }
        guard -visibleTop(in: scrollView) >= Self.threshold else { return }
        beginRefreshing()
    }

    // MARK: - Refreshing

    func beginRefreshing() {
        guard !isRefreshing, let scrollView else { return }
        isRefreshing = true
        didAnnounceReady = false
        refreshStartedAt = Date()

        indicator.alpha = 1
        indicator.apply(.refreshing)
        layout(in: scrollView)

        guard let onRefresh else {
            finish(success: true)
            return
        }
        onRefresh { [weak self] success in
            DispatchQueue.main.async { self?.finish(success: success) }
        }
    }

    /// Ends the refresh honouring the minimum visible time, shows the check,
    /// then fades out.
    func finish(success: Bool) {
        guard isRefreshing else { return }

        let elapsed = Date().timeIntervalSince(refreshStartedAt ?? Date())
        let wait = max(0, Self.minimumVisibleTime - elapsed)

        DispatchQueue.main.asyncAfter(deadline: .now() + wait) { [weak self] in
            guard let self, self.isRefreshing else { return }
            if success {
                self.indicator.apply(.done)
                MimoFeedback.shared.success()
                MimoFeedback.shared.play(.refreshPop)
            } else {
                MimoFeedback.shared.error()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + (success ? Self.doneHoldTime : 0)) {
                self.isRefreshing = false
                self.didAnnounceReady = false

                UIView.animate(withDuration: Self.fadeDuration,
                               delay: 0,
                               options: [.beginFromCurrentState],
                               animations: {
                    self.indicator.alpha = 0
                    if let scrollView = self.scrollView { self.layout(in: scrollView) }
                }, completion: { _ in
                    // Let the fade finish before resetting, so the check does
                    // not flip back to the mark while still on screen.
                    guard !self.isRefreshing else { return }
                    self.indicator.apply(.idle, animated: false)
                    self.indicator.alpha = 0
                })
            }
        }
    }
}
