//
//  StoryViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 26.12.23.
//
//  The stories feed and what the rider did with it: likes (one way - the
//  backend has no unlike) and questionnaire answers, kept per story AND page.
//  Playback state lives in `StoryPlayer`, which exists only while the viewer
//  is open.
//
//  The Impulse project is not folder-synchronised, so the viewer's companions
//  live in this file as marked sections rather than in files of their own:
//  `StoryPlayer` (the viewer's one clock), `StorySeenStore` (watched pages on
//  the device) and `StoryAnalytics` (Firebase events).
//

import Foundation
import UIKit
import SwiftUI
import Combine
import Kingfisher
import FirebaseAnalytics

// MARK: - StoryViewModel

class StoryViewModel: MimoBaseViewModel, ObservableObject {

    private var cancellables = Set<AnyCancellable>()

    private let worker: StoryWorkerProtocol

    /// Chosen options per questionnaire page, keyed by `optionsKey(storyId:pageNumber:)`.
    /// Starts from each page's `selectedOptions` as the backend sent them.
    @Published private(set) var selectedOptions: [String: [String]] = [:]
    @Published var likedStories: [String] = []

    var stories: CurrentValueSubject<[Story], Never> = .init([])
    /// Kept for the call sites that still read them; the viewer itself is
    /// presented by `StoryViewerPresenter`, not by this flag.
    @Published var showStory: Bool = false
    @Published var currentStory: String = ""

    init(worker: StoryWorkerProtocol) {
        self.worker = worker
    }

    func getStories() {
        worker.getStories()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handle(error)
                }
            } receiveValue: { [weak self] stories in
                guard let self else { return }

                var options: [String: [String]] = [:]
                for story in stories {
                    for page in story.pages {
                        options[Self.optionsKey(storyId: story.id, pageNumber: page.number)] = page.selectedOptions
                    }
                }

                self.likedStories = stories.filter({ $0.like }).map({ $0.id })
                self.selectedOptions = options
                self.stories.send(stories)
            }
            .store(in: &cancellables)
    }

    // MARK: - Like

    /// Likes a story. Shown at once and kept; rolled back only when the
    /// request fails. There is no unlike on the backend, so a liked story
    /// stays liked.
    func like(storyId: String) {
        guard !storyId.isEmpty, !likedStories.contains(storyId) else { return }

        likedStories.append(storyId)

        worker.like(id: storyId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.likedStories.removeAll(where: { $0 == storyId })
                    self?.handle(error)
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    func like() {
        like(storyId: currentStory)
    }

    func isLiked(storyId: String) -> Bool {
        likedStories.contains(storyId)
    }

    func isLiked() -> Bool {
        isLiked(storyId: currentStory)
    }

    // MARK: - Questionnaire

    static func optionsKey(storyId: String, pageNumber: Int) -> String {
        "\(storyId)#\(pageNumber)"
    }

    func selectedOptions(storyId: String, pageNumber: Int) -> [String] {
        selectedOptions[Self.optionsKey(storyId: storyId, pageNumber: pageNumber)] ?? []
    }

    func isOptionSelected(_ option: String, storyId: String, pageNumber: Int) -> Bool {
        selectedOptions(storyId: storyId, pageNumber: pageNumber).contains(option)
    }

    /// Toggles an answer of one page: a chosen option is deselected by
    /// tapping it again, another one is added (the contract takes "selected
    /// answer(s)"). The page's whole list is sent each time; the change shows
    /// at once and is rolled back if the request fails.
    ///
    /// - Returns: true when the option is now selected.
    @discardableResult
    func toggle(option: String, storyId: String, pageNumber: Int) -> Bool {
        let key = Self.optionsKey(storyId: storyId, pageNumber: pageNumber)
        let previous = selectedOptions[key] ?? []
        var options = previous

        if options.contains(option) {
            options.removeAll(where: { $0 == option })
        } else {
            options.append(option)
        }

        selectedOptions[key] = options

        worker.setOptions(id: storyId, pageNumber: pageNumber, options: options)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self, case .failure(let error) = completion else { return }

                // Roll back only if nothing newer was chosen in the meantime.
                if self.selectedOptions[key] == options {
                    self.selectedOptions[key] = previous
                }
                self.handle(error)
            } receiveValue: { _ in }
            .store(in: &cancellables)

        return options.contains(option)
    }
}

// MARK: - StoryPlayer

//  The one clock of an open stories viewer. It owns which story and page are
//  on screen, how far the page has got (0...1), and every reason the story is
//  paused. Only the visible story ticks: a single CADisplayLink advances the
//  page by elapsed time, so the bar moves linearly at the screen's rate, and
//  stops whenever anything pauses the story.
//
//  A picture page lasts `imagePageDuration` and starts counting only once its
//  picture is displayed; a video page lasts as long as its video
//  (`StoryVideoPlayback` is its clock) and waits for the video to be ready.
//
//  The viewer (`StoryViewerView`) draws it; `StoryViewerPresenter` creates it.

/// Progress of the page on screen, published on its own so that only the
/// progress bars redraw at the screen's rate - not the whole viewer.
final class StoryPageClock: ObservableObject {
    @Published var progress: CGFloat = 0
}

final class StoryPlayer: ObservableObject {

    enum PauseReason: Hashable {
        /// The rider holds a finger on the card.
        case holding
        /// The share sheet is up.
        case sharing
        /// The app is not active.
        case background
        /// A link opened from the page is in front.
        case linkOpened
        /// The page's picture or video is not on screen yet.
        case mediaLoading
        /// A horizontal / vertical drag is in progress.
        case dragging
        /// The viewer is closing.
        case dismissing
        /// The viewer is zooming in.
        case opening
        /// Paused from the VoiceOver "Pause" action.
        case accessibility
    }

    enum CloseReason: String {
        case closeButton = "close_button"
        case swipeDown = "swipe_down"
        case finished = "finished"
    }

    static let imagePageDuration: TimeInterval = 5
    /// A page shown for this long counts as seen.
    static let seenAfter: TimeInterval = 1
    /// A picture that neither loads nor fails within this time starts the
    /// clock anyway.
    static let mediaTimeout: TimeInterval = 10

    /// The stories as the strip ordered them when the viewer opened. Not
    /// re-ordered while the viewer is open.
    let stories: [Story]
    let clock = StoryPageClock()
    let playback = StoryVideoPlayback()

    @Published private(set) var storyIndex: Int
    @Published private(set) var pageIndex: Int
    @Published private(set) var pauseReasons: Set<PauseReason> = [.opening]
    /// Set once; the viewer animates out and then dismisses.
    @Published private(set) var closeRequest: CloseReason?

    /// The controller the viewer is presented in; the share sheet goes on it.
    weak var hostController: UIViewController?

    private let seenStore: StorySeenStore
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private var visibleTime: TimeInterval = 0
    private var didMarkSeen = false
    private var imageLoaded = false
    /// The media took longer than `mediaTimeout`: the page runs on the
    /// picture clock whatever it is waiting for.
    private var mediaForcedReady = false
    private var trackedVideoPage: Int?
    private var mediaTimeoutWork: DispatchWorkItem?
    private var prefetcher: ImagePrefetcher?
    private var cancellables = Set<AnyCancellable>()
    private var isStarted = false
    /// The story just left and the page it was on, so its card keeps that
    /// page while it turns away instead of jumping to its first page.
    private var outgoing: (index: Int, page: Int)?
    private var outgoingReset: DispatchWorkItem?

    init(stories: [Story], startIndex: Int, seenStore: StorySeenStore = .shared) {
        self.stories = stories
        self.seenStore = seenStore

        let index = stories.indices.contains(startIndex) ? startIndex : 0
        let story = stories.indices.contains(index) ? stories[index] : nil
        self.storyIndex = index
        self.pageIndex = Self.clamp(story.map { seenStore.firstUnseenPageIndex(in: $0) } ?? 0, in: story)
    }

    deinit {
        displayLink?.invalidate()
        mediaTimeoutWork?.cancel()
        outgoingReset?.cancel()
        prefetcher?.stop()
    }

    // MARK: - What is on screen

    var currentStory: Story? {
        stories.indices.contains(storyIndex) ? stories[storyIndex] : nil
    }

    var currentPage: StoryPage? {
        guard let story = currentStory, story.pages.indices.contains(pageIndex) else { return nil }
        return story.pages[pageIndex]
    }

    var isHolding: Bool { pauseReasons.contains(.holding) }
    var isMediaLoading: Bool { pauseReasons.contains(.mediaLoading) }
    var isPausedByRider: Bool { pauseReasons.contains(.accessibility) }

    var hasPreviousStory: Bool { storyIndex > 0 }
    var hasNextStory: Bool { storyIndex < stories.count - 1 }

    /// The page a story shows when it is not the current one: the next
    /// story opens at its first unseen page, an earlier one at its first.
    func displayedPageIndex(forStoryAt index: Int) -> Int {
        guard stories.indices.contains(index) else { return 0 }
        if index == storyIndex { return pageIndex }
        if let outgoing, outgoing.index == index { return outgoing.page }
        if index > storyIndex { return Self.clamp(seenStore.firstUnseenPageIndex(in: stories[index]), in: stories[index]) }
        return 0
    }

    // MARK: - Life cycle

    /// The viewer appeared: start the first page and the clock.
    func start() {
        guard !isStarted else { return }
        isStarted = true

        Publishers.CombineLatest(playback.$videoPageNumber, playback.$isReady)
            .sink { [weak self] videoPage, isReady in
                self?.videoStateChanged(videoPage: videoPage, isReady: isReady)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in self?.pause(.background) }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                // Back from the browser a CTA opened, or from Control Center.
                self?.resume([.background, .linkOpened])
            }
            .store(in: &cancellables)

        let link = CADisplayLink(target: DisplayLinkProxy(self), selector: #selector(DisplayLinkProxy.tick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.isPaused = true
        link.add(to: .main, forMode: .common)
        displayLink = link

        if let story = currentStory {
            StoryAnalytics.open(storyId: story.id, source: "thumbnail")
        }
        enterPage()
    }

    /// The viewer is gone: stop everything it was playing.
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        mediaTimeoutWork?.cancel()
        prefetcher?.stop()
        cancellables.removeAll()
        playback.reset()
    }

    // MARK: - Pausing

    func pause(_ reason: PauseReason) {
        guard !pauseReasons.contains(reason) else { return }
        pauseReasons.insert(reason)
        updateRunning()
    }

    func resume(_ reason: PauseReason) {
        resume([reason])
    }

    func resume(_ reasons: Set<PauseReason>) {
        guard !pauseReasons.isDisjoint(with: reasons) else { return }
        pauseReasons.subtract(reasons)
        updateRunning()
    }

    func toggleRiderPause() {
        if isPausedByRider { resume(.accessibility) } else { pause(.accessibility) }
    }

    private func updateRunning() {
        let running = pauseReasons.isEmpty && closeRequest == nil

        if running, displayLink?.isPaused == true {
            // Elapsed time is counted from the next frame, not from when the
            // story was paused.
            lastTimestamp = nil
        }
        displayLink?.isPaused = !running

        // A loading video must be allowed to start on its own once ready, so
        // only the other reasons hold it.
        if pauseReasons.subtracting([.mediaLoading]).isEmpty && closeRequest == nil {
            playback.play()
        } else {
            playback.pause()
        }
    }

    // MARK: - Clock

    fileprivate func tick(_ link: CADisplayLink) {
        guard let last = lastTimestamp else {
            lastTimestamp = link.timestamp
            return
        }
        // A long gap (a hitch, a breakpoint) must not skip the page.
        let elapsed = min(max(link.timestamp - last, 0), 0.1)
        lastTimestamp = link.timestamp

        guard pauseReasons.isEmpty, currentPage != nil else { return }

        visibleTime += elapsed
        if !didMarkSeen, visibleTime >= Self.seenAfter {
            markCurrentPageSeen()
        }

        let progress: CGFloat
        if let videoProgress = playback.progress, playback.isReady || videoProgress >= 1 || !mediaForcedReady {
            progress = videoProgress
        } else {
            progress = clock.progress + CGFloat(elapsed / Self.imagePageDuration)
        }

        if progress >= 1 {
            clock.progress = 1
            markCurrentPageSeen()
            next()
        } else if abs(progress - clock.progress) > 0.0005 {
            clock.progress = progress
        }
    }

    private func markCurrentPageSeen() {
        guard let story = currentStory, let page = currentPage else { return }
        didMarkSeen = true
        seenStore.markSeen(storyId: story.id, pageNumber: page.number)
    }

    // MARK: - Navigation

    /// Next page; after the last page the next story, after the last story
    /// the viewer closes.
    func next() {
        guard closeRequest == nil, let story = currentStory else { return }

        if pageIndex < story.pages.count - 1 {
            pageIndex += 1
            enterPage()
            return
        }

        StoryAnalytics.complete(storyId: story.id)

        if hasNextStory {
            withAnimation(Self.storyChangeAnimation) {
                goToStory(at: storyIndex + 1)
            }
        } else {
            requestClose(.finished)
        }
    }

    /// Previous page; on the first page the previous story from its start,
    /// or the first page again on the first story.
    func previous() {
        guard closeRequest == nil else { return }

        if pageIndex > 0 {
            pageIndex -= 1
            enterPage()
        } else if hasPreviousStory {
            withAnimation(Self.storyChangeAnimation) {
                goToStory(at: storyIndex - 1)
            }
        } else {
            enterPage()
        }
    }

    /// Moves to another story: forward at its first unseen page, backward at
    /// its first page. The caller decides the animation.
    func goToStory(at index: Int) {
        guard stories.indices.contains(index), index != storyIndex else { return }

        let page = displayedPageIndex(forStoryAt: index)
        outgoing = (storyIndex, pageIndex)
        storyIndex = index
        pageIndex = page

        outgoingReset?.cancel()
        let reset = DispatchWorkItem { [weak self] in self?.outgoing = nil }
        outgoingReset = reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: reset)

        StoryAnalytics.open(storyId: stories[index].id, source: "auto_advance")
        enterPage()
    }

    static var storyChangeAnimation: Animation {
        UIAccessibility.isReduceMotionEnabled ? .easeInOut(duration: 0.25) : .easeInOut(duration: 0.35)
    }

    // MARK: - Closing

    func requestClose(_ reason: CloseReason) {
        guard closeRequest == nil else { return }

        if let story = currentStory {
            StoryAnalytics.close(storyId: story.id, pageNumber: currentPage?.number ?? 0, reason: reason.rawValue)
        }

        pauseReasons.insert(.dismissing)
        closeRequest = reason
        updateRunning()
    }

    // MARK: - Page set-up

    private func enterPage() {
        mediaTimeoutWork?.cancel()
        clock.progress = 0
        visibleTime = 0
        didMarkSeen = false
        lastTimestamp = nil

        guard let story = currentStory, let page = currentPage else { return }

        // A picture already in the cache (prefetched, or the same file as the
        // previous page) is on screen at once: its clock starts right away
        // instead of waiting for a load callback that may never come again.
        if let url = page.background?.imageURL, page.backgroundKind != .video {
            imageLoaded = KingfisherManager.shared.cache.isCached(forKey: url.cacheKey)
        } else {
            imageLoaded = page.background?.imageURL == nil
        }
        mediaForcedReady = false
        trackedVideoPage = nil

        // Always from the start, also when the same page is shown again.
        playback.reset()
        playback.show(page)
        refreshMediaState(videoPage: playback.videoPageNumber, isReady: playback.isReady)

        let work = DispatchWorkItem { [weak self] in self?.forceMediaReady() }
        mediaTimeoutWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.mediaTimeout, execute: work)

        StoryAnalytics.pageView(
            storyId: story.id,
            pageNumber: page.number,
            pageType: page.type.rawValue,
            background: page.backgroundKind == .video ? "video" : "image"
        )

        prefetchAhead()
        updateRunning()
    }

    /// Called by the background picture of a page once it is displayed or
    /// failed. Ignored unless it is the page on screen.
    func backgroundDidLoad(storyId: String, pageNumber: Int) {
        guard currentStory?.id == storyId, currentPage?.number == pageNumber else { return }
        markImageLoaded()
    }

    private func markImageLoaded() {
        guard !imageLoaded else { return }
        imageLoaded = true
        refreshMediaState(videoPage: playback.videoPageNumber, isReady: playback.isReady)
    }

    private func forceMediaReady() {
        mediaForcedReady = true
        refreshMediaState(videoPage: playback.videoPageNumber, isReady: playback.isReady)
    }

    /// `@Published` delivers before the property changes, so the new values
    /// arrive as arguments rather than being read back from `playback`.
    private func videoStateChanged(videoPage: Int?, isReady: Bool) {
        guard let page = currentPage else { return }

        if videoPage == page.number, trackedVideoPage != page.number {
            // A page whose kind was only found out by asking the server:
            // it started on the picture clock, the video restarts it.
            trackedVideoPage = page.number
            clock.progress = 0
            visibleTime = 0
            lastTimestamp = nil
        }

        refreshMediaState(videoPage: videoPage, isReady: isReady)
    }

    private func refreshMediaState(videoPage: Int?, isReady: Bool) {
        guard let page = currentPage else { return }

        let loading: Bool
        if mediaForcedReady {
            loading = false
        } else if videoPage == page.number {
            loading = !isReady
        } else if page.backgroundKind == .video {
            // The video could not be played: the page keeps the picture
            // timing over black instead of waiting for ever.
            loading = false
        } else {
            loading = !imageLoaded
        }

        if loading {
            pause(.mediaLoading)
        } else {
            resume(.mediaLoading)
        }
    }

    // MARK: - Preloading

    /// The next page of this story and the page the next story opens at.
    private func prefetchAhead() {
        var pages: [StoryPage] = []

        if let story = currentStory, story.pages.indices.contains(pageIndex + 1) {
            pages.append(story.pages[pageIndex + 1])
        }

        if hasNextStory {
            let nextStory = stories[storyIndex + 1]
            let index = displayedPageIndex(forStoryAt: storyIndex + 1)
            if nextStory.pages.indices.contains(index) { pages.append(nextStory.pages[index]) }
        }

        var urls: [URL] = []
        for page in pages {
            if let logo = page.logo?.imageURL { urls.append(logo) }

            guard let background = page.background?.imageURL else { continue }
            switch page.backgroundKind {
            case .image:
                urls.append(background)
            case .video:
                StoryVideoPlayback.preload(background)
            case .undetermined:
                // Could be a video: not worth downloading as a picture.
                break
            }
        }

        if hasNextStory, let headerLogo = stories[storyIndex + 1].pages.first?.logo?.imageURL {
            urls.append(headerLogo)
        }

        prefetcher?.stop()
        guard !urls.isEmpty else { prefetcher = nil; return }

        let prefetcher = ImagePrefetcher(urls: urls)
        prefetcher.start()
        self.prefetcher = prefetcher
    }

    // MARK: - Actions

    /// Opens the page's link (CTA button or swipe up). The story waits until
    /// the app is active again.
    func openLink(via: String) {
        guard let story = currentStory, let page = currentPage, let url = page.linkURL else { return }

        StoryAnalytics.linkTap(storyId: story.id, pageNumber: page.number, via: via)
        pause(.linkOpened)

        UIApplication.shared.open(url, options: [:]) { [weak self] opened in
            guard let self else { return }

            guard opened else {
                self.resume(.linkOpened)
                return
            }

            // A link the app handles itself never leaves the app, so no
            // didBecomeActive follows: resume if we are still in front.
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                guard let self, UIApplication.shared.applicationState == .active,
                      !self.pauseReasons.contains(.background) else { return }
                self.resume(.linkOpened)
            }
        }
    }

    /// The share sheet with the app's address, paused while it is up.
    func share() {
        guard let story = currentStory, let host = hostController,
              let url = URL(string: "https://impulsepower.ru/") else { return }

        StoryAnalytics.share(storyId: story.id)
        pause(.sharing)

        let sheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        sheet.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.resume(.sharing)
        }
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = host.view
            popover.sourceRect = CGRect(x: host.view.bounds.midX, y: host.view.bounds.maxY - 80, width: 1, height: 1)
        }

        host.topMostViewController().present(sheet, animated: true)
    }

    // MARK: - Helpers

    private static func clamp(_ index: Int, in story: Story?) -> Int {
        guard let story, !story.pages.isEmpty else { return 0 }
        return min(max(index, 0), story.pages.count - 1)
    }
}

/// CADisplayLink retains its target; the proxy keeps the player free to go.
private final class DisplayLinkProxy {

    private weak var player: StoryPlayer?

    init(_ player: StoryPlayer) {
        self.player = player
    }

    @objc func tick(_ link: CADisplayLink) {
        guard let player else {
            link.invalidate()
            return
        }
        player.tick(link)
    }
}

// MARK: - StorySeenStore

//  Which story pages this device has already shown. Drives the NEW badge on
//  the home strip, the order of the strip (unseen first) and the page a story
//  reopens on.
//
//  Kept on the device only, in UserDefaults, as JSON `[storyId: [pageNumber]]`.
//  A story is fully seen when every page number it has *now* is in its set, so
//  a page the admin adds later makes the story new again.

final class StorySeenStore: ObservableObject {

    static let shared = StorySeenStore()

    /// Bumped (on the main thread) every time the seen set actually changes.
    @Published private(set) var revision: Int = 0

    /// Upper bound on remembered stories; the least recently seen are dropped.
    private static let maxStories = 200

    private let defaults: UserDefaults
    private let seenKey = "StorySeenStore.seenPages.v1"
    private let recencyKey = "StorySeenStore.recency.v1"

    private let lock = NSLock()
    /// storyId -> seen page numbers.
    private var seen: [String: Set<Int>]
    /// Story ids, least recently marked first.
    private var recency: [String]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: seenKey),
           let decoded = try? JSONDecoder().decode([String: [Int]].self, from: data) {
            seen = decoded.mapValues { Set($0) }
        } else {
            seen = [:]
        }

        let storedRecency = defaults.stringArray(forKey: recencyKey) ?? []
        // Keep only ids that are still stored, then add any stored id the
        // recency list does not know (e.g. written by an older build) at the
        // old end, so it is the first to go.
        var known = Set<String>()
        var order: [String] = []
        for id in storedRecency where seen[id] != nil && !known.contains(id) {
            order.append(id)
            known.insert(id)
        }
        let unknown = seen.keys.filter { !known.contains($0) }.sorted()
        recency = unknown + order
    }

    // MARK: - Writing

    /// Records that `pageNumber` of `storyId` was shown. Idempotent: marking a
    /// page that is already seen changes nothing and publishes nothing.
    func markSeen(storyId: String, pageNumber: Int) {
        guard !storyId.isEmpty else { return }

        lock.lock()
        var pages = seen[storyId] ?? []
        guard !pages.contains(pageNumber) else {
            lock.unlock()
            return
        }
        pages.insert(pageNumber)
        seen[storyId] = pages

        recency.removeAll { $0 == storyId }
        recency.append(storyId)
        if recency.count > Self.maxStories {
            let dropped = recency.prefix(recency.count - Self.maxStories)
            dropped.forEach { seen[$0] = nil }
            recency.removeFirst(dropped.count)
        }

        let snapshot = seen.mapValues { Array($0).sorted() }
        let recencySnapshot = recency
        lock.unlock()

        persist(snapshot, recency: recencySnapshot)
        bumpRevision()
    }

    // MARK: - Reading

    /// True when every page the story currently has was seen. A story without
    /// pages has nothing new to show and counts as seen.
    func isFullySeen(_ story: Story) -> Bool {
        let pages = seenPages(for: story.id)
        return story.pages.allSatisfy { pages.contains($0.number) }
    }

    /// Index into `story.pages` of the first page not seen yet; 0 when all
    /// pages are seen (the story replays from the start) or it has no pages.
    func firstUnseenPageIndex(in story: Story) -> Int {
        let pages = seenPages(for: story.id)
        return story.pages.firstIndex { !pages.contains($0.number) } ?? 0
    }

    /// Unseen stories first, then seen ones; inside each group the order of
    /// `stories` (the backend's order) is kept.
    func ordered(_ stories: [Story]) -> [Story] {
        lock.lock()
        let current = seen
        lock.unlock()

        var unseen: [Story] = []
        var done: [Story] = []
        for story in stories {
            let pages = current[story.id] ?? []
            if story.pages.allSatisfy({ pages.contains($0.number) }) {
                done.append(story)
            } else {
                unseen.append(story)
            }
        }
        return unseen + done
    }

    // MARK: - Private

    private func seenPages(for storyId: String) -> Set<Int> {
        lock.lock()
        defer { lock.unlock() }
        return seen[storyId] ?? []
    }

    private func persist(_ snapshot: [String: [Int]], recency: [String]) {
        // A couple of KB at most; a synchronous write is fine.
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: seenKey)
        defaults.set(recency, forKey: recencyKey)
    }

    private func bumpRevision() {
        if Thread.isMainThread {
            revision &+= 1
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.revision &+= 1
            }
        }
    }
}

// MARK: - StoryAnalytics

//  Firebase Analytics events of the stories viewer. Only story ids, page
//  numbers and short technical labels are sent - never user ids, phone
//  numbers or the texts of questionnaire options.

enum StoryAnalytics {

    /// The story strip or a deep link opened a story. `source`: e.g. "home", "deeplink".
    static func open(storyId: String, source: String) {
        log("story_open", ["story_id": storyId, "source": source])
    }

    /// A page became the visible one. `pageType`: "link" / "questionnaire";
    /// `background`: "image" / "video" / "none".
    static func pageView(storyId: String, pageNumber: Int, pageType: String, background: String) {
        log("story_page_view", [
            "story_id": storyId,
            "page_number": pageNumber,
            "page_type": pageType,
            "background": background
        ])
    }

    /// The page's link was opened. `via`: e.g. "button", "swipe_up".
    static func linkTap(storyId: String, pageNumber: Int, via: String) {
        log("story_link_tap", ["story_id": storyId, "page_number": pageNumber, "via": via])
    }

    /// A questionnaire option was chosen (the option text is deliberately not sent).
    static func optionSelect(storyId: String, pageNumber: Int) {
        log("story_option_select", ["story_id": storyId, "page_number": pageNumber])
    }

    static func like(storyId: String) {
        log("story_like", ["story_id": storyId])
    }

    static func share(storyId: String) {
        log("story_share", ["story_id": storyId])
    }

    /// The last page of the story finished.
    static func complete(storyId: String) {
        log("story_complete", ["story_id": storyId])
    }

    /// The viewer closed. `reason`: e.g. "close_button", "swipe_down", "finished", "link".
    static func close(storyId: String, pageNumber: Int, reason: String) {
        log("story_close", ["story_id": storyId, "page_number": pageNumber, "reason": reason])
    }

    // MARK: - Private

    /// Firebase drops string parameter values longer than 100 characters.
    private static let maxValueLength = 100

    private static func log(_ name: String, _ parameters: [String: Any]) {
        let trimmed = parameters.mapValues { value -> Any in
            guard let string = value as? String else { return value }
            return String(string.prefix(maxValueLength))
        }
        Analytics.logEvent(name, parameters: trimmed)
    }
}
