//
//  NotificationsViewModel.swift
//  Impuls
//
//  State for the notifications list: the rows grouped by day in the rider's
//  language, each with the badge its domain earns, the first-load placeholder
//  state, a failed first load (the screen offers a retry) and pull-to-refresh.
//

import SwiftUI
import Combine

/// The notification's domain, as sent by the backend on `GET /api/notification`.
/// It decides the badge, which is the only thing that tells a wallet message
/// apart from a charging one at a glance.
enum NotificationContextStyle {
    case scooter
    case bike
    case powerbank
    case evCharger
    case wallet
    case general

    init(context: String?) {
        switch context?.lowercased() {
        case "scooter": self = .scooter
        case "sharing": self = .bike
        case "powerbank": self = .powerbank
        case "evup": self = .evCharger
        case "wallet": self = .wallet
        default: self = .general
        }
    }

    /// Product artwork where the app has it, a neutral glyph where it does not.
    var image: Image {
        switch self {
        case .scooter: return Image("mimo_product_scooter")
        case .bike: return Image("mimo_product_bike")
        case .powerbank: return Image("mimo_product_charger")
        case .evCharger: return Image("mimo_product_ev_charger")
        case .wallet: return Image(systemName: "creditcard.fill")
        case .general: return Image(systemName: "bell.fill")
        }
    }

    var isTemplateImage: Bool {
        switch self {
        case .wallet, .general: return true
        default: return false
        }
    }

    var tint: Color {
        switch self {
        case .wallet: return .brandYellow
        default: return .appSecondaryLabel
        }
    }

    /// A hair lighter than the screen ground so the badge reads as part of the
    /// card, not a hole in it.
    var badgeBackground: Color { .appFill }
}

final class NotificationsViewModel: MimoBaseViewModel, ObservableObject {

    /// What a notification row draws.
    struct Row: Identifiable {
        let id: String
        let title: String
        let body: AttributedString
        let hasBody: Bool
        let time: String
        let context: NotificationContextStyle
        /// The row's metadata routes to a real screen - it shows a chevron.
        /// Impulse has no shared push router yet, so no row pretends to be a
        /// link; the flag stays so the layout is ready for one.
        let isNavigable: Bool
    }

    /// One day of notifications, newest first.
    struct DaySection: Identifiable {
        let id: Date
        let title: String
        let rows: [Row]
    }

    @Published private(set) var sections: [DaySection] = []
    /// True until the first response lands, so the screen draws placeholders.
    @Published private(set) var isLoading: Bool = false
    /// A failed first load; the screen offers a retry.
    @Published private(set) var loadFailed: Bool = false
    private var hasLoaded = false

    var isEmpty: Bool { hasLoaded && sections.isEmpty }

    private var cancellables = Set<AnyCancellable>()
    private let worker: NotificationsWorkerProtocol

    init(worker: NotificationsWorkerProtocol) {
        self.worker = worker
        super.init()
    }

    // MARK: - Loading

    func load() {
        if !hasLoaded {
            isLoading = true
            loadFailed = false
        }

        worker.getNotifications()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.loadFailed = !self.hasLoaded
                    self.mimoError = error
                }
            } receiveValue: { [weak self] notifications in
                guard let self else { return }
                self.hasLoaded = true
                self.sections = Self.makeSections(from: notifications)
            }
            .store(in: &cancellables)
    }

    /// Pull-to-refresh: reports back once the list (or an error) arrives.
    func reload(completion: @escaping (Bool) -> Void) {
        var delivered = false
        let loaded = $sections.dropFirst().map { _ in true }
        let failed = $errorMessage.dropFirst().compactMap { $0 }.map { _ in false }

        loaded.merge(with: failed)
            .first()
            .timeout(.seconds(15), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                if case .finished = result, !delivered { completion(false) }
            }, receiveValue: { success in
                delivered = true
                completion(success)
            })
            .store(in: &cancellables)

        load()
    }

    // MARK: - Mapping

    private static var locale: Locale {
        guard let language = StorageManager().fetch(key: .language, type: String.self) else { return .current }

        return Locale(identifier: language)
    }

    private static func date(from milliseconds: Double?) -> Date {
        Date(timeIntervalSince1970: (milliseconds ?? 0) / 1000)
    }

    /// Notifications grouped by day, newest day first - a flat list gives no
    /// sense of when anything happened.
    private static func makeSections(from notifications: [NotificationListResponse]) -> [DaySection] {
        let locale = self.locale
        let grouped = Dictionary(grouping: notifications) { notification in
            Calendar.current.startOfDay(for: date(from: notification.date))
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return grouped
            .sorted { $0.key > $1.key }
            .map { day, items in
                DaySection(
                    id: day,
                    title: formatter.string(from: day),
                    rows: items
                        .sorted { date(from: $0.date) > date(from: $1.date) }
                        .map { makeRow($0, locale: locale) }
                )
            }
    }

    private static func makeRow(_ item: NotificationListResponse, locale: Locale) -> Row {
        let content = message(for: item, locale: locale)
        let bodyText = content?.content ?? ""

        return Row(id: item.id ?? UUID().uuidString,
                   title: content?.title ?? "",
                   body: attributedContent(bodyText),
                   hasBody: !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                   time: timeText(for: item, locale: locale),
                   context: NotificationContextStyle(context: item.context),
                   isNavigable: false)
    }

    /// The backend ships one `Message` per language; pick the one the app is
    /// set to and fall back to English rather than drawing an empty row.
    private static func message(for notification: NotificationListResponse, locale: Locale) -> Message? {
        let content = notification.content

        switch locale.identifier.prefix(2) {
        case "ru": return content?.ru ?? content?.en
        case "hy", "am": return content?.hy ?? content?.en
        default: return content?.en ?? content?.ru ?? content?.hy
        }
    }

    /// "2h ago" while it is recent, a clock time after that - the section
    /// header already carries the date.
    private static func timeText(for notification: NotificationListResponse, locale: Locale) -> String {
        let date = date(from: notification.date)
        let elapsed = Date().timeIntervalSince(date)

        if elapsed < 60 * 60 * 24 {
            let formatter = RelativeDateTimeFormatter()
            formatter.locale = locale
            formatter.unitsStyle = .abbreviated

            return formatter.localizedString(for: date, relativeTo: Date())
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        return formatter.string(from: date)
    }

    /// Body text with every URL turned into a tappable link.
    private static func attributedContent(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return attributed
        }

        let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        for match in matches {
            guard let url = match.url,
                  let range = Range(match.range, in: text),
                  let attributedRange = attributed.range(of: String(text[range])) else { continue }
            attributed[attributedRange].link = url
            attributed[attributedRange].foregroundColor = Color(UIColor.systemBlue)
        }

        return attributed
    }

    /// Dummy rows for the redacted loading state.
    static func placeholderSections() -> [DaySection] {
        let rows = (0..<4).map { index in
            Row(id: "placeholder-\(index)",
                title: "Notification title",
                body: AttributedString("Placeholder body text that is long enough to wrap onto a second line."),
                hasBody: true,
                time: "2h ago",
                context: .general,
                isNavigable: false)
        }

        return [DaySection(id: Date(), title: "Today", rows: rows)]
    }
}
