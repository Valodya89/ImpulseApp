//
//  StoriesThumbView.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 21.12.23.
//
//  Hosted on home by `MimoHomeViewController`, which sizes its container to
//  `stripHeight`.
//
//  The stories strip on home: wide picture cards with the story's name in
//  bold at the bottom left, a round play button at the bottom right and a
//  yellow NEW badge while the story has a page this device has not shown
//  yet. Unseen stories come first. Tapping a preview opens the viewer, which
//  zooms out of (and back into) the preview's on-screen frame.
//

import SwiftUI
import Kingfisher

struct StoriesThumbView: View {

    @EnvironmentObject var storyViewModel: StoryViewModel
    @ObservedObject private var seenStore = StorySeenStore.shared

    /// Latest list from the view model. `stories` is a subject, not a
    /// `@Published` property, so it is mirrored here to redraw when it emits.
    @State private var receivedStories: [Story]?
    /// Global frames of the thumbnails, written on every layout pass. A plain
    /// reference box so scrolling does not invalidate the view.
    @State private var frameBox = StoryThumbnailFrameBox()

    var body: some View {
        let stories = seenStore.ordered(receivedStories ?? storyViewModel.stories.value)

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: Layout.spacing) {
                ForEach(stories, id: \.id) { story in
                    Button {
                        open(story, in: stories)
                    } label: {
                        StoryThumbnailItem(story: story, isUnseen: !seenStore.isFullySeen(story))
                    }
                    .buttonStyle(StoryThumbnailButtonStyle())
                    .accessibilityLabel(Text(story.name))
                    .accessibilityValue(Text(seenStore.isFullySeen(story) ? "" : "MOBILE_story_new".localized(fallback: "New")))
                    .accessibilityIdentifier("storyThumbnail")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, Layout.verticalPadding)
            .animation(.easeInOut(duration: 0.3), value: stories.map(\.id))
        }
        .onPreferenceChange(StoryThumbnailFramesKey.self) { frames in
            frameBox.frames = frames
        }
        .onReceive(storyViewModel.stories.receive(on: DispatchQueue.main)) { stories in
            receivedStories = stories
        }
    }

    private func open(_ story: Story, in stories: [Story]) {
        let box = frameBox
        StoryViewerPresenter.present(
            viewModel: storyViewModel,
            stories: stories,
            startStoryId: story.id,
            thumbnailFrame: { id in box.visibleFrame(for: id) }
        )
    }

    /// Also the corner the viewer shrinks into when it opens or closes.
    static let previewCornerRadius: CGFloat = 14

    /// What the strip needs from its host: the cards plus their vertical padding.
    static let stripHeight: CGFloat = Layout.cardHeight + 2 * Layout.verticalPadding

    fileprivate enum Layout {
        static let cardWidth: CGFloat = 142
        static let cardHeight: CGFloat = 110
        static let spacing: CGFloat = 10
        static let verticalPadding: CGFloat = 8
    }
}

// MARK: - Item

private struct StoryThumbnailItem: View {

    let story: Story
    let isUnseen: Bool

    private static let cardBorder = Color(UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.3)
            : UIColor.black.withAlphaComponent(0.15)
    })

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: StoriesThumbView.previewCornerRadius, style: .continuous)

        ZStack(alignment: .bottomLeading) {
            thumbnail
                .frame(width: StoriesThumbView.Layout.cardWidth, height: StoriesThumbView.Layout.cardHeight)
                .clipped()

            // Legibility of the white name on light pictures.
            LinearGradient(colors: [.clear, Color.alwaysBlack.opacity(0.65)], startPoint: .center, endPoint: .bottom)

            HStack(alignment: .center, spacing: 6) {
                Text(story.name)
                    .font(.robotoBold15)
                    .foregroundColor(.alwaysWhite)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .shadow(color: .alwaysBlack.opacity(0.35), radius: 2, x: 0, y: 1)

                Spacer(minLength: 0)

                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.alwaysWhite)
                    .offset(x: 1)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.alwaysBlack.opacity(0.55)))
                    .overlay(Circle().stroke(Color.alwaysWhite.opacity(0.35), lineWidth: 1))
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 9)
        }
        .frame(width: StoriesThumbView.Layout.cardWidth, height: StoriesThumbView.Layout.cardHeight)
        .overlay(alignment: .topLeading) {
            if isUnseen {
                Text("MOBILE_story_new".localized(fallback: "New").uppercased())
                    .font(.robotoBold12)
                    .foregroundColor(.onBrandLabel)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.brandYellow))
                    .padding(8)
            }
        }
        .clipShape(shape)
        // A crisp 1 pt edge inside the card, light on dark and dark on light,
        // so it reads on any picture in both appearances.
        .overlay(shape.strokeBorder(Self.cardBorder, lineWidth: 1))
        .background(
            // The viewer zooms out of this card and back into it.
            GeometryReader { proxy in
                Color.clear.preference(
                    key: StoryThumbnailFramesKey.self,
                    value: [story.id: proxy.frame(in: .global)]
                )
            }
        )
        .contentShape(shape)
        .accessibilityElement(children: .ignore)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let url = thumbnailURL {
            KFImage(url)
                .placeholder { placeholder }
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.appFill
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.appSecondaryLabel)
        }
    }

    /// First page's picture (the card shows the story's artwork); else its
    /// logo when the background is a video (`KFImage` cannot draw a video).
    private var thumbnailURL: URL? {
        guard let page = story.pages.first else { return nil }
        if let background = page.background?.imageURL, !Self.isVideo(page, url: background) { return background }
        return page.logo?.imageURL
    }

    private static let videoExtensions: Set<String> = ["mp4", "mov", "m4v"]

    private static func isVideo(_ page: StoryPage, url: URL) -> Bool {
        if let type = page.backgroundType?.lowercased(), !type.isEmpty {
            if type.contains("video") || videoExtensions.contains(type) { return true }
            if type.contains("image") { return false }
        }
        return videoExtensions.contains(url.pathExtension.lowercased())
    }
}

// MARK: - Pressed state

private struct StoryThumbnailButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Frames

private struct StoryThumbnailFramesKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]

    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}

/// Holds the latest global frame of every thumbnail. Read by the viewer when
/// it opens and when it closes, so the zoom starts and ends on the thumbnail
/// wherever it is at that moment.
private final class StoryThumbnailFrameBox {
    var frames: [String: CGRect] = [:]

    /// The frame when the thumbnail is (mostly) on screen; nil when it is
    /// scrolled out, never laid out, or the strip is gone.
    func visibleFrame(for id: String) -> CGRect? {
        guard let frame = frames[id], frame.width > 0, frame.height > 0 else { return nil }
        let visible = frame.intersection(UIScreen.main.bounds)
        guard !visible.isNull, visible.width * visible.height >= frame.width * frame.height * 0.5 else { return nil }
        return frame
    }
}
