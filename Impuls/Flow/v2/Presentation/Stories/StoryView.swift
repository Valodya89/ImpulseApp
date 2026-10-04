//
//  StoryView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.12.23.
//

import SwiftUI
import Combine
import Kingfisher
import AVFoundation
//import FirebaseAnalytics

struct StoryView: View {
    
    @EnvironmentObject var storyViewModel: StoryViewModel
    
    var body: some View {
        if storyViewModel.showStory {
            TabView(selection: $storyViewModel.currentStory) {
                ForEach(storyViewModel.stories.value) { story in
                    StoryCardView(story: story)
                        .environmentObject(storyViewModel)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea(edges: .all))
        }
    }
}

struct StoryCardView: View {
    
    @EnvironmentObject var storyViewModel: StoryViewModel
    
    let story: Story
    
    @State var timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    @State var timerProgress: CGFloat = 0
    @State var isTimerRunning = true
    @GestureState var isPressing = false
    @State var shareURL: URL? = nil
    @State var currentIndex = 0

    /// Plays the page whose background is a video; that page lasts as long as
    /// its video instead of the five seconds a picture gets.
    @StateObject private var playback = StoryVideoPlayback()
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                // A story with no pages yields index -1 and traps on subscript.
                let index = max(0, min(Int(timerProgress), story.pages.count - 1))

                if story.pages.isEmpty {
                    EmptyView()
                } else if story.pages[index].type == .link {
                    StoryActionView(storyGroup: story, story: story.pages[index])
                        .environmentObject(storyViewModel)
                } else {
                    StorySurveyView(story: story.pages[index])
                        .environmentObject(storyViewModel)
                }
                
                if shareURL != nil {
                    ActivityViewController(shareURL: $shareURL)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .cornerRadius(6)
            .overlay(
                HStack {
                    Rectangle()
                        .fill(.black.opacity(0.01))
                        .onTapGesture {
                            if (timerProgress - 1) < 0 {
                                updateStory(forward: false)
                            } else {
                                timerProgress = CGFloat(Int(timerProgress - 1))
                            }
                        }
                    
                    Rectangle()
                        .fill(.black.opacity(0.01))
                        .onTapGesture {
                            if (timerProgress + 1) > CGFloat(story.pages.count) {
                                updateStory()
                            } else {
                                timerProgress = CGFloat(Int(timerProgress + 1))
                            }
                        }
                }
                    .frame(height: proxy.size.height * 0.45)
                    .padding(.top, 65)
                , alignment: .top
            )
            .overlay(
                Button(action: {
                    storyViewModel.showStory = false
                }, label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.alwaysWhite)
                        .shadow(color: .black, radius: 2, x: 1, y: 1)
                })
                .padding()
                .padding(.top, 20)
                , alignment: .topTrailing
            )
            .overlay(
                HStack(spacing: 5) {
                    ForEach(story.pages.indices, id: \.self) { index in
                        
                        GeometryReader { proxy in
                            
                            let width = proxy.size.width
                            let progress = timerProgress - CGFloat(index)
                            let perfectProgress = min(max(progress, 0), 1)
                            
                            Capsule()
                                .fill(.gray.opacity(0.5))
                                .overlay(
                                    Capsule()
                                        .fill(Color.mimoYellow500)
                                        .frame(width: width * perfectProgress)
                                    , alignment: .leading
                                )
                        }
                    }
                }
                .frame(height: 4)
                .padding()
                , alignment: .top
            )
            .overlay(
                VStack(spacing: 0) {
                    Divider()
                        .frame(minHeight: 1)
                        .background(Color.alwaysWhite.opacity(0.2))
                        .padding(.bottom, 16)
                        .padding(.horizontal, 20)
                    
                    HStack {
                        Spacer()

                        HStack(spacing: 10) {
                            
                            Button {
                                shareURL = URL(string: "https://impulsepower.ru/")
                            } label: {
                                ZStack {
                                    Color.alwaysWhite.opacity(0.1)
                                    
                                    Image(systemName: "arrowshape.turn.up.right")
                                        .resizable()
                                        .foregroundColor(Color.alwaysWhite)
                                        .frame(width: 24, height: 24)
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            }

                            Button {
                                storyViewModel.like()
                            } label: {
                                ZStack {
                                    Color.alwaysWhite.opacity(0.1)

                                    Image(systemName: storyViewModel.isLiked() ? "heart.fill" : "heart")
                                        .resizable()
                                        .foregroundColor(storyViewModel.isLiked() ? Color.mimoYellow500 : Color.alwaysWhite)
                                        .frame(width: 20, height: 20)
                                }
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                            }
                            .disabled(storyViewModel.isLiked())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                , alignment: .bottom
            )
            .rotation3DEffect(getAngle(proxy: proxy),
                              axis: (x: 0, y: 1, z: 0),
                              anchor: proxy.frame(in: .global).minX > 0 ? .leading : .trailing,
                              perspective: 2.5)
        }
        .environmentObject(playback)
        .onAppear(perform: {
            withAnimation {
                timerProgress = 0
            }
        })
        .onDisappear {
            playback.reset()
        }
        .onReceive(timer) { _ in
            let isCurrent = story.id == storyViewModel.currentStory && storyViewModel.showStory

            guard isCurrent else {
                // Swiped away from: coming back starts its page over.
                playback.reset()
                return
            }

            playback.show(story.pages.indices.contains(shownIndex) ? story.pages[shownIndex] : nil)

            guard isTimerRunning else {
                playback.pause()
                return
            }

            playback.play()

            if timerProgress < CGFloat(story.pages.count) {
                if let videoProgress = playback.progress {
                    // The video is the clock: the bar follows it, waits while
                    // it loads, and moves on when it ends.
                    let target = CGFloat(shownIndex) + videoProgress
                    if target != timerProgress {
                        withAnimation(videoProgress >= 1 ? nil : .linear(duration: 0.1)) {
                            timerProgress = target
                        }
                    }
                } else {
                    withAnimation {
                        timerProgress += 0.02
                    }
                }
            } else {
                updateStory()
            }

            let index = max(0, min(Int(timerProgress), story.pages.count - 1))
            if self.currentIndex != index, story.pages.indices.contains(index) {
                self.currentIndex = index

                print("Story -> \(story.pages[index].title) ::::")
            }
        }
        .gesture(LongPressGesture(minimumDuration: 0.01)
            .sequenced(before: LongPressGesture(minimumDuration: .infinity))
                    .updating($isPressing) { value, state, transaction in
                        switch value {
                        case .second(true, nil):
                            state = true
                            isTimerRunning = false
                        case .first(true):
                            print("1111isPressinggg: \(value)")
                        default:
                            break
                        }
                    })
                .onChange(of: isPressing) { value in
                    if value == false {
                        isTimerRunning = true
                    }
                    
                    print("isPressinggg: \(value)")
                }
    }
    
    /// The page on screen, as `body` picks it.
    private var shownIndex: Int {
        max(0, min(Int(timerProgress), story.pages.count - 1))
    }

    func getAngle(proxy: GeometryProxy) -> Angle {
        let progress = proxy.frame(in: .global).minX / proxy.size.width
        let rotationAngle: CGFloat = 45
        let degrees = rotationAngle * progress
        
        return Angle(degrees: Double(degrees))
    }
    
    func updateStory(forward: Bool = true) {
        let index = max(0, min(Int(timerProgress), story.pages.count - 1))
        guard story.pages.indices.contains(index) else { return }
        let currentStory = self.story.pages[index]
        
        if !forward {
            if let first = storyViewModel.stories.value.first, first.id != story.id {
                let storyIndex = storyViewModel.stories.value.firstIndex(where: { $0.id == story.id }) ?? 0
                withAnimation {
                    storyViewModel.currentStory = storyViewModel.stories.value[storyIndex - 1].id
                }
            } else {
                withAnimation {
                    timerProgress = 0
                }
            }
            return
        }
        
        if let last = story.pages.last, last.number == currentStory.number {
            if let lastStory = storyViewModel.stories.value.last, lastStory.id == story.id {
                storyViewModel.showStory = false
//                timerProgress = 0
            } else {
                let storyIndex = storyViewModel.stories.value.firstIndex(where: { $0.id == story.id }) ?? 0
                withAnimation {
                    storyViewModel.currentStory = storyViewModel.stories.value[storyIndex + 1].id
                }
            }
        }
    }
}

extension View {
    func pressAction(onPress: @escaping (() -> Void), onRelease: @escaping (() -> Void)) -> some View {
        modifier(PressActions(onPress: {
            onPress()
        }, onRelease: {
            onRelease()
        }))
    }
}

struct PressActions: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 20)
                    .onChanged({ _ in
                        onPress()
                    })
                    .onEnded({ _ in
                        onRelease()
                    })
            )
    }
}

struct CustomGestureModifier: ViewModifier {
    var onRightTap: () -> Void
    var onLeftTap: () -> Void
    var onLongPressBegan: (() -> Void)
    var onLongPressEnded: () -> Void
    
    func body(content: Content) -> some View {
        content
            .overlay(
                CustomGestureRepresentable(
                    onRightTap: onRightTap,
                    onLeftTap: onLeftTap,
                    onLongPressBegan: onLongPressBegan,
                    onLongPressEnded: onLongPressEnded
                )
            )
    }
}

extension View {
    func customGestures(
        onRightTap: @escaping () -> Void,
        onLeftTap: @escaping () -> Void,
        onLongPressBegan: @escaping () -> Void,
        onLongPressEnded: @escaping () -> Void
    ) -> some View {
        self.modifier(CustomGestureModifier(
            onRightTap: onRightTap,
            onLeftTap: onLeftTap,
            onLongPressBegan: onLongPressBegan,
            onLongPressEnded: onLongPressEnded
        ))
    }
}

// MARK: - Page background (picture or video)

/// The background of a story page: the picture, or the video when the page's
/// file is one. Fills the page either way.
struct StoryBackgroundView: View {

    let page: StoryPage

    @EnvironmentObject private var playback: StoryVideoPlayback

    var body: some View {
        if playback.videoPageNumber == page.number {
            ZStack {
                Color.black

                StoryVideoLayerView(player: playback.player)

                if !playback.isReady {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
        } else if page.backgroundKind == .video {
            // About to be handed to the player; a video is not a picture to load.
            Color.black
        } else {
            KFImage(page.background?.imageURL)
                .resizable()
                .scaledToFill()
        }
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

// MARK: - Video playback

/// What a page's background file is. The stories contract describes the
/// background as a `FileData` and nothing more (accounts docs/mobile-api.md,
/// GET /api/stories), so the kind is read from what the file says about
/// itself: its `type`, then its address, then - when neither tells - the
/// content type the server answers with.
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

/// Plays the page of a story whose background is a video. One per story card:
/// the card tells it which page is up, reads how far the video has got to
/// drive the progress bar, and pauses it with the rest of the story.
final class StoryVideoPlayback: ObservableObject {

    let player = AVPlayer()

    /// The page whose background is being played as a video, nil while the
    /// page on screen shows a picture.
    @Published private(set) var videoPageNumber: Int?
    /// False until the first frame can be shown.
    @Published private(set) var isReady = false

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

    // MARK: Which page

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
        let item = AVPlayerItem(url: url)

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

    // MARK: Transport

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

    // MARK: Progress

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
