//
//  TransactionListView.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/26/25.
//
//  Wallet transaction history, redesigned: totals in and out at the top, an
//  income/outcome filter, then the transactions grouped by day with the day's
//  net movement in the section header. Rows are `TransactionRowView`, shared
//  with the wallet's recent-activity preview so the two read as one thing.
//

import SwiftUI

struct TransactionListView: View {

    @ObservedObject var viewModel: TransactionListViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            MimoSheetHeader(title: "MOBILE_profile_transactions".localized()) { dismiss() }

            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 10, pinnedViews: .sectionHeaders) {
                    if viewModel.isLoading {
                        skeleton
                    } else if viewModel.loadFailed {
                        loadFailedState
                    } else if viewModel.isEmpty {
                        emptyState
                    } else {
                        summaryCard

                        SegmentedCapsulePicker(selected: filterBinding, options: TransactionListViewModel.Filter.allCases)
                            .frame(height: 40)
                            .padding(.top, 2)

                        if viewModel.isFilterEmpty {
                            filterEmptyState
                        } else {
                            ForEach(viewModel.sections) { section in
                                Section {
                                    VStack(spacing: 0) {
                                        ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                                            TransactionRowView(item: item)

                                            if index < section.items.count - 1 {
                                                MimoRowDivider()
                                            }
                                        }
                                    }
                                    .mimoCard()
                                } header: {
                                    sectionHeader(section)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 32)
                .mimoRefreshable { done in
                    viewModel.reload(completion: done)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSecondaryBackground.ignoresSafeArea())
    }

    private var filterBinding: Binding<TransactionListViewModel.Filter> {
        Binding(
            get: { viewModel.filter },
            set: { newValue in
                guard newValue != viewModel.filter else { return }
                VibrateManager.vibrate()
                withAnimation(.easeInOut(duration: 0.25)) {
                    viewModel.filter = newValue
                }
            }
        )
    }

    // MARK: - Pieces

    /// Money in and money out over everything loaded, side by side.
    private var summaryCard: some View {
        HStack(spacing: 0) {
            summaryTile(
                title: "MOBILE_charger.income".localized(fallback: "Income"),
                amount: "+" + MimoWalletViewModel.format(amount: viewModel.totalIncome),
                tint: .successGreen,
                well: .greenTint,
                systemImage: "arrow.down.left"
            )

            Rectangle()
                .fill(Color.dividerColor)
                .frame(width: 1)
                .padding(.vertical, 8)

            summaryTile(
                title: "MOBILE_charger.outcome".localized(fallback: "Outcome"),
                amount: "−" + MimoWalletViewModel.format(amount: viewModel.totalOutcome),
                tint: .appLabel,
                well: .appFill,
                systemImage: "arrow.up.right"
            )
        }
        .mimoCard(padding: 4)
    }

    private func summaryTile(title: String, amount: String, tint: Color, well: Color, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 32, height: 32)
                .background(well)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.robotoRegular12)
                    .foregroundColor(.gray5)
                    .lineLimit(1)

                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(amount)
                        .font(.robotoBold16)
                        .foregroundColor(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)

                    Text(viewModel.currencyTitle)
                        .font(.robotoMedium12)
                        .foregroundColor(.gray5)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Day label on the left, the day's net movement on the right. Pinned
    /// while its card scrolls under it, so it paints the screen ground.
    private func sectionHeader(_ section: TransactionListViewModel.DaySection) -> some View {
        HStack(alignment: .firstTextBaseline) {
            MimoSectionLabel(title: section.title)

            Text(netText(section.netAmount))
                .font(.robotoMedium12)
                .foregroundColor(section.netAmount >= 0 ? .successGreen : .gray5)
                .lineLimit(1)
                .padding(.horizontal, 4)
        }
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(Color.appSecondaryBackground)
    }

    private func netText(_ amount: Double) -> String {
        (amount >= 0 ? "+" : "−") + MimoWalletViewModel.format(amount: abs(amount)) + " " + viewModel.currencyTitle
    }

    // MARK: - States

    private var skeleton: some View {
        VStack(alignment: .leading, spacing: 10) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.appBackground)
                .frame(height: 72)

            Capsule()
                .fill(Color.appBackground)
                .frame(height: 40)

            MimoSectionLabel(title: "Today")
                .padding(.top, 6)

            VStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { index in
                    TransactionRowView(item: TransactionDTO.placeholder(index: index))

                    if index < 3 {
                        MimoRowDivider()
                    }
                }
            }
            .mimoCard()
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
                viewModel.reload()
            } label: {
                Text("MOBILE_try_again".localized(fallback: "Try again"))
                    .padding(.horizontal, 12)
            }
            .buttonStyle(MimoSecondaryButton())
            .frame(maxWidth: 200)
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image("ic_empty_data")

            Text("MOBILE_transactions_empty_title".localized(fallback: "Begin your adventure!"))
                .font(.robotoSemibold16)
                .foregroundColor(.appLabel)

            Text("MOBILE_transactions_empty_description".localized(fallback: "Your transactions will show here once you’ve made your first top-up or trip"))
                .font(.robotoRegular15)
                .foregroundColor(.gray5)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    private var filterEmptyState: some View {
        Text("MOBILE_transactions_filter_empty".localized(fallback: "Nothing here yet"))
            .font(.robotoRegular15)
            .foregroundColor(.gray5)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
    }
}

extension TransactionDTO {

    /// Dummy rows for the redacted loading state.
    static func placeholder(index: Int) -> TransactionDTO {
        TransactionDTO(id: "placeholder-\(index)",
                       amount: 1_000,
                       currency: "AMD",
                       status: "",
                       type: index.isMultiple(of: 2) ? .idramDeposit : .mimoPay,
                       date: Int(Date().timeIntervalSince1970 * 1000))
    }
}
