//
//  EVChargerReceiptView.swift
//  MimoBike
//
//  Receipt for a finished trip or rent, opened from the history list and shown
//  as the end-of-session summary the moment a rent ends. One screen for every
//  product - each history / session model maps itself onto `ReceiptData`.
//

import SwiftUI

// MARK: - Receipt content

struct ReceiptRow: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct ReceiptSection: Identifiable {
    let id = UUID()
    let rows: [ReceiptRow]
}

/// Everything the receipt screen draws. Products differ only in what they put in
/// here, never in how it is laid out.
struct ReceiptData: Identifiable {
    let id: String
    let iconName: String
    let title: String
    let amount: String
    let dateLine: String
    /// The code the rider recognises - scooter QR, station QR - shown in a pill.
    let codeTitle: String?
    let code: String?
    let sections: [ReceiptSection]
}

// MARK: - Screen

struct ReceiptView: View {

    let receipt: ReceiptData
    /// Title of the primary button under the card. Set by the end-of-session
    /// summary ("Thank you"); the history receipt has none and keeps the yellow
    /// share button as its only action.
    var doneTitle: String? = nil
    /// Primary action of the end-of-session summary. Close (x) and this button
    /// end the screen the same way.
    var onDone: (() -> Void)? = nil
    let onClose: () -> Void

    private var isSummary: Bool { onDone != nil }

    var body: some View {
        VStack(spacing: 0) {
            handle

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    receiptCard
                        .padding(.horizontal, 16)

                    if isSummary {
                        VStack(spacing: 12) {
                            quietShareButton

                            doneButton
                        }
                        .padding(.horizontal, 16)
                    } else {
                        shareButton
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.top, 20)
                // Breathing room under the buttons so they never sit against
                // the bottom edge on a scrolled-to-end receipt.
                .padding(.bottom, 100)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.evBgColor.ignoresSafeArea())
    }

    // MARK: - Chrome

    private var handle: some View {
        ZStack {
            Capsule()
                .fill(Color.evStroke)
                .frame(width: 40, height: 4)

            HStack {
                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray6)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.evBgColor))
                }
                .padding(.trailing, 16)
            }
        }
        .padding(.top, 12)
    }

    private var shareButton: some View {
        Button {
            ReceiptSharing.share(receipt: receiptCard)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))

                Text("MOBILE_history_detail_share_receipt".localized())
                    .font(.robotoMedium15)
            }
            .foregroundColor(.onBrandLabel)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Capsule().fill(Color.brandYellow))
        }
    }

    /// Quiet secondary share of the summary - the yellow belongs to the primary
    /// button there. Shares the very same card image as the history receipt.
    private var quietShareButton: some View {
        Button {
            ReceiptSharing.share(receipt: receiptCard)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .semibold))

                Text("MOBILE_history_detail_share_receipt".localized())
                    .font(.robotoBold15)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundColor(.appLabel)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Capsule().fill(Color.appBackground))
            .overlay(Capsule().stroke(Color.evStroke, lineWidth: 1))
        }
    }

    private var doneButton: some View {
        Button {
            onDone?()
        } label: {
            Text(doneTitle ?? "")
                .font(.robotoBold15)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundColor(.onBrandLabel)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Capsule().fill(Color.brandYellow))
        }
    }

    // MARK: - Receipt

    /// The part that gets shared as an image, so it carries its own background and
    /// never depends on the screen behind it.
    private var receiptCard: some View {
        VStack(spacing: 0) {
            header

            VStack(spacing: 18) {
                if let code = receipt.code, !code.isEmpty {
                    dashedSeparator

                    codeRow(title: receipt.codeTitle ?? "", code: code)
                }

                ForEach(receipt.sections) { section in
                    dashedSeparator

                    VStack(spacing: 14) {
                        ForEach(section.rows) { item in
                            row(title: item.title, value: item.value)
                        }
                    }
                }

                dashedSeparator

                totalRow
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appBackground)
        )
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(receipt.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .padding(14)
                .background(Circle().fill(Color.appBackground))

            Text(receipt.title)
                .font(.robotoSemibold16)
                .foregroundColor(.appLabel)

            Text(receipt.amount)
                .font(.robotoBold24)
                .foregroundColor(.appLabel)

            Text(receipt.dateLine)
                .font(.robotoRegular12)
                .foregroundColor(.label075)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(
            Color.brandYellow
                .cornerRadius(20, corners: [.topLeft, .topRight])
        )
    }

    private func codeRow(title: String, code: String) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.robotoRegular14)
                .foregroundColor(.evText6)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Image(.qrIcon)

                Text(code)
                    .lineLimit(1)
                    .font(.robotoMedium14)
                    .foregroundColor(.evText9)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .roundedBorderMedium(color: .evbrandCyan80, lineWidth: 1)
        }
    }

    private var totalRow: some View {
        HStack(spacing: 12) {
            Text("MOBILE_history_detail_total".localized())
                .font(.robotoSemibold16)
                .foregroundColor(.appLabel)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(receipt.amount)
                .font(.robotoSemibold16)
                .foregroundColor(.appLabel)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.brandYellow))
        }
    }

    private func row(title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(.robotoRegular14)
                .foregroundColor(.evText6)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(.robotoMedium14)
                .foregroundColor(.evText9)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private var dashedSeparator: some View {
        Line()
            .stroke(Color.evStroke, style: StrokeStyle(lineWidth: 1, dash: [5]))
            .frame(height: 1)
    }
}

// MARK: - Formatting shared by every product

enum ReceiptFormat {

    /// Every history payload carries epoch milliseconds.
    static func time(milliseconds: Int) -> String {
        DateFormatter.hoursMinutesFormatter.string(from: date(milliseconds: milliseconds))
    }

    static func fullDate(milliseconds: Int) -> String {
        date(milliseconds: milliseconds).toString(dateStyle: .medium, timeStyle: .short)
    }

    static func duration(fromMilliseconds start: Int, toMilliseconds end: Int) -> String {
        let minutes = max(0, (end - start) / 60_000)
        let hours = minutes / 60

        let hoursUnit = "MOBILE_history_detail_hours_short".localized()
        let minutesUnit = "MOBILE_history_detail_minutes_short".localized()

        if hours > 0, minutes % 60 > 0 { return "\(hours)\(hoursUnit) \(minutes % 60)\(minutesUnit)" }
        if hours > 0 { return "\(hours)\(hoursUnit)" }
        return "\(minutes)\(minutesUnit)"
    }

    static func distance(meters: Int) -> String {
        meters >= 1000
            ? String(format: "%.1f", Double(meters) / 1000) + " " + "MOBILE_history_detail_km".localized()
            : "\(meters) " + "MOBILE_history_detail_m".localized()
    }

    /// Amount plus the currency the rider's wallet is in - the trip payloads carry
    /// no currency of their own.
    static func walletAmount(_ amount: Double?) -> String {
        String(format: "%.2f", amount ?? 0) + " " + UserManager.walletCurrencyTitle
    }

    /// "00:12:34" - the padded h:m:s an end-of-session summary shows, where
    /// seconds still matter for a rent that just closed.
    static func clock(seconds: TimeInterval) -> String {
        DateComponentsFormatter.hmsFormatter.string(from: max(0, seconds)) ?? "00:00:00"
    }

    /// Date line of an end-of-session summary: the start when the payload has
    /// one; a session that never started is summarised the moment it ends, so
    /// "now" is the honest date to print.
    static func dateLineOrNow(milliseconds: Int, now: Date = Date()) -> String {
        let stamp = milliseconds > 0 ? milliseconds : Int(now.timeIntervalSince1970 * 1000)
        return fullDate(milliseconds: stamp)
    }

    /// Amount in the currency the backend priced it in, falling back to the
    /// rider's wallet currency.
    static func amount(_ amount: Double?, currency: String?) -> String {
        String(format: "%.2f", amount ?? 0) + " " + UserManager.currencyTitle(currency)
    }

    private static func date(milliseconds: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000.0)
    }
}

// MARK: - Product adapters

extension EVChargerRentViewModel: Identifiable {}

extension EVChargerRentViewModel {

    var receipt: ReceiptData {
        var stationRows: [ReceiptRow] = []
        if let name = destinationName, !name.isEmpty {
            stationRows.append(ReceiptRow(title: "MOBILE_history_detail_station".localized(), value: name))
        }
        if let address = destinationAddress, !address.isEmpty {
            stationRows.append(ReceiptRow(title: "MOBILE_history_detail_address".localized(), value: address))
        }
        if let connector = connectorType?.title {
            stationRows.append(ReceiptRow(title: "MOBILE_history_detail_connector".localized(), value: connector))
        }

        let sessionRows = [
            ReceiptRow(title: "EV_CHARGER_charged".localized(),
                       value: "\(kwtsCharged.stringValueRoundedUp2) \("EV_CHARGER_kw".localized())"),
            ReceiptRow(title: "MOBILE_history_detail_start".localized(), value: ReceiptFormat.time(milliseconds: start)),
            ReceiptRow(title: "MOBILE_history_detail_end".localized(), value: ReceiptFormat.time(milliseconds: end)),
            ReceiptRow(title: "MOBILE_history_detail_duration".localized(),
                       value: ReceiptFormat.duration(fromMilliseconds: start, toMilliseconds: end))
        ]

        return ReceiptData(
            id: id.uuidString,
            iconName: "mimo_product_ev_charger",
            title: "MOBILE_history_detail_charging_complete".localized(),
            amount: "\(amount.stringValueRoundedUp2) \(UserManager.currencyTitle(currency))",
            dateLine: ReceiptFormat.fullDate(milliseconds: start),
            codeTitle: "MOBILE_history_detail_charger_id".localized(),
            code: stationId,
            sections: [ReceiptSection(rows: stationRows), ReceiptSection(rows: sessionRows)]
                .filter { !$0.rows.isEmpty }
        )
    }
}

extension ChargerRentModel {

    var receipt: ReceiptData {
        ReceiptData(
            id: id,
            iconName: "mimo_charger_station",
            title: "MOBILE_history_detail_rent_complete".localized(),
            amount: ReceiptFormat.walletAmount(payment.amount),
            dateLine: ReceiptFormat.fullDate(milliseconds: start),
            codeTitle: "MOBILE_history_detail_station".localized(),
            code: startStationCode,
            sections: [
                ReceiptSection(rows: [
                    ReceiptRow(title: "MOBILE_history_detail_taken_from".localized(), value: startStationCode),
                    ReceiptRow(title: "MOBILE_history_detail_returned_to".localized(), value: endStationCode)
                ]),
                ReceiptSection(rows: [
                    ReceiptRow(title: "MOBILE_history_detail_start".localized(), value: ReceiptFormat.time(milliseconds: start)),
                    ReceiptRow(title: "MOBILE_history_detail_end".localized(), value: ReceiptFormat.time(milliseconds: end)),
                    ReceiptRow(title: "MOBILE_history_detail_duration".localized(),
                               value: ReceiptFormat.duration(fromMilliseconds: start, toMilliseconds: end))
                ])
            ]
        )
    }
}

extension RentedCharger {

    /// End-of-rent summary of a power bank, built from the RENT_ENDED payload
    /// (powerbank docs/events.md: startStationQR, billingDetails.amount,
    /// currentTariff.priceName, activePackage). Same card as the history receipt
    /// of the rent; only the rows differ: the station pill, then the power bank,
    /// the plan it was billed on, and the start / end / HH:MM:SS duration.
    /// - Parameter currency: the wallet currency the caller knows; the rent
    ///   payload carries none of its own.
    func receipt(currency: String?, now: Date = Date()) -> ReceiptData {
        let rent = data
        let start = Int(rent?.start ?? 0)
        let end = Int(rent?.end ?? 0)
        let billing = rent?.billingDetails

        // A valid package names the plan; otherwise the tariff the rent was
        // billed on. Unknown until the backend says - never a blank cell.
        var plan = billing?.currentTariff?.priceName
        if rent?.activePackageValid == true, let package = rent?.activePackage?.name, !package.isEmpty {
            plan = package
        }

        let powerBankId = powerBank?.id ?? rent?.powerBank

        let rentRows = [
            ReceiptRow(title: "MOBILE_history_detail_charger_id".localized(),
                       value: powerBankId.flatMap { $0.isEmpty ? nil : $0 } ?? "-"),
            ReceiptRow(title: "MOBILE_history_detail_plan".localized(fallback: "Plan"),
                       value: plan.flatMap { $0.isEmpty ? nil : $0 } ?? "-")
        ]

        let timeRows = [
            ReceiptRow(title: "MOBILE_history_detail_start".localized(),
                       value: start > 0 ? ReceiptFormat.time(milliseconds: start) : "-"),
            ReceiptRow(title: "MOBILE_history_detail_end".localized(),
                       value: end > 0 ? ReceiptFormat.time(milliseconds: end) : "-"),
            ReceiptRow(title: "MOBILE_history_detail_duration".localized(),
                       value: ReceiptFormat.clock(seconds: TimeInterval(max(0, end - start)) / 1000))
        ]

        let stationCode = rent?.startStationQR ?? ""

        return ReceiptData(
            id: rent?.id ?? UUID().uuidString,
            iconName: "mimo_charger_station",
            title: "MOBILE_history_detail_rent_complete".localized(),
            amount: ReceiptFormat.amount(billing?.amount, currency: currency),
            dateLine: ReceiptFormat.dateLineOrNow(milliseconds: start, now: now),
            codeTitle: "MOBILE_history_detail_station".localized(),
            code: stationCode.isEmpty ? nil : stationCode,
            sections: [ReceiptSection(rows: rentRows), ReceiptSection(rows: timeRows)]
        )
    }
}

extension TripScooterDataModel {

    var receipt: ReceiptData {
        let startTime = start ?? 0
        let endTime = end ?? 0

        var rideRows = [
            ReceiptRow(title: "MOBILE_history_detail_start".localized(), value: ReceiptFormat.time(milliseconds: startTime)),
            ReceiptRow(title: "MOBILE_history_detail_end".localized(), value: ReceiptFormat.time(milliseconds: endTime)),
            ReceiptRow(title: "MOBILE_history_detail_duration".localized(),
                       value: ReceiptFormat.duration(fromMilliseconds: startTime, toMilliseconds: endTime))
        ]
        if let distance, distance > 0 {
            rideRows.append(ReceiptRow(title: "MOBILE_history_detail_distance".localized(), value: ReceiptFormat.distance(meters: distance)))
        }

        return ReceiptData(
            id: id ?? UUID().uuidString,
            iconName: "Mimo_scooter_New",
            title: "MOBILE_history_detail_ride_complete".localized(),
            amount: ReceiptFormat.walletAmount(payment?.amount),
            dateLine: ReceiptFormat.fullDate(milliseconds: startTime),
            codeTitle: "MOBILE_history_detail_scooter".localized(),
            code: scooterQr,
            sections: [ReceiptSection(rows: rideRows)]
        )
    }
}

extension TripBikeDataModel {

    var receipt: ReceiptData {
        let startTime = start ?? 0
        let endTime = end ?? 0

        var rideRows = [
            ReceiptRow(title: "MOBILE_history_detail_start".localized(), value: ReceiptFormat.time(milliseconds: startTime)),
            ReceiptRow(title: "MOBILE_history_detail_end".localized(), value: ReceiptFormat.time(milliseconds: endTime)),
            ReceiptRow(title: "MOBILE_history_detail_duration".localized(),
                       value: ReceiptFormat.duration(fromMilliseconds: startTime, toMilliseconds: endTime))
        ]
        if let distance, distance > 0 {
            rideRows.append(ReceiptRow(title: "MOBILE_history_detail_distance".localized(), value: ReceiptFormat.distance(meters: distance)))
        }

        return ReceiptData(
            id: id,
            iconName: "Mimo_bike_New",
            title: "MOBILE_history_detail_ride_complete".localized(),
            amount: ReceiptFormat.walletAmount(payment?.amount ?? amount),
            dateLine: ReceiptFormat.fullDate(milliseconds: startTime),
            codeTitle: "MOBILE_history_detail_bike".localized(),
            code: bike ?? id,
            sections: [ReceiptSection(rows: rideRows)]
        )
    }
}

// MARK: - Sharing

enum ReceiptSharing {

    /// Width the receipt is rendered at when shared, independent of the device -
    /// the same receipt looks the same coming out of any phone.
    private static let renderWidth: CGFloat = 360

    /// Renders the receipt to an image and hands it to the system share sheet.
    /// An image travels everywhere - Messages, Mail, WhatsApp - without the
    /// receiver needing the app.
    static func share<Receipt: View>(receipt: Receipt) {
        guard let topController = UIApplication.shared.topMostViewController(),
              let image = snapshot(of: receipt.frame(width: renderWidth)) else { return }

        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        // iPad presents this as a popover and crashes without an anchor.
        activityViewController.popoverPresentationController?.sourceView = topController.view
        activityViewController.popoverPresentationController?.sourceRect = CGRect(
            x: topController.view.bounds.midX,
            y: topController.view.bounds.maxY,
            width: 0,
            height: 0
        )

        topController.present(activityViewController, animated: true)
    }

    /// SwiftUI only draws once its hosting view belongs to a window, which is why
    /// rendering a detached view's layer produced a blank image. The hosting view
    /// is parked off screen inside the current window for the one frame it takes
    /// to capture it.
    private static func snapshot<Content: View>(of view: Content) -> UIImage? {
        guard let window = UIApplication.shared.keyWindowInConnectedScenes
                ?? UIApplication.shared.connectedScenes
                    .compactMap({ ($0 as? UIWindowScene)?.windows.first })
                    .first
        else { return nil }

        let controller = UIHostingController(rootView: view)
        guard let hostedView = controller.view else { return nil }

        hostedView.backgroundColor = .clear
        hostedView.frame = CGRect(origin: .zero, size: CGSize(width: renderWidth, height: window.bounds.height))

        var size = hostedView.sizeThatFits(CGSize(width: renderWidth, height: .greatestFiniteMagnitude))
        if size.height <= 1 {
            size = hostedView.systemLayoutSizeFitting(
                CGSize(width: renderWidth, height: UIView.layoutFittingCompressedSize.height),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
        }
        guard size.width > 0, size.height > 0 else { return nil }

        // Off to the left of the window: in the hierarchy, so SwiftUI renders it,
        // but never visible to the user.
        hostedView.frame = CGRect(origin: CGPoint(x: -renderWidth - 50, y: 0), size: size)
        window.addSubview(hostedView)
        hostedView.setNeedsLayout()
        hostedView.layoutIfNeeded()

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        format.opaque = false

        let image = UIGraphicsImageRenderer(size: size, format: format).image { context in
            let drawn = hostedView.drawHierarchy(in: CGRect(origin: .zero, size: size), afterScreenUpdates: true)
            if !drawn {
                // Older devices occasionally refuse the snapshot; the layer tree is
                // populated by now, so this second path produces the same picture.
                hostedView.layer.render(in: context.cgContext)
            }
        }

        hostedView.removeFromSuperview()

        return image
    }
}
