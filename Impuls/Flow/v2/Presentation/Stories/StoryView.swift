//
//  StoryView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.12.23.
//
//  The full-screen stories viewer, presented by `StoryViewerPresenter`.
//
//  - Zooms out of the tapped thumbnail and back into it on close (a fade
//    when the thumbnail is off screen or Reduce Motion is on).
//  - Stories sit side by side on a cube; dragging sideways turns it, with a
//    cross-fade instead under Reduce Motion.
//  - Dragging down shrinks the card and fades the black behind it; released
//    far or fast enough it closes, otherwise it springs back.
//  - Swiping up on a LINK page opens the link.
//  Timing, pausing and page order are `StoryPlayer`'s; this file only draws
//  and turns gestures into player calls.
//
//  The Impulse project is not folder-synchronised, so the viewer's chrome
//  (`StoryChromeViews`), its touch surface (`StoryGestureLayer`) and the
//  presenter (`StoryViewerPresenter`) live in this file as marked sections.
//  Everything drawn on the story's picture or video uses the fixed
//  `alwaysWhite` / `alwaysBlack` tokens: the media, not the app theme, is its
//  background.
//

import SwiftUI
import UIKit
import Kingfisher

// MARK: - StoryViewerView

struct StoryViewerView: View {

    @ObservedObject var player: StoryPlayer
    @ObservedObject var viewModel: StoryViewModel
    /// The global frame of a story's thumbnail on home, nil when off screen.
    let thumbnailFrame: (String) -> CGRect?
    /// The closing animation is over: take the viewer away.
    let onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isExpanded = false
    /// Thumbnail frame (global) the viewer zooms from / into.
    @State private var zoomFrame: CGRect?
    @State private var pagerOffset: CGFloat = 0
    @State private var dismissOffset: CGSize = .zero
    @State private var liftOffset: CGFloat = 0
    @State private var dragAxis: DragAxis?
    /// The story whose heart burst plays, and a counter bumped per like.
    @State private var likeBurst: (storyId: String, count: Int) = ("", 0)

    private enum DragAxis { case horizontal, down, up }

    private static let cardRadius: CGFloat = 10
    private static let openAnimation = Animation.spring(response: 0.38, dampingFraction: 0.86)
    private static let closeDuration = 0.32

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let origin = proxy.frame(in: .global).origin

            ZStack {
                // A scrim, black in both appearances.
                Color.alwaysBlack
                    .opacity(backgroundOpacity(height: size.height))
                    .ignoresSafeArea()

                pager(size: size)
                    .frame(width: size.width, height: size.height)
                    .scaleEffect(dismissScale(height: size.height))
                    .offset(x: dismissOffset.width, y: dismissOffset.height + liftOffset)
                    .modifier(zoomModifier(size: size, origin: origin))
                    .allowsHitTesting(isExpanded)
            }
        }
        .onAppear(perform: open)
        .onReceive(player.$closeRequest.compactMap { $0 }) { _ in close() }
    }

    // MARK: - Pager

    private func pager(size: CGSize) -> some View {
        let lower = max(0, player.storyIndex - 1)
        let upper = min(player.stories.count - 1, player.storyIndex + 1)
        let indices = lower <= upper ? Array(lower...upper) : []

        return ZStack {
            ForEach(indices, id: \.self) { index in
                let offset = CGFloat(index - player.storyIndex) * size.width + pagerOffset
                let isCurrent = index == player.storyIndex

                StoryCardView(
                    story: player.stories[index],
                    pageIndex: player.displayedPageIndex(forStoryAt: index),
                    isCurrent: isCurrent,
                    player: player,
                    viewModel: viewModel,
                    likeBurst: likeBurst.storyId == player.stories[index].id ? likeBurst.count : 0,
                    onLike: like,
                    onClose: { player.requestClose(.closeButton) },
                    onPan: { handlePan($0, size: size) }
                )
                .frame(width: size.width, height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: Self.cardRadius, style: .continuous))
                .modifier(CubeModifier(offset: offset, width: size.width, reduceMotion: reduceMotion))
                .zIndex(isCurrent ? 1 : 0)
                .allowsHitTesting(isCurrent)
                .accessibilityHidden(!isCurrent)
                .transition(.identity)
            }
        }
    }

    // MARK: - Open and close

    private func open() {
        if let id = player.currentStory?.id { zoomFrame = thumbnailFrame(id) }
        player.start()

        DispatchQueue.main.async {
            withAnimation(reduceMotion ? .easeOut(duration: 0.2) : Self.openAnimation) {
                isExpanded = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            player.resume(.opening)
        }
    }

    private func close() {
        // Into the thumbnail of the story on screen, wherever the strip has
        // put it by now.
        zoomFrame = player.currentStory.flatMap { thumbnailFrame($0.id) }

        withAnimation(.easeInOut(duration: Self.closeDuration)) {
            isExpanded = false
            dismissOffset = .zero
            liftOffset = 0
            pagerOffset = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.closeDuration + 0.02) {
            onFinish()
        }
    }

    private func zoomModifier(size: CGSize, origin: CGPoint) -> ZoomTransition {
        var local: CGRect?
        if let zoomFrame, !reduceMotion, zoomFrame.width > 1, zoomFrame.height > 1 {
            local = zoomFrame.offsetBy(dx: -origin.x, dy: -origin.y)
        }
        return ZoomTransition(isExpanded: isExpanded, size: size, target: local, cardRadius: Self.cardRadius)
    }

    private func backgroundOpacity(height: CGFloat) -> Double {
        guard isExpanded else { return 0 }
        let pulled = max(dismissOffset.height, 0) / max(height * 0.5, 1)
        return Double(1 - min(pulled, 1) * 0.8)
    }

    private func dismissScale(height: CGFloat) -> CGFloat {
        let pulled = max(dismissOffset.height, 0) / max(height, 1)
        return max(0.6, 1 - pulled * 0.5)
    }

    // MARK: - Like

    private func like() {
        guard let story = player.currentStory, !viewModel.isLiked(storyId: story.id) else { return }

        viewModel.like(storyId: story.id)
        MimoFeedback.shared.impactLight()
        StoryAnalytics.like(storyId: story.id)
        likeBurst = (story.id, likeBurst.count + 1)
    }

    // MARK: - Drags

    private func handlePan(_ event: StoryPanEvent, size: CGSize) {
        let t = event.translation

        switch event.phase {
        case .began, .changed:
            if dragAxis == nil {
                guard abs(t.width) > 2 || abs(t.height) > 2 else { return }
                dragAxis = abs(t.width) > abs(t.height) ? .horizontal : (t.height > 0 ? .down : .up)
                player.pause(.dragging)
            }

            switch dragAxis {
            case .horizontal:
                let atEdge = (t.width > 0 && !player.hasPreviousStory) || (t.width < 0 && !player.hasNextStory)
                pagerOffset = atEdge ? t.width * 0.25 : t.width
            case .down:
                dismissOffset = CGSize(width: t.width * 0.5, height: max(t.height, 0))
            case .up:
                // A short lift, more resistant when there is no link to open.
                let resistance: CGFloat = canSwipeUp ? 0.35 : 0.15
                liftOffset = max(min(t.height, 0), -160) * resistance
            case nil:
                break
            }

        case .ended, .cancelled:
            let axis = dragAxis
            dragAxis = nil
            let cancelled = event.phase == .cancelled

            switch axis {
            case .horizontal:
                endHorizontal(t: t, velocity: event.velocity, width: size.width, cancelled: cancelled)
            case .down:
                if !cancelled, t.height > 120 || event.velocity.height > 900 {
                    player.resume(.dragging)
                    player.requestClose(.swipeDown)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { dismissOffset = .zero }
                    player.resume(.dragging)
                }
            case .up:
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { liftOffset = 0 }
                if !cancelled, t.height < -60 || event.velocity.height < -600, canSwipeUp {
                    player.openLink(via: "swipe_up")
                }
                player.resume(.dragging)
            case nil:
                player.resume(.dragging)
            }
        }
    }

    /// Swipe up opens the link of a LINK page that has one.
    private var canSwipeUp: Bool {
        guard let page = player.currentPage else { return false }
        return page.type == .link && page.linkURL != nil
    }

    private func endHorizontal(t: CGSize, velocity: CGSize, width: CGFloat, cancelled: Bool) {
        let goesForward = !cancelled && player.hasNextStory && (t.width < -width * 0.3 || velocity.width < -500)
        let goesBack = !cancelled && player.hasPreviousStory && (t.width > width * 0.3 || velocity.width > 500)

        withAnimation(.easeOut(duration: 0.3)) {
            if goesForward {
                player.goToStory(at: player.storyIndex + 1)
            } else if goesBack {
                player.goToStory(at: player.storyIndex - 1)
            }
            pagerOffset = 0
        }
        player.resume(.dragging)
    }
}

// MARK: - Card

/// One story: its page on screen (background, touch layer, foreground),
/// the progress bars, header and share / like bar.
struct StoryCardView: View {

    let story: Story
    let pageIndex: Int
    let isCurrent: Bool
    @ObservedObject var player: StoryPlayer
    @ObservedObject var viewModel: StoryViewModel
    let likeBurst: Int
    let onLike: () -> Void
    let onClose: () -> Void
    let onPan: (StoryPanEvent) -> Void

    var body: some View {
        let page = story.pages.indices.contains(pageIndex) ? story.pages[pageIndex] : nil
        let isLiked = viewModel.isLiked(storyId: story.id)
        let chromeOpacity: Double = isCurrent && player.isHolding ? 0 : 1

        ZStack {
            Color.alwaysBlack

            if let page {
                content(page: page, isLiked: isLiked)
            }

            if isCurrent && player.isMediaLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .alwaysWhite))
                    .allowsHitTesting(false)
            }

            StoryLikeBurst(trigger: likeBurst)

            VStack(spacing: 10) {
                StoryProgressBars(
                    pageCount: story.pages.count,
                    pageIndex: pageIndex,
                    isLive: isCurrent,
                    clock: player.clock
                )
                .padding(.horizontal, 12)
                .padding(.top, 10)

                StoryHeaderView(story: story, page: page, isCurrent: isCurrent, playback: player.playback, onClose: onClose)
                    .padding(.leading, 12)
                    .padding(.trailing, 4)

                Spacer()

                StoryBottomBar(
                    isLiked: isLiked,
                    onShare: player.share,
                    onLike: onLike
                )
            }
            .opacity(chromeOpacity)
            .animation(.easeInOut(duration: 0.2), value: chromeOpacity)
        }
    }

    @ViewBuilder
    private func content(page: StoryPage, isLiked: Bool) -> some View {
        ZStack {
            StoryBackgroundView(page: page, isCurrent: isCurrent, playback: player.playback) {
                player.backgroundDidLoad(storyId: story.id, pageNumber: page.number)
            }
            .allowsHitTesting(false)

            // Legibility of the white chrome on light pictures.
            VStack(spacing: 0) {
                LinearGradient(colors: [Color.alwaysBlack.opacity(0.45), .clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 140)
                Spacer()
                LinearGradient(colors: [.clear, Color.alwaysBlack.opacity(0.45)], startPoint: .top, endPoint: .bottom)
                    .frame(height: 220)
            }
            .allowsHitTesting(false)

            if isCurrent {
                StoryGestureLayer(
                    onTap: { x in x < 1.0 / 3.0 ? player.previous() : player.next() },
                    onHold: { holding in holding ? player.pause(.holding) : player.resume(.holding) },
                    onPan: onPan
                )
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(page.title)
        .accessibilityValue(page.content)
        .accessibilityAction(named: Text("MOBILE_global_next".localized(fallback: "Next"))) { player.next() }
        .accessibilityAction(named: Text("MOBILE_story_previous".localized(fallback: "Previous"))) { player.previous() }
        .accessibilityAction(named: Text(player.isPausedByRider
            ? "MOBILE_story_resume".localized(fallback: "Resume")
            : "MOBILE_story_pause".localized(fallback: "Pause"))) { player.toggleRiderPause() }
        .accessibilityAction(.escape) { onClose() }

        // The page's own controls sit above the touch layer.
        switch page.type {
        case .link:
            StoryActionView(page: page) { player.openLink(via: "button") }
        case .questionnaire:
            StorySurveyView(storyId: story.id, page: page, viewModel: viewModel)
        }
    }
}

// MARK: - Transitions

/// The cube between stories: a card beside the current one is turned 45° at
/// a full width away, hinged on the edge it shares with it. Under Reduce
/// Motion the cards stay put and cross-fade. One modifier chain either way,
/// so a card keeps its identity (and state) while it moves.
private struct CubeModifier: ViewModifier {

    let offset: CGFloat
    let width: CGFloat
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        let progress = width > 0 ? offset / width : 0

        content
            .rotation3DEffect(
                .degrees(reduceMotion ? 0 : Double(45 * progress)),
                axis: (x: 0, y: 1, z: 0),
                anchor: offset > 0 ? .leading : .trailing,
                perspective: 2.5
            )
            .offset(x: reduceMotion ? 0 : offset)
            .opacity(reduceMotion ? Double(1 - min(abs(progress), 1)) : 1)
    }
}

/// Grows the viewer out of the thumbnail and shrinks it back: the card is
/// scaled uniformly to the thumbnail's width, masked to the thumbnail's
/// shape and moved onto it. Without a thumbnail (off screen, Reduce Motion)
/// it fades and scales down a little instead.
private struct ZoomTransition: ViewModifier {

    let isExpanded: Bool
    let size: CGSize
    /// The thumbnail in the viewer's coordinates.
    let target: CGRect?
    let cardRadius: CGFloat

    func body(content: Content) -> some View {
        let width = max(size.width, 1)

        var scale: CGFloat = 1
        var maskHeight = size.height
        var radius = cardRadius
        var offset = CGSize.zero
        var opacity = 1.0

        if !isExpanded {
            if let target {
                scale = max(target.width / width, 0.01)
                maskHeight = min(target.height / scale, size.height)
                // The preview's own corner, before the scale shrinks it.
                radius = min(StoriesThumbView.previewCornerRadius / scale, min(width, maskHeight) / 2)
                offset = CGSize(width: target.midX - size.width / 2, height: target.midY - size.height / 2)
            } else {
                scale = 0.9
                opacity = 0
            }
        }

        return content
            .mask(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .frame(width: size.width, height: maskHeight)
            )
            .scaleEffect(scale)
            .offset(offset)
            .opacity(opacity)
    }
}

// MARK: - StoryChromeViews

//  The chrome of a story card: progress bars, header (logo, name, mute,
//  close), the share / like bar and the heart burst. All of it sits on the
//  story's picture or video, so it is drawn white with a soft shadow in both
//  appearances - the media, not the app theme, is its background.

// MARK: - Progress

/// One bar per page: earlier pages full, the current one following the
/// clock, later ones empty. No implicit animation - the clock already moves
/// at the screen's rate, so the bar is linear.
struct StoryProgressBars: View {

    let pageCount: Int
    let pageIndex: Int
    /// Follow the clock; false for a neighbouring story seen during a swipe.
    let isLive: Bool
    @ObservedObject var clock: StoryPageClock

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<pageCount, id: \.self) { index in
                GeometryReader { proxy in
                    Capsule()
                        .fill(Color.alwaysWhite.opacity(0.35))
                        .overlay(
                            Capsule()
                                .fill(Color.brandYellow)
                                .frame(width: proxy.size.width * fill(for: index)),
                            alignment: .leading
                        )
                }
            }
        }
        .frame(height: 3)
        .animation(nil, value: clock.progress)
        .accessibilityHidden(true)
    }

    private func fill(for index: Int) -> CGFloat {
        if index < pageIndex { return 1 }
        if index > pageIndex || !isLive { return 0 }
        return min(max(clock.progress, 0), 1)
    }
}

// MARK: - Header

struct StoryHeaderView: View {

    let story: Story
    let page: StoryPage?
    let isCurrent: Bool
    @ObservedObject var playback: StoryVideoPlayback
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            logo
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.alwaysWhite.opacity(0.6), lineWidth: 1))
                // Taps on the logo and name fall through to the card.
                .allowsHitTesting(false)

            Text(story.name)
                .font(.robotoMedium15)
                .foregroundColor(.alwaysWhite)
                .lineLimit(1)
                .shadow(color: .alwaysBlack.opacity(0.4), radius: 2, x: 0, y: 1)
                .allowsHitTesting(false)

            Spacer(minLength: 8)

            if isCurrent, let page, playback.videoPageNumber == page.number {
                Button(action: playback.toggleMute) {
                    Image(systemName: playback.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.alwaysWhite)
                        .shadow(color: .alwaysBlack.opacity(0.4), radius: 2, x: 0, y: 1)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(playback.isMuted
                    ? "MOBILE_story_unmute".localized(fallback: "Unmute")
                    : "MOBILE_story_mute".localized(fallback: "Mute"))
            }

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Self.closeTint(page?.closeButtonColor))
                    .shadow(color: .alwaysBlack.opacity(0.4), radius: 2, x: 0, y: 1)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            // 20 pt further in from the right edge than the header's own inset.
            .padding(.trailing, 20)
            .accessibilityLabel("MOBILE_global_done".localized(fallback: "Close"))
            .accessibilityIdentifier("storyClose")
        }
    }

    @ViewBuilder
    private var logo: some View {
        let first = story.pages.first
        if let url = first?.logo?.imageURL ?? (first?.backgroundKind == .image ? first?.background?.imageURL : nil) {
            KFImage(url)
                .resizable()
                .scaledToFill()
                .accessibilityHidden(true)
        } else {
            Circle()
                .fill(Color.alwaysWhite.opacity(0.25))
                .accessibilityHidden(true)
        }
    }

    /// The admin's colour when it is a plain hex ("#FFF", "#FFFFFF" or
    /// "#FFFFFFFF" as RRGGBBAA), white for anything else.
    static func closeTint(_ raw: String?) -> Color {
        guard var hex = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !hex.isEmpty else { return .alwaysWhite }
        if hex.hasPrefix("#") { hex.removeFirst() }

        guard [3, 6, 8].contains(hex.count),
              hex.allSatisfy({ $0.isHexDigit }),
              let value = UInt64(hex, radix: 16) else { return .alwaysWhite }

        let r, g, b, a: Double
        switch hex.count {
        case 3:
            r = Double((value >> 8) & 0xF) / 15
            g = Double((value >> 4) & 0xF) / 15
            b = Double(value & 0xF) / 15
            a = 1
        case 6:
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
            a = 1
        default:
            r = Double((value >> 24) & 0xFF) / 255
            g = Double((value >> 16) & 0xFF) / 255
            b = Double((value >> 8) & 0xFF) / 255
            a = Double(value & 0xFF) / 255
        }

        // A fully transparent tint would hide the only way out.
        return Color(.sRGB, red: r, green: g, blue: b, opacity: max(a, 0.6))
    }
}

// MARK: - Share and like

struct StoryBottomBar: View {

    let isLiked: Bool
    let onShare: () -> Void
    let onLike: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var likePop = false

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.alwaysWhite.opacity(0.2))
                .frame(height: 1)
                .padding(.bottom, 16)
                .padding(.horizontal, 20)
                .accessibilityHidden(true)

            HStack(spacing: 10) {
                Spacer()

                Button(action: onShare) {
                    circle(Image(systemName: "arrowshape.turn.up.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.alwaysWhite))
                }
                .accessibilityLabel("MOBILE_story_share".localized(fallback: "Share"))
                .accessibilityIdentifier("storyShare")

                Button(action: onLike) {
                    circle(Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isLiked ? Color.brandYellow : .alwaysWhite)
                        .scaleEffect(likePop ? 1.3 : 1))
                }
                // No unlike on the backend: a liked story stays liked.
                .disabled(isLiked)
                .accessibilityLabel(isLiked
                    ? "MOBILE_story_liked".localized(fallback: "Liked")
                    : "MOBILE_story_like".localized(fallback: "Like"))
                .accessibilityIdentifier("storyLike")
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .onChange(of: isLiked) { liked in
            guard liked, !reduceMotion else { return }
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) { likePop = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { likePop = false }
            }
        }
    }

    private func circle<Content: View>(_ content: Content) -> some View {
        ZStack {
            Color.alwaysWhite.opacity(0.1)
            content
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
    }
}

// MARK: - Heart burst

/// A big heart that pops in the middle of the card when the story is liked.
struct StoryLikeBurst: View {

    /// Bumped by the viewer on every like.
    let trigger: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scale: CGFloat = 0.3
    @State private var opacity: Double = 0

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 96, weight: .regular))
            .foregroundColor(.brandYellow)
            .shadow(color: .alwaysBlack.opacity(0.25), radius: 8, x: 0, y: 2)
            .scaleEffect(scale)
            .opacity(opacity)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .onChange(of: trigger) { value in
                // 0 is "not this story"; only a new like plays the burst.
                if value > 0 { burst() }
            }
    }

    private func burst() {
        scale = reduceMotion ? 1 : 0.3
        opacity = 0

        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.3, dampingFraction: 0.55)) {
            scale = 1
            opacity = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeIn(duration: 0.25)) {
                opacity = 0
                if !reduceMotion { scale = 1.15 }
            }
        }
    }
}

// MARK: - StoryGestureLayer

//  The touch surface of a story card, over its full height. It sits between
//  the background and the page's controls, so the CTA, options and buttons
//  keep their own taps and everything else lands here:
//
//  - tap: the caller gets the tap's position (left third = previous page),
//    on touch-up with no double-tap wait, so quick taps skip pages at once
//    (stories like via the heart button only, as on Instagram / Telegram);
//  - hold: pause and hide the chrome until released;
//  - pan: horizontal (between stories), down (close), up (open the link).
//
//  UIKit recognizers rather than SwiftUI gestures: iOS 15 SwiftUI has no drag
//  velocity, and tap / hold / pan need explicit failure requirements to stay
//  apart.

struct StoryPanEvent {
    enum Phase { case began, changed, ended, cancelled }

    let phase: Phase
    /// In window coordinates: the card itself moves with the finger.
    let translation: CGSize
    let velocity: CGSize
}

struct StoryGestureLayer: UIViewRepresentable {

    /// The tap's x as a fraction of the layer's width, 0...1.
    var onTap: (CGFloat) -> Void
    var onHold: (Bool) -> Void
    var onPan: (StoryPanEvent) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        // The card's accessibility element carries the actions instead.
        view.isAccessibilityElement = false
        view.accessibilityElementsHidden = true

        let coordinator = context.coordinator

        // Long enough that an ordinary (slightly slow) tap stays a tap.
        let hold = UILongPressGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleHold(_:)))
        hold.minimumPressDuration = 0.3
        hold.delegate = coordinator

        let tap = UITapGestureRecognizer(target: coordinator, action: #selector(Coordinator.handleTap(_:)))
        tap.require(toFail: hold)

        let pan = UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        pan.delegate = coordinator

        [hold, tap, pan].forEach(view.addGestureRecognizer)

        coordinator.hold = hold
        coordinator.pan = pan

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        // A card that leaves the screen mid-hold must not leave the story
        // paused.
        guard coordinator.isHolding else { return }
        coordinator.isHolding = false

        // Not during the view update that removes the layer.
        let onHold = coordinator.parent.onHold
        DispatchQueue.main.async { onHold(false) }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        var parent: StoryGestureLayer
        weak var hold: UILongPressGestureRecognizer?
        weak var pan: UIPanGestureRecognizer?
        var isHolding = false

        init(parent: StoryGestureLayer) {
            self.parent = parent
        }

        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view, view.bounds.width > 0 else { return }
            parent.onTap(recognizer.location(in: view).x / view.bounds.width)
        }

        @objc func handleHold(_ recognizer: UILongPressGestureRecognizer) {
            switch recognizer.state {
            case .began:
                isHolding = true
                parent.onHold(true)
            case .ended, .cancelled, .failed:
                guard isHolding else { return }
                isHolding = false
                parent.onHold(false)
            default:
                break
            }
        }

        @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
            let space = recognizer.view?.window ?? recognizer.view
            let translation = recognizer.translation(in: space)
            let velocity = recognizer.velocity(in: space)

            let phase: StoryPanEvent.Phase
            switch recognizer.state {
            case .began: phase = .began
            case .changed: phase = .changed
            case .ended: phase = .ended
            case .cancelled, .failed: phase = .cancelled
            default: return
            }

            parent.onPan(StoryPanEvent(
                phase: phase,
                translation: CGSize(width: translation.x, height: translation.y),
                velocity: CGSize(width: velocity.x, height: velocity.y)
            ))
        }

        // Hold and pan together: a held story can still be swiped down.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            (gestureRecognizer === hold && other === pan) || (gestureRecognizer === pan && other === hold)
        }
    }
}

// MARK: - StoryViewerPresenter

//  Puts the stories viewer on screen. iOS 15 cannot match geometry across a
//  `fullScreenCover`, so the viewer is a hosting controller presented
//  `.overFullScreen` without UIKit's animation, on a clear background: the
//  SwiftUI view runs the zoom out of the thumbnail itself, and back into it
//  before the controller is taken away.

enum StoryViewerPresenter {

    private static weak var presented: StoryViewerHostingController?

    /// stories: already in strip order. thumbnailFrame: global frame of a story's thumbnail (nil when off screen), asked on open and on close.
    static func present(viewModel: StoryViewModel, stories: [Story], startStoryId: String, thumbnailFrame: @escaping (String) -> CGRect?) {
        // A second tap while the viewer is opening must not stack another one.
        guard presented == nil else { return }

        let playable = stories.filter { !$0.pages.isEmpty }
        guard let startIndex = playable.firstIndex(where: { $0.id == startStoryId }),
              let presenter = UIApplication.shared.topMostViewController() else { return }

        viewModel.currentStory = startStoryId

        let player = StoryPlayer(stories: playable, startIndex: startIndex)
        let controller = StoryViewerHostingController(player: player, viewModel: viewModel, thumbnailFrame: thumbnailFrame)

        presented = controller
        presenter.present(controller, animated: false)
    }
}

final class StoryViewerHostingController: UIHostingController<AnyView> {

    private let player: StoryPlayer

    init(player: StoryPlayer, viewModel: StoryViewModel, thumbnailFrame: @escaping (String) -> CGRect?) {
        self.player = player
        super.init(rootView: AnyView(EmptyView()))

        rootView = AnyView(
            StoryViewerView(
                player: player,
                viewModel: viewModel,
                thumbnailFrame: thumbnailFrame,
                onFinish: { [weak self] in self?.finish() }
            )
        )

        player.hostController = self
        modalPresentationStyle = .overFullScreen
        modalPresentationCapturesStatusBarAppearance = true
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.accessibilityViewIsModal = true
    }

    override var prefersStatusBarHidden: Bool { true }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { .fade }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }

    private func finish() {
        player.stop()
        dismiss(animated: false)
    }
}
