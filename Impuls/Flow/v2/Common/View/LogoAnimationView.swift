//
//  LogoAnimationView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 16.09.23.
//

import SwiftUI

/// The splash mark. A flat line snaps into place, a charge runs into it from
/// the left and the line answers - rising into the brand's pulse as the charge
/// passes through it, holding that shape for a beat under a shockwave, then
/// flattening again as the charge leaves - once, not on a loop. The app's name
/// builds underneath as this happens, one letter at a time. The line carries the app icon's
/// orange-into-amber gradient. Drawn natively, so it needs no
/// animation file and stays sharp at any size.
///
/// Reduce Motion gets the held shape and the whole name, still.
struct LogoAnimationView: View {

    // MARK: - Timeline of one pass, in seconds

    /// The line snapping into place, centre outwards.
    private let arrival: TimeInterval = 0.40
    /// The charge running in from the left until it sits in the middle.
    private let approach: TimeInterval = 0.60
    /// The mark, held.
    private let hold: TimeInterval = 0.50
    /// The charge leaving to the right.
    private let departure: TimeInterval = 0.50
    /// The line, flat again, as the pass closes.
    private let rest: TimeInterval = 0.40

    /// The whole pass, start to finish. The splash stays up at least this long
    /// (see `SplashView`), so it is seen once, in full.
    private var cycle: TimeInterval { arrival + approach + hold + departure + rest }

    /// How far the shockwave outlives the moment it is thrown.
    private let shockLife: TimeInterval = 0.70

    /// The pulse carries the app icon's own gradient, orange into amber.
    private let charge = LinearGradient(
        colors: [.brandPulseStart, .brandPulseEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
    /// The light the charge throws, and the shockwave, take the warmer end.
    private let spark = Color.brandPulseStart
    /// The name is set in the icon's dark ink, on the icon's white ground.
    private let ink = Color.onBrandLabel

    /// The mark is wide and short, like the one on the app icon, and never
    /// grows past a logo's size however much room the screen offers.
    private let markAspect: CGFloat = 2.4
    private let markMaxWidth: CGFloat = 250

    /// How tall the pulse stands, as a share of the mark's height.
    private let amplitude: CGFloat = 0.42

    // MARK: - The name

    /// Whatever the app is called on the home screen, so the two never drift.
    private var appName: String {
        let info = Bundle.main.infoDictionary
        let name = (info?["CFBundleDisplayName"] as? String)
            ?? (info?["CFBundleName"] as? String)
        return (name ?? "Импульс").uppercased()
    }

    /// The first letter arrives while the charge is still running in.
    private let nameStarts: TimeInterval = 0.75
    /// The last one is down before the line settles, whatever the name's length.
    private var nameSettled: TimeInterval { cycle - 0.15 }
    /// How long a single letter takes to land.
    private let letterFlight: TimeInterval = 0.40

    /// The gap between one letter and the next, stretched across the pass so
    /// they read one at a time - and squeezed, never spilled past the end, when
    /// the name is a long one.
    private var letterStagger: TimeInterval {
        let count = appName.count
        guard count > 1 else { return 0 }

        let window = max(0, nameSettled - nameStarts - letterFlight)
        return min(0.24, window / Double(count - 1))
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Timed from the moment the splash appears, so every launch opens on the
    /// line snapping in rather than mid-pass.
    @State private var birth = Date()

    var body: some View {
        GeometryReader { proxy in
            let size = markSize(in: proxy.size)
            let weight = max(3, size.height * 0.15)

            Group {
                if reduceMotion {
                    stack(size: size) {
                        PulseTrace(impulse: 0.5, amplitude: amplitude)
                            .stroke(charge, style: stroke(weight))
                    } name: {
                        name(size: size) { _ in 1 }
                    }
                } else {
                    TimelineView(.animation) { context in
                        let elapsed = context.date.timeIntervalSince(birth)

                        stack(size: size) {
                            // One pass only, then the last frame is held: a
                            // second charge starting under the crossfade reads
                            // as the splash stuttering.
                            pass(at: min(elapsed, cycle), size: size, weight: weight)
                        } name: {
                            // Timed from the launch, not from the pass, so the
                            // name settles once and stays put while the line
                            // keeps beating.
                            name(size: size) { index in
                                easeOutBack(progress(elapsed,
                                                     from: nameStarts + Double(index) * letterStagger,
                                                     over: letterFlight))
                            }
                        }
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
        .accessibilityHidden(true)
    }

    /// The mark with the name under it, as one centred block.
    private func stack<Mark: View, Name: View>(
        size: CGSize,
        @ViewBuilder mark: () -> Mark,
        @ViewBuilder name: () -> Name
    ) -> some View {
        VStack(spacing: size.height * 0.32) {
            mark()
                .frame(width: size.width, height: size.height)

            name()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The name, letter by letter. `landed` gives each letter's own progress,
    /// so they arrive in order rather than as a block.
    private func name(size: CGSize, landed: @escaping (Int) -> CGFloat) -> some View {
        let letters = Array(appName)
        let body = size.height * 0.30

        return HStack(spacing: body * 0.14) {
            ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                let flight = landed(index)

                Text(String(letter))
                    .font(.custom(Constant.Font.robotoBold, size: body))
                    .foregroundColor(ink)
                    // The letter drops in under the shockwave and settles.
                    .offset(y: (1 - min(1, flight)) * body * 0.9)
                    .scaleEffect(0.78 + 0.22 * flight, anchor: .bottom)
                    .opacity(Double(min(1, flight * 1.6)))
            }
        }
        .frame(height: body * 1.25)
    }

    // MARK: - One frame of the pass

    private func pass(at time: TimeInterval, size: CGSize, weight: CGFloat) -> some View {
        let position = position(at: time)
        let reach = reach(at: time)
        let live = liveness(at: time)

        return ZStack {
            PulseTrace(impulse: position, amplitude: amplitude * live)
                .trim(from: 0.5 - reach / 2, to: 0.5 + reach / 2)
                .stroke(charge, style: stroke(weight))

            glow(in: size, at: position, strength: live)
            shock(in: size, time: time, weight: weight)
        }
        .scaleEffect(1 + 0.02 * live)
    }

    /// The light the charge carries, pooled on the line beneath the spike.
    @ViewBuilder
    private func glow(in size: CGSize, at position: CGFloat, strength: CGFloat) -> some View {
        if strength > 0.01, position > -0.1, position < 1.1 {
            let span = size.height * 1.3

            Circle()
                .fill(
                    RadialGradient(
                        colors: [spark.opacity(0.30 * strength), spark.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: span / 2
                    )
                )
                .frame(width: span, height: span)
                .position(x: size.width * position, y: size.height * 0.5)
        }
    }

    /// The ring thrown off the spike the moment the charge lands in the middle.
    @ViewBuilder
    private func shock(in size: CGSize, time: TimeInterval, weight: CGFloat) -> some View {
        let life = progress(time, from: arrival + approach, over: shockLife)

        if life > 0, life < 1 {
            let fade = 1 - life
            let span = size.height * (0.35 + 1.5 * life)

            Circle()
                .stroke(spark.opacity(0.5 * fade * fade), lineWidth: weight * 0.45 * fade)
                .frame(width: span, height: span)
                .position(x: size.width * 0.5, y: size.height * (0.5 - amplitude))
        }
    }

    // MARK: - The pass, step by step

    /// Where the charge sits along the line: off to the left, into the middle,
    /// held there, then away to the right.
    private func position(at time: TimeInterval) -> CGFloat {
        let entering = arrival
        let held = arrival + approach
        let leaving = held + hold

        if time < entering { return -0.3 }

        if time < held {
            // Decelerating into the middle, the way something heavy arrives.
            return -0.3 + 0.8 * easeOut(progress(time, from: entering, over: approach))
        }

        if time < leaving { return 0.5 }

        // Accelerating away again.
        return 0.5 + 0.8 * easeIn(progress(time, from: leaving, over: departure))
    }

    /// How much of the line is laid down, centre outwards.
    private func reach(at time: TimeInterval) -> CGFloat {
        ease(progress(time, from: 0, over: arrival))
    }

    /// How strongly the line answers the charge: nothing before it arrives,
    /// full while it passes, gone once it has left.
    private func liveness(at time: TimeInterval) -> CGFloat {
        let held = arrival + approach
        let gone = held + hold + departure

        if time < arrival { return 0 }
        if time < held { return ease(progress(time, from: arrival, over: approach * 0.6)) }
        if time < gone { return 1 }

        return 1 - ease(progress(time, from: gone, over: rest * 0.5))
    }

    // MARK: - Shorthand

    private func stroke(_ weight: CGFloat) -> StrokeStyle {
        StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round)
    }

    /// A logo-sized box in the middle of whatever room the screen gives, so the
    /// mark never stretches to the full height of a phone.
    private func markSize(in available: CGSize) -> CGSize {
        let width = max(1, min(available.width, markMaxWidth))
        let height = min(width / markAspect, max(1, available.height))
        return CGSize(width: height * markAspect, height: height)
    }

    /// 0 before `from`, 1 once `over` has passed, clamped in between.
    private func progress(_ time: TimeInterval, from: TimeInterval, over duration: TimeInterval) -> CGFloat {
        guard duration > 0 else { return 1 }
        return CGFloat(min(1, max(0, (time - from) / duration)))
    }

    private func ease(_ value: CGFloat) -> CGFloat {
        value < 0.5 ? 2 * value * value : 1 - pow(-2 * value + 2, 2) / 2
    }

    private func easeOut(_ value: CGFloat) -> CGFloat {
        1 - pow(1 - value, 3)
    }

    private func easeIn(_ value: CGFloat) -> CGFloat {
        value * value * value
    }

    /// Overshoots a little before settling, so a letter lands rather than
    /// simply appearing.
    private func easeOutBack(_ value: CGFloat) -> CGFloat {
        let pull: CGFloat = 1.7
        let rebound = pull + 1
        let shifted = value - 1
        return 1 + rebound * shifted * shifted * shifted + pull * shifted * shifted
    }
}

/// The line, bent by a charge passing through it. With the charge in the middle
/// this is the pulse from the app icon; with the charge away it is flat.
struct PulseTrace: Shape {

    /// Where the charge sits, 0 at the left edge and 1 at the right.
    var impulse: CGFloat
    /// How tall the answer stands, as a share of the height.
    var amplitude: CGFloat

    /// How far either side of itself the charge bends the line.
    private let spread: CGFloat = 0.5
    private let samples = 150

    func path(in rect: CGRect) -> Path {
        var path = Path()

        for step in 0...samples {
            let x = CGFloat(step) / CGFloat(samples)
            let y = 0.5 - amplitude * Self.answer(to: (x - impulse) / spread)
            let point = CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)

            if step == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        return path
    }

    /// The shape of the answer: a lean-in, the spike, the deep trough that
    /// follows it and a small rebound - the pulse of the brand mark.
    private static func answer(to distance: CGFloat) -> CGFloat {
        guard abs(distance) < 1.4 else { return 0 }

        return 1.00 * bell(distance, at: 0.00, width: 0.085)
             - 0.62 * bell(distance, at: 0.21, width: 0.110)
             - 0.14 * bell(distance, at: -0.28, width: 0.130)
             + 0.13 * bell(distance, at: 0.54, width: 0.190)
    }

    private static func bell(_ x: CGFloat, at centre: CGFloat, width: CGFloat) -> CGFloat {
        let offset = (x - centre) / width
        return exp(-offset * offset)
    }
}

struct LogoAnimationView_Previews: PreviewProvider {
    static var previews: some View {
        LogoAnimationView()
            .padding(.horizontal, 50)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.alwaysWhite)
    }
}
