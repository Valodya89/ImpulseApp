//
//  HistoryView.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/20/25.
//

import SwiftUI
import SwiftMessages

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel

    /// The history item whose receipt is open, if any - any product.
    @State private var selectedReceipt: ReceiptData?
    @State private var successMessage: SuccessMessage?
    @State private var errorMessage: ErrorMessage?

    var body: some View {
        VStack(spacing: 0) {
            if let debt = viewModel.debt {
                debtBanner(debt)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }

//            SegmentedCapsulePicker(selected: $viewModel.selectedItem, options: viewModel.selectionItems)
//                .padding([.top, .horizontal], 16)
//
//            switch viewModel.selectedItem {
//            case .scooter:
//                scooterTripsListView()
//            case .bike:
//                bikeTripsListView()
//            case .charger:
                chargerRentsListView()
//            case .evup:
//                evChargerRentsListView()
//            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.evBgColor.ignoresSafeArea())
        .safeAreaInset(edge: .top) { navigationView() }
        .sheet(item: $selectedReceipt) { receipt in
            ReceiptView(receipt: receipt) { selectedReceipt = nil }
        }
        // No card on file: the wallet opens with the debt already typed in, so
        // the user only picks how to top up. Whatever they did there, the banner
        // is refreshed on the way back.
        .sheet(isPresented: $viewModel.showWallet, onDismiss: { viewModel.loadDebt() }) {
            WalletView(
                viewModel: MimoWalletViewModel(
                    worker: Resolver.resolve(),
                    initialAmount: viewModel.debt?.amount
                )
            )
        }
        // The bank wanted a form before charging the attached card.
        .sheet(
            item: $viewModel.attachCardURL,
            onDismiss: {
                Resolver.resolve(MessageServiceProtocol.self).publish(.balanceUpdated)
                viewModel.loadDebt()
            },
            content: { url in
                InAppWebView(url: url.id)
            }
        )
        .onReceive(viewModel.$errorMessage) { error in
            if let error {
                MILoader.hide()
                errorMessage = ErrorMessage(title: "MOBILE__global_attention".localized(), body: error.localized())
            }
        }
        .onReceive(viewModel.$debtPaid) { isPaid in
            if isPaid {
                successMessage = SuccessMessage(
                    title: "MOBILE_global_success_title".localized(),
                    body: "MOBILE_wallet_successfully_replenished".localized()
                )
                viewModel.debtPaid = false
            }
        }
        .swiftMessage(message: $successMessage)
        .swiftMessage(message: $errorMessage)
    }

    // MARK: - Debt

    /// Sits above the list whenever the account owes money: what is owed and a
    /// single way to settle it. It disappears on its own once the debt is paid.
    private func debtBanner(_ debt: HistoryViewModel.Debt) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(Color.mimoRed500)

            VStack(alignment: .leading, spacing: 3) {
                Text("MOBILE_you_have_a_debt".localized())
                    .font(.robotoMedium13)
                    .foregroundColor(Color.gray6)
                    .lineLimit(2)

                Text(debt.amountText)
                    .font(.robotoBold16)
                    .foregroundColor(Color.mimoRed500)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            Button {
                VibrateManager.vibrate()
                viewModel.payDebt()
            } label: {
                Text("MOBILE_pay_debt".localized())
                    .font(.robotoBold14)
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .padding(.horizontal, 18)
                    .frame(height: 38)
                    .background(Capsule().fill(viewModel.isPayingDebt ? Color.black025 : Color.mimoYellow500))
            }
            .disabled(viewModel.isPayingDebt)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.mimoRed500.opacity(0.35), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    /// Day header. The trailing total answers "what did this day cost me?"
    /// without opening a single receipt - the rows below carry the breakdown.
    private func headerView(_ title: String, total: String? = nil) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.robotoSemibold14)
                .foregroundColor(Color.evText9)

            Spacer(minLength: 8)

            if let total, !total.isEmpty {
                Text(total)
                    .font(.robotoMedium13)
                    .foregroundColor(Color.gray6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.evBgColor)
    }

    func scooterTripsListView() -> some View {
        Group {
            if viewModel.scooterTrips.isEmpty {
                emptyDataView
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8, pinnedViews: .sectionHeaders) {

                        ForEach(viewModel.scooterTrips, id: \.title) { section in
                            Section {
                                ForEach(section.items, id: \.id) { item in
                                    scooterView(item)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedReceipt = item.receipt }
                                }
                                .padding(.horizontal, 16)
                            } header: {
                                headerView(
                                    section.title,
                                    total: walletTotal(of: section.items) { $0.payment?.amount }
                                )
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func scooterView(_ item: TripScooterDataModel) -> some View {
        var metrics: [HistoryMetric] = []

        if let start = item.start, let end = item.end, end >= start {
            metrics.append(
                HistoryMetric(
                    systemImage: "clock",
                    text: ReceiptFormat.duration(fromMilliseconds: start, toMilliseconds: end)
                )
            )
        }

        if let distance = item.distance, distance > 0 {
            metrics.append(HistoryMetric(systemImage: "map", text: ReceiptFormat.distance(meters: distance)))
        }

        return historyCard(
            code: item.scooterQr ?? shortCode(item.id),
            timeRange: timeRange(start: item.start, end: item.end),
            amount: ReceiptFormat.walletAmount(item.payment?.amount),
            isAmountMuted: (item.payment?.amount ?? 0) == 0,
            status: statusBadge(item.payment?.status),
            metrics: metrics
        )
    }

    func bikeTripsListView() -> some View {
        Group {
            if viewModel.bikeTrips.isEmpty {
                emptyDataView
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8, pinnedViews: .sectionHeaders) {

                        ForEach(viewModel.bikeTrips, id: \.title) { section in
                            Section {
                                ForEach(section.items, id: \.id) { item in
                                    bikeView(item)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedReceipt = item.receipt }
                                }
                                .padding(.horizontal, 16)
                            } header: {
                                headerView(
                                    section.title,
                                    total: walletTotal(of: section.items) { $0.payment?.amount ?? $0.amount }
                                )
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func bikeView(_ item: TripBikeDataModel) -> some View {
        var metrics: [HistoryMetric] = []

        if let start = item.start, let end = item.end, end >= start {
            metrics.append(
                HistoryMetric(
                    systemImage: "clock",
                    text: ReceiptFormat.duration(fromMilliseconds: start, toMilliseconds: end)
                )
            )
        }

        if let distance = item.distance, distance > 0 {
            metrics.append(HistoryMetric(systemImage: "map", text: ReceiptFormat.distance(meters: distance)))
        }

        let amount = item.payment?.amount ?? item.amount

        return historyCard(
            // Bike trips carry no rider-facing QR, only Mongo ids - a 24-character
            // hex string is noise in a list, so the row shows a short reference and
            // the receipt keeps the full id.
            code: shortCode(item.bike ?? item.id),
            timeRange: timeRange(start: item.start, end: item.end),
            amount: ReceiptFormat.walletAmount(amount),
            isAmountMuted: (amount ?? 0) == 0,
            status: statusBadge(item.payment?.status),
            metrics: metrics
        )
    }

    func chargerRentsListView() -> some View {
        Group {
            if viewModel.chargerRents.isEmpty {
                emptyDataView
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8, pinnedViews: .sectionHeaders) {

                        ForEach(viewModel.chargerRents, id: \.title) { section in
                            Section {
                                ForEach(section.items, id: \.id) { item in
                                    chargerView(item)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedReceipt = item.receipt }
                                }
                                .padding(.horizontal, 16)
                            } header: {
                                headerView(
                                    section.title,
                                    total: walletTotal(of: section.items) { $0.payment.amount }
                                )
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func chargerView(_ item: ChargerRentModel) -> some View {
        var metrics: [HistoryMetric] = [
            HistoryMetric(
                systemImage: "clock",
                text: ReceiptFormat.duration(fromMilliseconds: item.start, toMilliseconds: item.end)
            )
        ]

        // Where the power bank went back is the one fact a rider actually looks
        // for in this list; it was previously only visible inside the receipt.
        let returnedTo = item.endStationCode
        if !returnedTo.isEmpty, returnedTo != item.startStationCode {
            metrics.append(HistoryMetric(systemImage: "arrow.right", text: returnedTo))
        }

        return historyCard(
            code: item.startStationCode,
            timeRange: timeRange(start: item.start, end: item.end),
            amount: ReceiptFormat.walletAmount(item.payment.amount),
            isAmountMuted: (item.payment.amount ?? 0) == 0,
            status: statusBadge(item.payment.status),
            metrics: metrics
        )
    }

    func evChargerRentsListView() -> some View {
        Group {
            if viewModel.evChargerRents.isEmpty {
                emptyDataView
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 8, pinnedViews: .sectionHeaders) {

                        ForEach(viewModel.evChargerRents, id: \.title) { section in
                            Section {
                                ForEach(section.items, id: \.id) { item in
                                    evChargerView(item)
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedReceipt = item.receipt }
                                }
                                .padding(.horizontal, 16)
                            } header: {
                                headerView(section.title, total: evTotal(of: section.items))
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
    }

    private func evChargerView(_ item: EVChargerRentViewModel) -> some View {
        let metrics: [HistoryMetric] = [
            HistoryMetric(
                systemImage: "clock",
                text: ReceiptFormat.duration(fromMilliseconds: item.start, toMilliseconds: item.end)
            ),
            HistoryMetric(
                systemImage: "bolt.fill",
                text: "\(item.kwtsCharged.stringValueRoundedUp2) \("EV_CHARGER_kw".localized())"
            )
        ]

        let place = [item.destinationName, item.destinationAddress]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")

        return historyCard(
            code: item.stationId,
            location: place,
            timeRange: timeRange(start: item.start, end: item.end),
            amount: "\(item.amount.stringValueRoundedUp2) \(UserManager.currencyTitle(item.currency))",
            isAmountMuted: item.amount == 0,
            status: nil,
            trailingChip: item.connectorType?.title,
            metrics: metrics
        )
    }

    // MARK: - The row every product shares

    /// One card shape for scooter, bike, power bank and EV rows: what was used,
    /// when, what it cost, and a strip of the numbers worth scanning. Products
    /// differ only in what they put into `metrics`.
    private func historyCard(
        code: String,
        location: String? = nil,
        timeRange: String?,
        amount: String,
        isAmountMuted: Bool,
        status: HistoryStatusBadge?,
        trailingChip: String? = nil,
        metrics: [HistoryMetric]
    ) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        codeChip(code)

                        if let trailingChip, !trailingChip.isEmpty {
                            Text(trailingChip)
                                .font(.robotoMedium13)
                                .foregroundColor(Color.evText9)
                                .lineLimit(1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.evBgColor))
                        }
                    }

                    if let location, !location.isEmpty {
                        HStack(spacing: 6) {
                            Image(.evLocationMarker)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)

                            Text(location)
                                .font(.robotoRegular12)
                                .foregroundColor(Color.gray6)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }

                    if let timeRange, !timeRange.isEmpty {
                        Text(timeRange)
                            .font(.robotoRegular12)
                            .foregroundColor(Color.gray6)
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 6) {
                    // A free ride is still a fact worth showing, just not worth
                    // shouting - it stays grey instead of full-contrast black.
                    Text(amount)
                        .font(.robotoBold16)
                        .foregroundColor(isAmountMuted ? Color.gray6 : Color.evText9)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    // Colour only means something when it is rare: a paid ride
                    // carries no badge, so yellow/red always signal "look here".
                    if let status {
                        Text(status.title)
                            .font(.robotoMedium12)
                            .foregroundColor(status.foreground)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(status.background))
                    }
                }
            }

            if !metrics.isEmpty {
                Rectangle()
                    .fill(Color.dividerColor)
                    .frame(height: 1)

                HStack(spacing: 16) {
                    ForEach(metrics) { metric in
                        HStack(spacing: 5) {
                            Image(systemName: metric.systemImage)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.gray6)

                            Text(metric.text)
                                .font(.robotoMedium13)
                                .foregroundColor(Color.evText9)
                                .lineLimit(1)
                        }
                    }

                    Spacer(minLength: 0)

                    // The row opens a receipt - without a chevron nothing said so.
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color.gray6)
                }
            }
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
        }
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }

    private func codeChip(_ code: String) -> some View {
        HStack(spacing: 6) {
            Image(.qrIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)

            Text(code)
                .font(.robotoMedium14)
                .foregroundColor(Color.gray5)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .roundedBorderMedium(color: .evbrandCyan80, lineWidth: 1)
    }

    // MARK: - Row formatting

    /// "15:38 – 15:51". The day already sits in the pinned section header, so the
    /// row never repeats the date the way two separate start/end lines did.
    private func timeRange(start: Int?, end: Int?) -> String? {
        guard let start, start > 0 else { return nil }

        let from = ReceiptFormat.time(milliseconds: start)
        guard let end, end > 0, end != start else { return from }

        return "\(from) – \(ReceiptFormat.time(milliseconds: end))"
    }

    /// Mongo ids are unusable as a rider-facing reference; the tail is short
    /// enough to read out and still unique in practice within one list.
    private func shortCode(_ identifier: String?) -> String {
        guard let identifier, !identifier.isEmpty else { return "—" }

        return identifier.count > 6 ? "#" + identifier.suffix(6).uppercased() : identifier
    }

    private func statusBadge(_ status: ScooterPaymentProgress?) -> HistoryStatusBadge? {
        guard let status, status != .success else { return nil }

        return HistoryStatusBadge(
            title: status.userDescirption,
            background: Color(uiColor: status.backgroundColor),
            foreground: Color(uiColor: status.fillColor)
        )
    }

    private func statusBadge(_ status: PaymentProgress?) -> HistoryStatusBadge? {
        guard let status, status != .success else { return nil }

        return HistoryStatusBadge(
            title: status.userDescirption,
            background: Color(uiColor: status.backgroundColor),
            foreground: Color(uiColor: status.fillColor)
        )
    }

    private func walletTotal<Item>(of items: [Item], amount: (Item) -> Double?) -> String? {
        let total = items.reduce(0) { $0 + (amount($1) ?? 0) }
        guard total > 0 else { return nil }

        return ReceiptFormat.walletAmount(total)
    }

    /// EV sessions carry their own currency, so they are summed per day only when
    /// the whole day was charged in one.
    private func evTotal(of items: [EVChargerRentViewModel]) -> String? {
        let currencies = Set(items.map { $0.currency })
        guard let currency = currencies.first, currencies.count == 1 else { return nil }

        let total = items.reduce(0) { $0 + $1.amount }
        guard total > 0 else { return nil }

        return "\(total.stringValueRoundedUp2) \(UserManager.currencyTitle(currency))"
    }

    func navigationView() -> some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 0) {
                Text("MOBILE_profile_history".localized())
                    .font(.robotoBold15)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding()

            Image(.icCloseBig)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .padding(.leading, 18.5)
                .onTapGesture { viewModel.back() }
        }
        .background(Color.white)
    }

    var emptyDataView: some View {
        VStack(spacing: 8) {
            Image("ic_empty_data")

            Text("EV_CHARGER_history_empty_title".localized())
                .font(.robotoSemibold16)
                .foregroundColor(Color.black08)

            Text("EV_CHARGER_history_empty_description".localized())
                .font(.robotoRegular15)
                .foregroundColor(Color.gray8)

        }
        .frame(maxHeight: .infinity)
        .padding(.horizontal, 16)
    }
}

// MARK: - Row content

/// One number in the strip under a history row - a duration, a distance, the
/// energy delivered, the station a power bank went back to.
// `SwiftMessages` ships its own `Identifiable`; the qualified name keeps `ForEach` happy.
private struct HistoryMetric: Swift.Identifiable {
    let id = UUID()
    let systemImage: String
    let text: String
}

/// Shown only when a payment still needs attention; a settled payment has none.
private struct HistoryStatusBadge {
    let title: String
    let background: Color
    let foreground: Color
}
