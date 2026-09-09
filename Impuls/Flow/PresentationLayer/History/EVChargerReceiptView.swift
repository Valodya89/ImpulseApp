//
//  EVChargerReceiptView.swift
//  MimoBike
//
//  Receipt for a finished trip or rent, opened from the history list. One screen
//  for every product - each history model maps itself onto `ReceiptData`.
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
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            handle

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    receiptCard
                        .padding(.horizontal, 16)

                    shareButton
                        .padding(.horizontal, 16)
                }
                .padding(.top, 20)
                // Breathing room under the share button so it never sits against
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
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
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
                .fill(Color.white)
        )
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(receipt.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .padding(14)
                .background(Circle().fill(Color.white))

            Text(receipt.title)
                .font(.robotoSemibold16)
                .foregroundColor(.black)

            Text(receipt.amount)
                .font(.robotoBold24)
                .foregroundColor(.black)

            Text(receipt.dateLine)
                .font(.robotoRegular12)
                .foregroundColor(.black075)
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
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(receipt.amount)
                .font(.robotoSemibold16)
                .foregroundColor(.black)
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
