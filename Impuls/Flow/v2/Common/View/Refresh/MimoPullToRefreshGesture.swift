//
//  MimoPullToRefreshGesture.swift
//  Impuls
//
//  Pull-to-refresh for a UIKit screen that has no scroll view (the home hub is
//  a fixed stack of stories, services and a sheet). A pan gesture on the host
//  view drives the same indicator and feedback as `MimoRefreshControl`; the
//  indicator slides in from under the navigation bar while the content is
//  nudged down by the pull.
//

import UIKit

final class MimoPullToRefreshGesture: NSObject, UIGestureRecognizerDelegate {

    var onRefresh: ((_ completion: @escaping (_ success: Bool) -> Void) -> Void)?

    private weak var hostView: UIView?
    private var contentViews: [UIView] { contentViewRefs.compactMap { $0.view } }
    private let contentViewRefs: [WeakView]

    private struct WeakView { weak var view: UIView? }
    private let indicator = MimoRefreshIndicatorView(frame: .zero)
    private let pan = UIPanGestureRecognizer()

    private var isRefreshing = false
    private var didAnnounceReady = false
    private var refreshStartedAt: Date?

    private let threshold = MimoRefreshControl.threshold
    private let restingOffset: CGFloat = 66

    /// - Parameters:
    ///   - hostView: receives the pan and hosts the indicator.
    ///   - contentViews: views nudged down while pulling (the top-most content
    ///     blocks). Pass an empty list to leave the content still.
    init(hostView: UIView, contentViews: [UIView]) {
        self.hostView = hostView
        self.contentViewRefs = contentViews.map { WeakView(view: $0) }
        super.init()

        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.alpha = 0
        hostView.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: hostView.centerXAnchor),
            indicator.topAnchor.constraint(equalTo: hostView.safeAreaLayoutGuide.topAnchor, constant: 8),
            indicator.widthAnchor.constraint(equalToConstant: MimoRefreshIndicatorView.size),
            indicator.heightAnchor.constraint(equalToConstant: MimoRefreshIndicatorView.size),
        ])
        indicator.transform = CGAffineTransform(translationX: 0, y: -restingOffset)

        pan.addTarget(self, action: #selector(handlePan))
        pan.delegate = self
        hostView.addGestureRecognizer(pan)
    }

    // Only claim downward drags that start on the host; let the sheet and
    // controls keep their own gestures. A horizontal carousel (stories, active
    // trips, the service cards) cannot use a vertical drag, so a pull that
    // starts on it still refreshes.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard !isRefreshing else { return false }
        var view = touch.view
        while let current = view, current !== hostView {
            if let scrollView = current as? UIScrollView {
                let scrollsVertically = scrollView.alwaysBounceVertical
                    || scrollView.contentSize.height > scrollView.bounds.height + 1
                if scrollsVertically { return false }
            } else if current is UIControl {
                return false
            }
            view = current.superview
        }
        return true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let velocity = pan.velocity(in: hostView)
        return velocity.y > 0 && abs(velocity.y) > abs(velocity.x)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        false
    }

    @objc private func handlePan() {
        let pulled = max(0, pan.translation(in: hostView).y) * 0.6   // rubber-band feel
        let progress = min(1, pulled / threshold)

        switch pan.state {
        case .began:
            MimoFeedback.shared.prepareImpact()
            didAnnounceReady = false

        case .changed:
            indicator.alpha = min(1, progress * 2)
            indicator.transform = CGAffineTransform(translationX: 0, y: -restingOffset + min(pulled, restingOffset + 20))
            contentViews.forEach { $0.transform = CGAffineTransform(translationX: 0, y: min(pulled, restingOffset)) }

            if progress >= 1 {
                if !didAnnounceReady {
                    didAnnounceReady = true
                    indicator.apply(.ready)
                    MimoFeedback.shared.impactLight()
                    MimoFeedback.shared.play(.refreshTick)
                }
            } else {
                didAnnounceReady = false
                indicator.apply(.pulling(progress), animated: false)
            }

        case .ended, .cancelled, .failed:
            if didAnnounceReady {
                startRefreshing()
            } else {
                collapse()
            }

        default:
            break
        }
    }

    private func startRefreshing() {
        isRefreshing = true
        refreshStartedAt = Date()
        indicator.apply(.refreshing)
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
            self.indicator.transform = .identity
            self.contentViews.forEach { $0.transform = CGAffineTransform(translationX: 0, y: self.restingOffset) }
        }

        guard let onRefresh else { return finish(success: true) }
        onRefresh { [weak self] success in
            DispatchQueue.main.async { self?.finish(success: success) }
        }
    }

    func finish(success: Bool) {
        let elapsed = Date().timeIntervalSince(refreshStartedAt ?? Date())
        let wait = max(0, MimoRefreshControl.minimumVisibleTime - elapsed)

        DispatchQueue.main.asyncAfter(deadline: .now() + wait) { [weak self] in
            guard let self else { return }
            if success {
                self.indicator.apply(.done)
                MimoFeedback.shared.success()
                MimoFeedback.shared.play(.refreshPop)
            } else {
                MimoFeedback.shared.error()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + (success ? MimoRefreshControl.doneHoldTime : 0)) {
                self.collapse()
            }
        }
    }

    private func collapse() {
        UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseOut]) {
            self.indicator.alpha = 0
            self.indicator.transform = CGAffineTransform(translationX: 0, y: -self.restingOffset)
            self.contentViews.forEach { $0.transform = .identity }
        } completion: { _ in
            self.isRefreshing = false
            self.didAnnounceReady = false
            self.indicator.apply(.idle, animated: false)
        }
    }
}
