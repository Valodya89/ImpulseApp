//
//  FastDecisionTableViewCell.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 07.06.23.
//

import UIKit
import SwiftUI
import CoreLocation

// MARK: - Row content

/// Everything a fast-decision row draws. Every product fills the same shape, so
/// the list reads as one list instead of four - they differ only in which chips
/// and which status they hand over.
struct FastDecisionRow {

    /// A small fact worth scanning: how far, how long the charge lasts, when the
    /// station is open, what a kWh costs.
    struct Chip: Identifiable {
        let id = UUID()
        let systemImage: String?
        let text: String
    }

    /// The one thing that decides whether this row is usable at all.
    enum Status {
        /// Battery artwork plus its reading - scooters.
        case reading(image: UIImage?, text: String)
        /// A coloured state capsule - power bank availability, EV connector state.
        case capsule(text: String, background: Color, foreground: Color)
    }

    let imageName: String
    let title: String
    let code: String?
    var address: String?
    /// Vehicles get their address reverse-geocoded after the row is already on
    /// screen; the line is drawn as a skeleton meanwhile so nothing jumps when
    /// the text lands.
    var awaitsAddress: Bool = false
    let chips: [Chip]
    let status: Status?
}

// MARK: - Row

struct FastDecisionRowView: View {

    let row: FastDecisionRow?

    var body: some View {
        VStack(spacing: 0) {
            if let row {
                HStack(spacing: 12) {
                    productImage(row.imageName)

                    VStack(alignment: .leading, spacing: 6) {
                        titleLine(row)

                        if let address = row.address, !address.isEmpty {
                            addressLine(address)
                        } else if row.awaitsAddress {
                            addressPlaceholder()
                        }

                        if !row.chips.isEmpty {
                            chipsLine(row.chips)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }

            // Inset hairline instead of the table's edge-to-edge separator, so the
            // rule starts where the content starts.
            Rectangle()
                .fill(Color.dividerColor)
                .frame(height: 1)
                .padding(.leading, 16)
        }
        .background(Color.white)
        // A hosting view inherits the window's safe area, which would squeeze the
        // row that happens to overlap the home indicator.
        .ignoresSafeArea()
    }

    private func productImage(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .padding(9)
            .frame(width: 56, height: 56)
            .background(Circle().fill(Color.evBgColor))
    }

    private func titleLine(_ row: FastDecisionRow) -> some View {
        HStack(spacing: 8) {
            Text(row.title)
                .font(.robotoBold16)
                .foregroundColor(Color.evText9)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            if let code = row.code, !code.isEmpty {
                codePill(code)
            }

            Spacer(minLength: 8)

            if let status = row.status {
                statusView(status)
            }
        }
    }

    /// The number printed on the scooter, bike or cabinet - the rider matches the
    /// row to the thing in front of them by this, so it stays next to the name.
    private func codePill(_ code: String) -> some View {
        HStack(spacing: 5) {
            Image(.qrIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 13, height: 13)

            Text(code)
                .font(.robotoMedium13)
                .foregroundColor(Color.evText9)
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .overlay(
            Capsule().stroke(Color.brandYellow, lineWidth: 1.5)
        )
        .fixedSize(horizontal: true, vertical: false)
    }

    private func addressLine(_ address: String) -> some View {
        HStack(spacing: 6) {
            Image(.evLocationMarker)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)

            // Addresses routinely outgrow the line; a truncated one is useless for
            // finding the thing, so the overflow scrolls past instead.
            MarqueeText(text: address, font: .robotoRegular14, color: Color.gray6)
        }
    }

    private func addressPlaceholder() -> some View {
        HStack(spacing: 6) {
            Image(.evLocationMarker)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
                .opacity(0.4)

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.evBgColor)
                .frame(width: 140, height: 12)
        }
    }

    private func chipsLine(_ chips: [FastDecisionRow.Chip]) -> some View {
        HStack(spacing: 6) {
            ForEach(chips) { chip in
                HStack(spacing: 4) {
                    if let systemImage = chip.systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color.gray6)
                    }

                    Text(chip.text)
                        .font(.robotoMedium12)
                        .foregroundColor(Color.evText9)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.evBgColor))
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func statusView(_ status: FastDecisionRow.Status) -> some View {
        switch status {
        case let .reading(image, text):
            HStack(spacing: 6) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 13)
                }

                Text(text)
                    .font(.robotoBold15)
                    .foregroundColor(Color.evText9)
                    .lineLimit(1)
            }
            .fixedSize(horizontal: true, vertical: false)

        case let .capsule(text, background, foreground):
            Text(text)
                .font(.robotoMedium12)
                .foregroundColor(foreground)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(background))
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

// MARK: - Marquee

/// A single-line label that scrolls sideways when its text is wider than the
/// space it is given, so the whole string can be read. Text that fits is drawn
/// as a plain label, and the scroll is dropped when the user asks for reduced
/// motion.
struct MarqueeText: View {

    let text: String
    let font: Font
    let color: Color

    /// Gap between the end of the text and the copy that follows it.
    var gap: CGFloat = 40
    /// Points per second.
    var speed: CGFloat = 28
    /// How long the text rests at its start before each pass.
    var pause: TimeInterval = 1.5
    /// Width of the soft edges that hint at text beyond the line.
    var fade: CGFloat = 12

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var start = Date()

    private var scrolls: Bool {
        !reduceMotion && containerWidth > 0 && textWidth > containerWidth + 0.5
    }

    /// One pass moves the text by its own width plus the gap, which lands the
    /// trailing copy exactly where the leading one started - so the wrap is
    /// invisible.
    private var distance: CGFloat { textWidth + gap }

    var body: some View {
        Group {
            if scrolls {
                TimelineView(.animation) { context in
                    let shift = shift(at: context.date)

                    HStack(spacing: gap) {
                        label.fixedSize()
                        label.fixedSize()
                    }
                    .offset(x: -shift)
                    .frame(width: containerWidth, alignment: .leading)
                    .clipped()
                    .mask(edgeMask(leadingFaded: shift > 0))
                }
                .onAppear { start = Date() }
            } else {
                label
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: ContainerWidthKey.self, value: proxy.size.width)
            }
        )
        .background(
            // An invisible copy at its natural width tells us whether the text
            // overflows; a background never affects the layout it sits behind.
            label
                .fixedSize()
                .opacity(0)
                .accessibilityHidden(true)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: TextWidthKey.self, value: proxy.size.width)
                    }
                )
        )
        .onPreferenceChange(ContainerWidthKey.self) { containerWidth = $0 }
        .onPreferenceChange(TextWidthKey.self) { textWidth = $0 }
        .accessibilityLabel(text)
        // New text means new measurements and a fresh pass from the start.
        .id(text)
    }

    private var label: some View {
        Text(text)
            .font(font)
            .foregroundColor(color)
            .lineLimit(1)
    }

    private func shift(at date: Date) -> CGFloat {
        let cycle = pause + TimeInterval(distance / speed)
        let elapsed = date.timeIntervalSince(start).truncatingRemainder(dividingBy: cycle)

        return CGFloat(max(0, elapsed - pause)) * speed
    }

    /// Soft edges on whichever side has text hiding behind it. The leading edge
    /// only fades once the text has moved, so the first letters read crisply
    /// during the pause.
    private func edgeMask(leadingFaded: Bool) -> some View {
        HStack(spacing: 0) {
            LinearGradient(
                colors: [leadingFaded ? .clear : .black, .black],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: fade)

            Color.black

            LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: fade)
        }
    }

    private struct ContainerWidthKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
    }

    private struct TextWidthKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
    }
}

// MARK: - Cell

class FastDecisionTableViewCell: BaseTableViewCell {

    // The nib still connects these, so they stay declared - removing an outlet a
    // nib references crashes at load. The nib's own layout is hidden and the row
    // is drawn by `FastDecisionRowView` instead.
    @IBOutlet private weak var mimoImageView: UIImageView!
    @IBOutlet private weak var nameLabel: UILabel!
    @IBOutlet private weak var locationLabel: UILabel!
    @IBOutlet private weak var distanceLabel: UILabel!
    @IBOutlet private weak var batteryImageView: UIImageView!
    @IBOutlet private weak var batteryPercentLabel: UILabel!
    @IBOutlet private weak var durationLabel: UILabel!
    @IBOutlet private weak var batteryView: UIView!
    @IBOutlet private weak var qrLabel: UILabel!
    @IBOutlet private weak var qrView: UIView!

    /// Row height the sheet gives every row - see
    /// `HomeFastDecisionSheetViewController.heightForRowAt`.
    static let rowHeight: CGFloat = 112.0

    private let addressHelper = AddressHelper()
    private lazy var host = UIHostingController(rootView: FastDecisionRowView(row: nil))

    private var row: FastDecisionRow?
    /// A recycled cell must not accept the address its previous occupant asked
    /// for; only the newest request wins.
    private var addressRequest = UUID()

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        installHost()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        addressRequest = UUID()
        row = nil
        host.rootView = FastDecisionRowView(row: nil)
    }

    private func installHost() {
        guard host.view.superview == nil else { return }

        contentView.subviews.forEach { $0.isHidden = true }

        host.view.translatesAutoresizingMaskIntoConstraints = false
        host.view.backgroundColor = .clear
        contentView.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: contentView.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func apply(_ row: FastDecisionRow) {
        self.row = row
        host.rootView = FastDecisionRowView(row: row)
    }

    // MARK: - Products

    func set(scooter: ScooterResult?, currentLocation: CLLocationCoordinate2D?) {
        guard let scooter else { return }

        apply(
            FastDecisionRow(
                imageName: "Mimo_scooter_New",
                title: "MAX PLUSE",
                code: scooter.qr,
                address: nil,
                awaitsAddress: true,
                chips: [
                    distanceChip(from: currentLocation, to: scooter.coordinate),
                    FastDecisionRow.Chip(
                        systemImage: "clock",
                        text: scooter.remainingMileage.prettyPrintedWithoutRange
                    )
                ],
                status: .reading(
                    image: scooter.batteryPercent.image,
                    text: scooter.batteryPercent.percentPrettyPrinted
                )
            )
        )

        loadAddress(for: scooter.coordinate)
    }

    func set(bike: BikeResult?, currentLocation: CLLocationCoordinate2D?) {
        guard let bike else { return }

        // A bike reports voltage, not a percentage - the model turns that into the
        // time estimate the rest of the app shows, which is the useful half anyway.
        apply(
            FastDecisionRow(
                imageName: "Mimo_bike_New",
                title: "BIKE",
                code: bike.qr,
                address: nil,
                awaitsAddress: true,
                chips: [
                    distanceChip(from: currentLocation, to: bike.coordinate),
                    FastDecisionRow.Chip(systemImage: "clock", text: "≈ \(bike.timePrettyPrinted)")
                ],
                status: nil
            )
        )

        loadAddress(for: bike.coordinate)
    }

    func set(charger: ChargingStation, currentLocation: CLLocationCoordinate2D?) {
        var chips = [distanceChip(from: currentLocation, to: charger.coordinate)]

        // Opening hours decide the trip as much as the distance does for a station
        // that sits inside a venue.
        if let hours = charger.workingHours, isMeaningful(hours) {
            chips.append(FastDecisionRow.Chip(systemImage: "clock", text: hours))
        }

        let availableBanks = charger.availablePowerBanksCount
        let slotsTitle = availableBanks == 1 ? "MOBILE_charger.slot".localized() : "MOBILE_charger.slots".localized()
        let hasBanks = availableBanks > 0

        apply(
            FastDecisionRow(
                imageName: "mimo_charger_station",
                title: charger.destinationName ?? "--",
                code: charger.qr,
                address: charger.destinationAddress,
                chips: chips,
                // An empty cabinet is the one case worth stopping a rider, so it is
                // the only one that turns red.
                status: .capsule(
                    text: "\(availableBanks) \(slotsTitle)",
                    background: Color(hasBanks ? "stateAvailable" : "stateUnAvailable"),
                    foreground: Color(hasBanks ? "stateAvailableTitle" : "stateUnAvailableTitle")
                )
            )
        )
    }

    func set(evCharger: EVChargingStation, currentLocation: CLLocationCoordinate2D?) {
        var chips = [distanceChip(from: currentLocation, to: evCharger.coordinate)]

        if let connector = evCharger.connectors.first {
            let power = Int(connector.power.rounded())
            let connectorText = power > 0
                ? "\(connector.type.title) · \(power) \("EV_CHARGER_kw".localized())"
                : connector.type.title
            chips.append(FastDecisionRow.Chip(systemImage: "bolt.fill", text: connectorText))

            if connector.pricePerKW > 0, isMeaningful(evCharger.currency) {
                chips.append(
                    FastDecisionRow.Chip(
                        systemImage: nil,
                        text: "\(price(connector.pricePerKW)) \(evCharger.currency)/\("EV_CHARGER_kw".localized())"
                    )
                )
            }
        }

        let state = evCharger.connectors.first?.state
        let style = connectorStateStyle(state)

        apply(
            FastDecisionRow(
                imageName: "mimo_ev_charger_station",
                title: evCharger.destinationName,
                // Station ids are long and never printed on the unit; the tail is
                // what the EV screens already show.
                code: String(evCharger.id.suffix(4)),
                address: isMeaningful(evCharger.destinationAddress) ? evCharger.destinationAddress : nil,
                chips: chips,
                status: .capsule(text: style.title, background: style.background, foreground: style.foreground)
            )
        )
    }

    // MARK: - Row content helpers

    /// Distance is what a fast decision turns on, so it leads the chip strip. The
    /// walking estimate is only added while walking there is still plausible.
    private func distanceChip(
        from currentLocation: CLLocationCoordinate2D?,
        to coordinate: CLLocationCoordinate2D
    ) -> FastDecisionRow.Chip {
        guard let currentLocation else {
            return FastDecisionRow.Chip(systemImage: "figure.walk", text: "-")
        }

        let meters = currentLocation.clLocation.distance(from: coordinate.clLocation)
        var text = meters.prettyDistance

        if meters <= 2000 {
            let minutes = max(1, Int((meters / 80).rounded()))
            text += " · \(minutes) \("MOBILE_guest_map_minutes".localized().lowercased())"
        }

        return FastDecisionRow.Chip(systemImage: "figure.walk", text: text)
    }

    private func loadAddress(for coordinate: CLLocationCoordinate2D) {
        let request = UUID()
        addressRequest = request

        let helper = addressHelper

        Task { @MainActor [weak self] in
            let address = try? await helper.getAddress(for: coordinate, fullAddress: false)

            guard let self, self.addressRequest == request, var row = self.row else { return }

            row.address = address
            row.awaitsAddress = false
            self.apply(row)
        }
    }

    /// The EV payload uses `-- --` where a field is missing.
    private func isMeaningful(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        return !trimmed.isEmpty && trimmed != "-- --" && trimmed != "--"
    }

    private func price(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(format: "%.2f", value)
    }

    private func connectorStateStyle(
        _ state: EVConnectorState?
    ) -> (title: String, background: Color, foreground: Color) {
        switch state {
        case .available:
            return ("EV_CHARGER_connector_state_available".localized(),
                    Color("stateAvailable"), Color("stateAvailableTitle"))
        case .preparing:
            return ("EV_CHARGER_connector_state_preparing".localized(),
                    Color("statePreparing"), Color("statePreparingTitle"))
        case .charging:
            return ("EV_CHARGER_connector_state_charging".localized(),
                    Color("stateCharging"), Color("stateChargingTitle"))
        case .finishing:
            return ("EV_CHARGER_connector_state_finishing".localized(),
                    Color("stateFinishing"), Color("stateFinishingTitle"))
        case .suspendedEvse, .suspendedEv:
            return ("EV_CHARGER_connector_state_suspended".localized(),
                    Color("stateSuspended"), Color("stateSuspendedTitle"))
        case .reserved, .unavailable, .faulted, .none:
            return ("EV_CHARGER_connector_state_unavailable".localized(),
                    Color("stateUnAvailable"), Color("stateUnAvailableTitle"))
        }
    }
}
