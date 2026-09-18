//
//  NotificationsView.swift
//  Impuls
//
//  The notifications list: close button and centred title, then the
//  notifications grouped by day as cards - a round badge for the domain,
//  title and time on one line, the body with tappable links. Placeholders
//  while the first load runs, a retry when it fails, an illustrated message
//  when there is nothing, and pull-to-refresh.
//

import SwiftUI
import UIKit

struct NotificationsView: View {

    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewModel: NotificationsViewModel

    init(viewModel: NotificationsViewModel) {
        self.viewModel = viewModel
    }

    /// The screen wrapped for UIKit callers, presented as a page sheet.
    static func makeSheet() -> UIViewController {
        let view = NotificationsView(viewModel: NotificationsViewModel(worker: Resolver.resolve()))
        let host = UIHostingController(rootView: view)
        host.modalPresentationStyle = .pageSheet
        host.view.backgroundColor = .appSecondaryBackground
        return host
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            if viewModel.isLoading {
                skeleton
            } else if viewModel.loadFailed {
                loadFailedState
            } else if viewModel.isEmpty {
                refreshableEmptyState
            } else {
                notificationList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSecondaryBackground.ignoresSafeArea())
        .onAppear { viewModel.load() }
    }

    // MARK: - Header

    /// Close on the left, centred title, no bar behind it.
    private var header: some View {
        ZStack {
            Text("MOBILE_notifications_title".localized(fallback: "Notifications"))
                .font(.robotoBold17)
                .foregroundColor(.appLabel)
                .lineLimit(1)
                .padding(.horizontal, 44)

            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.appLabel)
                        .frame(width: 44, height: 44)
                }
                .padding(.leading, 3)

                Spacer()
            }
        }
        .frame(height: 52)
        .padding(.top, 4)
    }

    // MARK: - List

    private var notificationList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                sectionsContent(viewModel.sections)
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
            .mimoRefreshable { done in
                viewModel.reload(completion: done)
            }
        }
    }

    private func sectionsContent(_ sections: [NotificationsViewModel.DaySection]) -> some View {
        ForEach(sections) { section in
            sectionHeader(section.title)

            ForEach(section.rows) { row in
                notificationCard(row)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 5)
            }
        }
    }

    /// Day label above its cards, painted on the screen ground.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.robotoMedium13)
            .foregroundColor(.appSecondaryLabel)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 6)
    }

    private func notificationCard(_ row: NotificationsViewModel.Row) -> some View {
        HStack(alignment: .top, spacing: 12) {
            badge(row.context)

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    // Two lines is enough for every template shipped today.
                    Text(row.title)
                        .font(.robotoBold15)
                        .foregroundColor(.appLabel)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer(minLength: 0)

                    Text(row.time)
                        .font(.robotoRegular12)
                        .foregroundColor(.appSecondaryLabel)
                        .lineLimit(1)
                        .fixedSize()
                }

                // Links stay tappable (the payload can carry a URL); the rest of
                // the body is plain text.
                if row.hasBody {
                    Text(row.body)
                        .font(.robotoRegular14)
                        .foregroundColor(.appSecondaryLabel)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // The chevron marks the rows whose metadata leads to a real screen;
            // it uses the same quiet gray as the meta text.
            if row.isNavigable {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gray5)
                    .frame(maxHeight: .infinity)
                    .padding(.leading, -4)
            }
        }
        .padding(.leading, 14)
        .padding(.vertical, 14)
        .padding(.trailing, row.isNavigable ? 12 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            // The screen ground is the grouped canvas, so the card is the
            // lighter surface (white in light, #31333F in dark).
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.evBgColor4)
        )
        .shadow(color: Color.alwaysBlack.opacity(0.05), radius: 6, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(row.isNavigable ? .isButton : .isStaticText)
    }

    /// Product artwork where the app has it, a tinted glyph where it does not.
    private func badge(_ context: NotificationContextStyle) -> some View {
        Group {
            if context.isTemplateImage {
                context.image
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(context.tint)
            } else {
                context.image
                    .resizable()
                    .scaledToFit()
            }
        }
        .frame(width: 22, height: 22)
        .frame(width: 40, height: 40)
        .background(Circle().fill(context.badgeBackground))
    }

    // MARK: - States

    private var skeleton: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 0) {
                sectionsContent(NotificationsViewModel.placeholderSections())
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .redacted(reason: .placeholder)
        .disabled(true)
        .accessibilityHidden(true)
    }

    private var loadFailedState: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 34, weight: .regular))
                .foregroundColor(.gray5)

            Text("MOBILE_something_wrong".localized(fallback: "Something went wrong. Please try again."))
                .font(.robotoRegular15)
                .foregroundColor(.appSecondaryLabel)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                VibrateManager.vibrate()
                viewModel.load()
            } label: {
                Text("MOBILE_try_again".localized(fallback: "Try again"))
                    .padding(.horizontal, 12)
            }
            .buttonStyle(MimoSecondaryButton())
            .frame(maxWidth: 200)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }

    /// The empty message inside a scroll view so a pull still refreshes.
    private var refreshableEmptyState: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                emptyState
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .mimoRefreshable { done in
                        viewModel.reload(completion: done)
                    }
            }
        }
    }

    /// The illustration, a heading and the sentence, centred on the screen.
    private var emptyState: some View {
        VStack(spacing: 8) {
            Image("ic_empty_data")
                .padding(.bottom, 8)

            Text("MOBILE_notifications_title".localized(fallback: "Notifications"))
                .font(.robotoBold16)
                .foregroundColor(.appLabel)
                .multilineTextAlignment(.center)

            Text("MOBILE__empty_notification_list_message".localized(fallback: "You have no notifications yet"))
                .font(.robotoRegular14)
                .foregroundColor(.appSecondaryLabel)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 32)
    }
}
