//
//  MimoDateOfBirthSheet.swift
//  Impuls
//
//  The one date-of-birth picker in the app: a bottom sheet where the rider
//  taps a year, then a month, then a day, instead of spinning three wheels
//  decades back. The three tiles on top show what is chosen so far and jump
//  back to any step. Nothing is written until the rider confirms, so closing
//  the sheet leaves the form as it was.
//  Presented through `MimoDateOfBirthPicker.present`, from SwiftUI and UIKit
//  screens alike.
//

import SwiftUI
import UIKit

struct MimoDateOfBirthSheet: View {

    private enum Step {
        case day
        case month
        case year
    }

    let onClose: () -> Void
    let onConfirm: (Date) -> Void

    @State private var step: Step
    @State private var year: Int?
    @State private var month: Int?
    @State private var day: Int?

    private let calendar = MimoDateOfBirthPicker.calendar
    private let today: DateComponents

    init(selected: Date?, onClose: @escaping () -> Void, onConfirm: @escaping (Date) -> Void) {
        self.onClose = onClose
        self.onConfirm = onConfirm

        let calendar = MimoDateOfBirthPicker.calendar
        today = calendar.dateComponents([.year, .month, .day], from: Date())

        if let selected = selected {
            let clamped = min(max(selected, MimoDateOfBirthPicker.earliestDate), Date())
            let components = calendar.dateComponents([.year, .month, .day], from: clamped)
            _year = State(initialValue: components.year)
            _month = State(initialValue: components.month)
            _day = State(initialValue: components.day)
            _step = State(initialValue: .day)
        } else {
            // Nothing stored yet: start with the year, the step that narrows most.
            _year = State(initialValue: nil)
            _month = State(initialValue: nil)
            _day = State(initialValue: nil)
            _step = State(initialValue: .year)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            MimoSheetHeader(title: "MOBILE_registartion_dob".localized(), action: onClose)

            HStack(spacing: 8) {
                tile(.day,
                     title: "MOBILE_dob_picker_day".localized(fallback: "Day"),
                     value: day.map { String($0) })
                tile(.month,
                     title: "MOBILE_dob_picker_month".localized(fallback: "Month"),
                     value: month.map { monthNames[$0 - 1] })
                tile(.year,
                     title: "MOBILE_dob_picker_year".localized(fallback: "Year"),
                     value: year.map { String($0) })
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)

            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    Group {
                        switch step {
                        case .year: yearGrid
                        case .month: monthGrid
                        case .day: dayGrid
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
                .onAppear { scrollToYear(with: proxy) }
                .onChange(of: step) { _ in scrollToYear(with: proxy) }
            }

            Button {
                guard let date = selectedDate else { return }

                VibrateManager.vibrate()
                onConfirm(date)
            } label: {
                Text("MOBILE_global_done".localized())
            }
            .buttonStyle(MimoButton(isEnabled: selectedDate != nil))
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .background(Color.appSecondaryBackground.ignoresSafeArea())
    }

    // MARK: - Tiles

    private func tile(_ target: Step, title: String, value: String?) -> some View {
        let isActive = step == target

        return Button {
            VibrateManager.vibrate()
            step = target
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.robotoRegular12)
                    .foregroundColor(.gray5)
                    .lineLimit(1)

                Text(value ?? "—")
                    .font(.robotoBold17)
                    .foregroundColor(value == nil ? .gray5 : .appLabel)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .frame(height: 60)
            .background(Color.appBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? Color.brandYellow : Color.appSeparator, lineWidth: isActive ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Grids

    private var yearGrid: some View {
        grid(years, columns: 4) { value in
            cell(String(value), isSelected: year == value) {
                year = value
                dropWhatNoLongerFits()
                step = .month
            }
            .id(value)
        }
    }

    private var monthGrid: some View {
        grid(Array(1...12), columns: 3) { value in
            cell(monthNames[value - 1],
                 isSelected: month == value,
                 isEnabled: isSelectable(month: value)) {
                month = value
                dropWhatNoLongerFits()
                step = .day
            }
        }
    }

    private var dayGrid: some View {
        grid(Array(1...numberOfDays), columns: 7) { value in
            cell(String(value),
                 isSelected: day == value,
                 isEnabled: isSelectable(day: value)) {
                day = value
            }
        }
    }

    /// Rows of equal cells; the last row is padded so its cells keep the width
    /// of the rows above.
    private func grid<Cell: View>(_ items: [Int],
                                  columns: Int,
                                  @ViewBuilder cell: @escaping (Int) -> Cell) -> some View {
        let rows = stride(from: 0, to: items.count, by: columns).map {
            Array(items[$0..<min($0 + columns, items.count)])
        }

        return VStack(spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        cell(item)
                    }

                    ForEach(0..<(columns - row.count), id: \.self) { _ in
                        Color.clear.frame(maxWidth: .infinity).frame(height: 44)
                    }
                }
            }
        }
    }

    private func cell(_ title: String,
                      isSelected: Bool,
                      isEnabled: Bool = true,
                      action: @escaping () -> Void) -> some View {
        Button {
            VibrateManager.vibrate()
            action()
        } label: {
            Text(title)
                .font(.robotoMedium15)
                .foregroundColor(isSelected ? .onBrandLabel : (isEnabled ? .appLabel : .label025))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Color.brandYellow : Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    // MARK: - Values

    /// Newest first: most riders are far closer to this end of the list.
    private var years: [Int] {
        let current = today.year ?? 2000
        let earliest = calendar.component(.year, from: MimoDateOfBirthPicker.earliestDate)
        return Array((earliest...current).reversed())
    }

    private var monthNames: [String] {
        let formatter = DateFormatter()
        formatter.locale = MimoDateOfBirthPicker.locale
        formatter.calendar = calendar
        let names = formatter.standaloneMonthSymbols ?? formatter.monthSymbols ?? []
        return names.count == 12 ? names.map { $0.capitalized(with: formatter.locale) } : (1...12).map { String($0) }
    }

    /// Days of the chosen month; 31 while the month is still open, and a leap
    /// February while the year is.
    private var numberOfDays: Int {
        guard let month = month else { return 31 }

        let components = DateComponents(year: year ?? 2000, month: month, day: 1)
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else { return 31 }

        return range.count
    }

    private var isCurrentYear: Bool {
        year != nil && year == today.year
    }

    private func isSelectable(month value: Int) -> Bool {
        !isCurrentYear || value <= (today.month ?? 12)
    }

    private func isSelectable(day value: Int) -> Bool {
        guard isCurrentYear, month == today.month else { return true }

        return value <= (today.day ?? 31)
    }

    /// A new year or month can leave the rest pointing at a date that does not
    /// exist (30 February) or has not happened yet; that part is asked again.
    private func dropWhatNoLongerFits() {
        if let value = month, !isSelectable(month: value) {
            month = nil
        }

        if let value = day, value > numberOfDays || !isSelectable(day: value) {
            day = nil
        }
    }

    private var selectedDate: Date? {
        guard let year = year, let month = month, let day = day else { return nil }

        // Noon, so no time zone shift can move the date to a neighbouring day.
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))
    }

    private func scrollToYear(with proxy: ScrollViewProxy) {
        guard step == .year else { return }

        let target = year ?? calendar.component(.year, from: MimoDateOfBirthPicker.defaultDate)
        DispatchQueue.main.async {
            proxy.scrollTo(target, anchor: .center)
        }
    }
}

enum MimoDateOfBirthPicker {

    static let calendar = Calendar(identifier: .gregorian)

    /// Where the year list opens when no birthday is stored yet. A starting
    /// point only: the minimum age is the backend's rule per country and per
    /// action.
    static var defaultDate: Date {
        calendar.date(byAdding: .year, value: -18, to: Date()) ?? Date()
    }

    static var earliestDate: Date {
        calendar.date(byAdding: .year, value: -120, to: Date()) ?? .distantPast
    }

    /// The app's language, which is not necessarily the device's.
    static var locale: Locale {
        guard let language = StorageManager().fetch(key: .language, type: String.self), !language.isEmpty else {
            return .current
        }

        return Locale(identifier: language)
    }

    /// "12 March 1998", in the app's language.
    static func displayString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.calendar = calendar
        formatter.dateFormat = "dd MMMM yyyy"
        return formatter.string(from: date)
    }

    /// Presents the sheet over `presenter` (the top-most screen when nil) and
    /// reports the date once the rider confirms it.
    static func present(from presenter: UIViewController? = nil,
                        selected: Date?,
                        onConfirm: @escaping (Date) -> Void) {
        guard let presenter = presenter ?? UIApplication.shared.topMostViewController() else { return }

        UIApplication.shared.dismissKeyboard()

        let host = UIHostingController(rootView: AnyView(EmptyView()))
        host.rootView = AnyView(
            MimoDateOfBirthSheet(
                selected: selected,
                onClose: { [weak host] in host?.dismiss(animated: true) },
                onConfirm: { [weak host] date in
                    onConfirm(date)
                    host?.dismiss(animated: true)
                }
            )
        )
        host.view.backgroundColor = UIColor(named: "AppSecondaryBackground")

        if #available(iOS 15.0, *), let sheet = host.sheetPresentationController {
            if #available(iOS 16.0, *) {
                sheet.detents = [.custom(identifier: .init("dateOfBirth")) { context in
                    min(540, context.maximumDetentValue)
                }]
            } else {
                // No custom heights on iOS 15, and half a screen is too little
                // for the day grid.
                sheet.detents = [.large()]
            }
            sheet.preferredCornerRadius = 20
        }

        presenter.present(host, animated: true)
    }
}
