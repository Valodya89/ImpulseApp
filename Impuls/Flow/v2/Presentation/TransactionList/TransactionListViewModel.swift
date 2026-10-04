//
//  TransactionListViewModel.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/26/25.
//
//  State for the wallet's transaction history: the flat list the backend
//  returns, the income/outcome totals over it, an income/outcome filter, and
//  the filtered list grouped by day for the screen. The wallet's inline
//  preview reads `transactions` straight.
//

import Combine
import Foundation

final class TransactionListViewModel: MimoBaseViewModel, ObservableObject {

    enum Filter: SegmentedCapsuleOption {
        case all
        case income
        case outcome

        var title: String {
            switch self {
            case .all: return "MOBILE_transactions_filter_all".localized(fallback: "All")
            case .income: return "MOBILE_charger.income".localized(fallback: "Income")
            case .outcome: return "MOBILE_charger.outcome".localized(fallback: "Outcome")
            }
        }
    }

    /// One day of transactions, newest first, with the day's net movement.
    struct DaySection: Identifiable {
        let id: Date
        let title: String
        let items: [TransactionDTO]
        let netAmount: Double
    }

    private var cancellables = Set<AnyCancellable>()
    private let worker: TransactionWorkerProtocol

    /// Every transaction, newest first.
    @Published private(set) var transactions: [TransactionDTO] = []
    /// The filtered list grouped by day, newest day first.
    @Published private(set) var sections: [DaySection] = []
    @Published var filter: Filter = .all {
        didSet { rebuildSections() }
    }

    /// True until the first response lands (or while reloading with nothing
    /// shown yet), so the screen draws placeholders.
    @Published private(set) var isLoading: Bool = false
    /// A failed first load; the screen offers a retry.
    @Published private(set) var loadFailed: Bool = false
    private var hasLoaded = false

    init(
        worker: TransactionWorkerProtocol
    ) {
        self.worker = worker
        super.init()

        getTransactionList()
    }

    // MARK: - Derived

    var totalIncome: Double {
        transactions.filter { $0.isIncome }.reduce(0) { $0 + abs($1.amount) }
    }

    var totalOutcome: Double {
        transactions.filter { !$0.isIncome }.reduce(0) { $0 + abs($1.amount) }
    }

    /// Currency for the totals: the rows' own, falling back to the wallet's.
    var currencyTitle: String {
        transactions.first?.currencyTitle ?? UserManager.walletCurrencyTitle
    }

    var isEmpty: Bool {
        hasLoaded && transactions.isEmpty
    }

    /// Transactions exist but none match the current filter.
    var isFilterEmpty: Bool {
        hasLoaded && !transactions.isEmpty && sections.isEmpty
    }

    func back() {
    }

    // MARK: - Loading

    /// Re-reads the list. The wallet calls this after a top-up so its inline
    /// preview shows the new transaction without reopening the screen.
    func reload() {
        getTransactionList()
    }

    /// Pull-to-refresh: reports back once the list (or an error) arrives.
    func reload(completion: @escaping (Bool) -> Void) {
        var delivered = false
        let loaded = $transactions.dropFirst().map { _ in true }
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

        getTransactionList()
    }

    private func getTransactionList() {
        if !hasLoaded {
            isLoading = true
            loadFailed = false
        }

        worker.getTransactionList()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.loadFailed = !self.hasLoaded
                    self.errorMessage = error.message
                }
            } receiveValue: { [weak self] transactions in
                guard let self else { return }
                self.hasLoaded = true
                // A card attachment is the bank's verification charge when a card is
                // linked - neither a top-up nor a purchase. Product decision
                // 2026-10-04: hide every `<PROVIDER>_CARD_ATTACHMENT` row before
                // rows, day totals, the In/Out summary and the wallet preview.
                self.transactions = transactions
                    .filter { !$0.type.rawValue.uppercased().contains("ATTACHMENT") }
                    .sorted { $0.date > $1.date }
                self.rebuildSections()
            }
            .store(in: &cancellables)
    }

    // MARK: - Grouping

    private func rebuildSections() {
        let visible: [TransactionDTO]
        switch filter {
        case .all: visible = transactions
        case .income: visible = transactions.filter { $0.isIncome }
        case .outcome: visible = transactions.filter { !$0.isIncome }
        }

        let calendar = Calendar.current
        let grouped = Dictionary(grouping: visible) { calendar.startOfDay(for: $0.dateValue) }

        var locale: Locale = Locale.current
        if let language = StorageManager().fetch(key: .language, type: String.self) {
            locale = Locale(identifier: language)
        }

        sections = grouped
            .sorted { $0.key > $1.key }
            .map { day, items in
                DaySection(
                    id: day,
                    // Relative formatting gives "Today" / "Yesterday" in the
                    // rider's language and a plain date otherwise.
                    title: day.toString(dateStyle: .medium, timeStyle: .none, isRelative: true, locale: locale),
                    items: items.sorted { $0.date > $1.date },
                    netAmount: items.reduce(0) { $0 + ($1.isIncome ? abs($1.amount) : -abs($1.amount)) }
                )
            }
    }
}
