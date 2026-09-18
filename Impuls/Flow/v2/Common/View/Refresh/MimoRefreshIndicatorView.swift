//
//  MimoRefreshIndicatorView.swift
//  Impuls
//
//  The branded pull-to-refresh indicator: a disc carrying the Impuls mark (the
//  pulse line from the logo, in its orange gradient) with a ring that fills as
//  the rider pulls, snaps solid at the threshold, spins while loading - the
//  pulse redrawing itself the way the splash animation does - and ends on a
//  check. Pure Core Animation so it is cheap to host in a UIView or a SwiftUI
//  bridge.
//

import UIKit

final class MimoRefreshIndicatorView: UIView {

    enum State: Equatable {
        case idle
        /// 0...1, how much of the threshold distance has been pulled.
        case pulling(CGFloat)
        case ready
        case refreshing
        case done
    }

    static let size: CGFloat = 44

    private(set) var state: State = .idle

    private let disc = CAShapeLayer()
    private let track = CAShapeLayer()
    /// The ring is a mask over a gradient so it carries the logo colours.
    private let ring = CAShapeLayer()
    private let ringGradient = CAGradientLayer()
    /// The pulse line, in the logo gradient (masked) and in white (solid) for
    /// the orange states.
    private let pulseMask = CAShapeLayer()
    private let pulseGradient = CAGradientLayer()
    private let pulseSolid = CAShapeLayer()
    private let check = UIImageView()

    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    /// The three stops of the logo's gradient stroke (`logo.json`).
    private static let brandGradient: [CGColor] = [
        UIColor(red: 0.937, green: 0.357, blue: 0.106, alpha: 1).cgColor,
        UIColor(red: 0.984, green: 0.616, blue: 0.122, alpha: 1).cgColor,
        UIColor(red: 0.992, green: 0.745, blue: 0.180, alpha: 1).cgColor
    ]
    private static let brandSolid = UIColor(red: 0.984, green: 0.616, blue: 0.122, alpha: 1)

    override init(frame: CGRect) {
        super.init(frame: CGRect(origin: frame.origin, size: CGSize(width: Self.size, height: Self.size)))
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override var intrinsicContentSize: CGSize { CGSize(width: Self.size, height: Self.size) }

    private func setup() {
        isUserInteractionEnabled = false

        let rect = CGRect(x: 0, y: 0, width: Self.size, height: Self.size)
        let ringRect = rect.insetBy(dx: 3, dy: 3)
        let circle = UIBezierPath(ovalIn: ringRect).cgPath

        disc.path = circle
        disc.fillColor = UIColor.refreshSurface.resolvedColor(with: traitCollection).cgColor
        layer.addSublayer(disc)

        track.path = circle
        track.fillColor = nil
        track.strokeColor = UIColor.refreshStroke.resolvedColor(with: traitCollection).cgColor
        track.lineWidth = 3
        layer.addSublayer(track)

        // Start the ring at 12 o'clock.
        ring.path = UIBezierPath(arcCenter: CGPoint(x: rect.midX, y: rect.midY),
                                 radius: ringRect.width / 2,
                                 startAngle: -.pi / 2,
                                 endAngle: 1.5 * .pi,
                                 clockwise: true).cgPath
        ring.fillColor = nil
        ring.strokeColor = UIColor.black.cgColor // mask: only its alpha counts
        ring.lineWidth = 3
        ring.lineCap = .round
        ring.strokeEnd = 0
        ring.frame = rect
        ringGradient.frame = rect
        ringGradient.colors = Self.brandGradient
        ringGradient.startPoint = CGPoint(x: 0, y: 0.5)
        ringGradient.endPoint = CGPoint(x: 1, y: 0.5)
        ringGradient.mask = ring
        layer.addSublayer(ringGradient)

        let pulsePath = Self.pulsePath(in: rect.insetBy(dx: 10, dy: 14))
        for shape in [pulseMask, pulseSolid] {
            shape.path = pulsePath
            shape.fillColor = nil
            shape.lineWidth = 2.4
            shape.lineJoin = .round
            shape.lineCap = .round
            shape.frame = rect
        }
        pulseMask.strokeColor = UIColor.black.cgColor
        pulseGradient.frame = rect
        pulseGradient.colors = Self.brandGradient
        pulseGradient.startPoint = CGPoint(x: 0, y: 0.5)
        pulseGradient.endPoint = CGPoint(x: 1, y: 0.5)
        pulseGradient.mask = pulseMask
        layer.addSublayer(pulseGradient)

        pulseSolid.strokeColor = UIColor.white.cgColor // stays white: drawn on the orange disc
        pulseSolid.opacity = 0
        layer.addSublayer(pulseSolid)

        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        check.image = UIImage(systemName: "checkmark", withConfiguration: config)
        check.tintColor = .white // stays white: drawn on the orange disc
        check.contentMode = .center
        check.frame = rect
        check.alpha = 0
        addSubview(check)

        apply(.idle, animated: false)
    }

    /// The pulse line traced from the logo's vertices, normalised to `box`.
    private static func pulsePath(in box: CGRect) -> CGPath {
        let normalized: [(CGFloat, CGFloat)] = [
            (0.000, 0.538), (0.346, 0.538), (0.449, 0.538), (0.537, 0.000),
            (0.688, 1.000), (0.824, 0.538), (0.878, 0.538), (1.000, 0.538)
        ]
        let points = normalized.map { CGPoint(x: box.minX + $0.0 * box.width, y: box.minY + $0.1 * box.height) }
        let path = UIBezierPath()
        path.move(to: points[0])
        points.dropFirst().forEach { path.addLine(to: $0) }
        return path.cgPath
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // CALayer colours do not adapt on their own.
        track.strokeColor = UIColor.refreshStroke.resolvedColor(with: traitCollection).cgColor
        apply(state, animated: false)
    }

    // MARK: - State

    func apply(_ newState: State, animated: Bool = true) {
        state = newState

        CATransaction.begin()
        CATransaction.setDisableActions(!animated)

        switch newState {
        case .idle:
            stopAnimations()
            ring.strokeEnd = 0
            ringGradient.opacity = 1
            disc.fillColor = UIColor.refreshSurface.resolvedColor(with: traitCollection).cgColor
            track.opacity = 1
            setMark(gradient: true, alpha: 0.35, scale: 0.7)
            check.alpha = 0

        case .pulling(let progress):
            stopAnimations()
            let p = max(0, min(1, progress))
            ring.strokeEnd = p
            ringGradient.opacity = 1
            disc.fillColor = UIColor.refreshSurface.resolvedColor(with: traitCollection).cgColor
            track.opacity = 1
            setMark(gradient: true, alpha: 0.35 + 0.65 * p, scale: reduceMotion ? 1 : 0.7 + 0.3 * p)
            check.alpha = 0

        case .ready:
            stopAnimations()
            ring.strokeEnd = 1
            ringGradient.opacity = 1
            disc.fillColor = Self.brandSolid.cgColor
            track.opacity = 0
            setMark(gradient: false, alpha: 1, scale: 1)
            check.alpha = 0

        case .refreshing:
            disc.fillColor = UIColor.refreshSurface.resolvedColor(with: traitCollection).cgColor
            track.opacity = 1
            setMark(gradient: true, alpha: 1, scale: 1)
            check.alpha = 0
            ring.strokeEnd = 0.75
            if reduceMotion {
                ringGradient.opacity = 0.6
            } else {
                startAnimations()
            }

        case .done:
            stopAnimations()
            ring.strokeEnd = 1
            ringGradient.opacity = 1
            disc.fillColor = Self.brandSolid.cgColor
            track.opacity = 0
            setMark(gradient: true, alpha: 0, scale: 1)
            check.alpha = 1
        }

        CATransaction.commit()
    }

    /// Shows the pulse in the logo gradient (white disc) or in white (orange disc).
    private func setMark(gradient: Bool, alpha: CGFloat, scale: CGFloat) {
        let transform = CATransform3DMakeScale(scale, scale, 1)
        pulseGradient.opacity = gradient ? Float(alpha) : 0
        pulseSolid.opacity = gradient ? 0 : Float(alpha)
        pulseGradient.transform = transform
        pulseSolid.transform = transform
    }

    private func startAnimations() {
        if ringGradient.animation(forKey: "spin") == nil {
            let spin = CABasicAnimation(keyPath: "transform.rotation.z")
            spin.fromValue = 0
            spin.toValue = 2 * CGFloat.pi
            spin.duration = 0.9
            spin.repeatCount = .infinity
            spin.isRemovedOnCompletion = false
            ringGradient.add(spin, forKey: "spin")
        }

        // The pulse draws itself and wipes away, like the splash's trim path.
        if pulseMask.animation(forKey: "draw") == nil {
            let drawOn = CABasicAnimation(keyPath: "strokeEnd")
            drawOn.fromValue = 0
            drawOn.toValue = 1
            drawOn.beginTime = 0
            drawOn.duration = 0.55
            drawOn.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            let wipe = CABasicAnimation(keyPath: "strokeStart")
            wipe.fromValue = 0
            wipe.toValue = 1
            wipe.beginTime = 0.65
            wipe.duration = 0.45
            wipe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

            let group = CAAnimationGroup()
            group.animations = [drawOn, wipe]
            group.duration = 1.3
            group.repeatCount = .infinity
            group.isRemovedOnCompletion = false
            pulseMask.add(group, forKey: "draw")
        }
    }

    private func stopAnimations() {
        ringGradient.removeAnimation(forKey: "spin")
        pulseMask.removeAnimation(forKey: "draw")
    }
}

private extension UIColor {
    static var refreshSurface: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.19, green: 0.20, blue: 0.25, alpha: 1) : .white }
    }

    static var refreshStroke: UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.2) : UIColor(red: 0.88, green: 0.91, blue: 0.93, alpha: 1) }
    }
}
