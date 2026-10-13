//
//  LoadingRectangle.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 22.12.23.
//
//  The old `LoadingRectangle` progress bar is gone (the viewer draws its own
//  bars, `StoryProgressBars`). The Impulse project is not folder-synchronised,
//  so this file now holds the media side of a story page as marked sections:
//  `StoryBackgroundView` (the picture or video that fills a page) and
//  `StoryVideoPlayback` (the one AVPlayer of an open viewer).
//

import SwiftUI
import AVFoundation
import Combine
import Kingfisher

// MARK: - StoryBackgroundView

//  The background of a story page: the picture, or the video when the page's
//  file is one. Fills the page either way. The picture reports when it is on
//  screen (or failed - a page must never wait forever), which is when the
//  page's clock starts.

struct StoryBackgroundView: View {

    let page: StoryPage
    /// Only the story on screen plays video; a neighbour seen during a swipe
    /// shows black for its video page (page numbers repeat across stories).
    let isCurrent: Bool
    @ObservedObject var playback: StoryVideoPlayback
    /// The picture is displayed, or could not be loaded.
    var onLoaded: () -> Void = {}

    var body: some View {
        if isCurrent && playback.videoPageNumber == page.number {
            ZStack {
                Color.alwaysBlack

                StoryVideoLayerView(player: playback.player)
            }
        } else if page.backgroundKind == .video {
            // About to be handed to the player; a video is not a picture to load.
            Color.alwaysBlack
        } else {
            // The picture fills the page but never sizes it: a picture with
            // another shape than the screen used to grow the whole page and
            // push the bars, header and buttons out of place.
            Color.alwaysBlack
                .overlay(
                    KFImage(page.background?.imageURL)
                        .onSuccess { _ in report() }
                        .onFailure { _ in report() }
                        .loadDiskFileSynchronously()
                        .fade(duration: 0.15)
                        .resizable()
                        .scaledToFill()
                )
                .clipped()
        }
    }

    /// Kingfisher may answer from the memory cache while the view is being
    /// built; the player is told on the next turn, never during an update.
    private func report() {
        DispatchQueue.main.async(execute: onLoaded)
    }
}

/// `AVPlayerLayer` behind a SwiftUI view, filling it the way the pictures do.
private struct StoryVideoLayerView: UIViewRepresentable {

    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: PlayerView, context: Context) {
        if uiView.playerLayer.player !== player {
            uiView.playerLayer.player = player
        }
    }

    final class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }

        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }
}

// MARK: - StoryVideoPlayback

//  Plays the page of a story whose background is a video. One per open
//  viewer, owned by `StoryPlayer`: the player tells it which page is up, reads
//  how far the video has got to drive the progress bar (a video page lasts as
//  long as its video), and pauses it with the rest of the story.
//
//  Audio: `.ambient` + `.mixWithOthers`, like `MimoFeedback` - a story video
//  follows the silent switch and never stops the rider's music. The mute
//  button's choice lasts for the app session.

/// What a page's background file is. The stories contract describes the
/// background as a `FileData` and nothing more (accounts docs/mobile-api.md,
/// GET /api/stories), so the kind is read from what the file
/// says about itself: its `type`, then its address, then - when neither
/// tells - the content type the server answers with.
enum StoryBackgroundKind {
    case image
    case video
    case undetermined
}

extension StoryPage {

    private static let videoExtensions: Set<String> = ["mp4", "mov", "m4v"]
    private static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "webp", "gif", "heic", "heif", "bmp"]

    var backgroundKind: StoryBackgroundKind {
        guard let url = background?.imageURL else { return .image }

        if let type = backgroundType?.lowercased(), !type.isEmpty {
            if type.contains("video") || Self.videoExtensions.contains(type) { return .video }
            if type.contains("image") || Self.imageExtensions.contains(type) { return .image }
        }

        let pathExtension = url.pathExtension.lowercased()

        if Self.videoExtensions.contains(pathExtension) { return .video }
        if Self.imageExtensions.contains(pathExtension) { return .image }

        return .undetermined
    }
}

final class StoryVideoPlayback: ObservableObject {

    let player = AVPlayer()

    /// The page whose background is being played as a video, nil while the
    /// page on screen shows a picture.
    @Published private(set) var videoPageNumber: Int?
    /// False until the first frame can be shown.
    @Published private(set) var isReady = false
    /// Sound off. Shared by every viewer opened in this app session.
    @Published private(set) var isMuted = StoryVideoPlayback.isMutedForSession

    private static var isMutedForSession = false
    private static var didConfigureAudioSession = false

    /// Assets created ahead of time for the pages about to come, so their
    /// video starts without the first round trip. Main thread only.
    private static var preparedAssets: [URL: AVURLAsset] = [:]
    private static var preparedOrder: [URL] = []
    private static let preparedLimit = 6

    private var shownPageNumber: Int?
    private var didFinish = false
    private var wantsToPlay = false
    private var statusObservation: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private var probe: URLSessionDataTask?

    /// Answers of the content-type check, so a page is asked about once.
    private static var probedKinds: [URL: Bool] = [:]

    deinit {
        probe?.cancel()
        statusObservation?.invalidate()
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        player.pause()
    }

    // MARK: - Which page

    /// Call whenever the page on screen changes. Showing the same page again
    /// changes nothing, so it is safe to call on every tick.
    func show(_ page: StoryPage?) {
        guard page?.number != shownPageNumber else { return }

        stop()
        shownPageNumber = page?.number

        guard let page, let url = page.background?.imageURL else { return }

        switch page.backgroundKind {
        case .image:
            break
        case .video:
            start(url, pageNumber: page.number)
        case .undetermined:
            resolve(url, pageNumber: page.number)
        }
    }

    /// Forgets the page, so the next `show` starts it from the beginning.
    func reset() {
        stop()
        shownPageNumber = nil
    }

    private func stop() {
        probe?.cancel()
        probe = nil
        statusObservation?.invalidate()
        statusObservation = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil

        player.pause()
        player.replaceCurrentItem(with: nil)

        didFinish = false
        if isReady { isReady = false }
        if videoPageNumber != nil { videoPageNumber = nil }
    }

    private func resolve(_ url: URL, pageNumber: Int) {
        if let isVideo = Self.probedKinds[url] {
            if isVideo { start(url, pageNumber: pageNumber) }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, _ in
            let contentType = (response as? HTTPURLResponse)?.value(forHTTPHeaderField: "Content-Type")?.lowercased()

            DispatchQueue.main.async {
                guard let contentType else { return }

                let isVideo = contentType.hasPrefix("video/")
                Self.probedKinds[url] = isVideo

                guard let self, isVideo, self.shownPageNumber == pageNumber else { return }

                self.start(url, pageNumber: pageNumber)
            }
        }

        probe = task
        task.resume()
    }

    private func start(_ url: URL, pageNumber: Int) {
        Self.configureAudioSessionIfNeeded()

        let item = AVPlayerItem(asset: Self.preparedAssets[url] ?? AVURLAsset(url: url))
        player.isMuted = isMuted

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self, self.player.currentItem === item else { return }

                switch item.status {
                case .readyToPlay:
                    self.isReady = true
                case .failed:
                    // Not playable after all: the page falls back to the
                    // picture and to the picture's timing.
                    self.stop()
                default:
                    break
                }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.didFinish = true
        }

        videoPageNumber = pageNumber
        player.replaceCurrentItem(with: item)

        if wantsToPlay { player.play() }
    }

    // MARK: - Preparing ahead

    /// Starts loading a video that is about to be shown (the next page, or
    /// the next story's first page), so `start` finds it ready.
    static func preload(_ url: URL) {
        guard preparedAssets[url] == nil else { return }

        let asset = AVURLAsset(url: url)
        asset.loadValuesAsynchronously(forKeys: ["playable"]) {}

        preparedAssets[url] = asset
        preparedOrder.append(url)

        while preparedOrder.count > preparedLimit {
            let oldest = preparedOrder.removeFirst()
            preparedAssets[oldest] = nil
        }
    }

    private static func configureAudioSessionIfNeeded() {
        guard !didConfigureAudioSession else { return }
        didConfigureAudioSession = true

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, options: [.mixWithOthers])
        try? session.setActive(true, options: [])
    }

    // MARK: - Sound

    func toggleMute() {
        isMuted.toggle()
        Self.isMutedForSession = isMuted
        player.isMuted = isMuted
    }

    // MARK: - Transport

    func play() {
        wantsToPlay = true

        guard player.currentItem != nil, !didFinish, player.rate == 0 else { return }

        player.play()
    }

    func pause() {
        wantsToPlay = false

        guard player.rate != 0 else { return }

        player.pause()
    }

    // MARK: - Progress

    /// How much of the page has passed, 0...1, while a video is on screen;
    /// nil for a picture, which keeps its own clock. A video that is still
    /// loading holds the page at its start.
    var progress: CGFloat? {
        guard videoPageNumber != nil, let item = player.currentItem else { return nil }

        if didFinish { return 1 }

        let duration = item.duration.seconds
        guard isReady, duration.isFinite, duration > 0 else { return 0 }

        return CGFloat(min(max(player.currentTime().seconds / duration, 0), 1))
    }
}
