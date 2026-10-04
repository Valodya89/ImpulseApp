//
//  HistoryViewModel.swift
//  MimoBike
//
//  Created by Albert Mnatsakanyan on 7/20/25.
//

import Combine

final class HistoryViewModel: MimoBaseViewModel, ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let coordinatoor: EVChargerCoordinator
    private let worker: TripWorkerProtocol
    private let walletWorker: WalletWorkerProtocol
    private let messageService: MessageServiceProtocol
    
    /// Outstanding debt, shown above the list; `nil` when the account is clear.
    @Published private(set) var debt: Debt?
    /// Set while the attached card is being charged so the pay button can't be
    /// tapped twice for the same debt.
    @Published private(set) var isPayingDebt: Bool = false
    /// Raised when there is no card on file: the wallet opens with the debt
    /// pre-filled so the user tops up by whatever method they choose.
    @Published var showWallet: Bool = false
    /// The bank asked for a 3-D Secure / card form before charging; shown in a
    /// web sheet exactly like a normal wallet top-up.
    @Published var attachCardURL: IdentifiableURL?
    @Published var debtPaid: Bool = false
    
    var selectionItems = PickerOption.allCases
    @Published var selectedItem: PickerOption = .charger//.scooter
    
    @Published private(set) var scooterTrips: [ItemSection<TripScooterDataModel>] = []
    @Published private(set) var bikeTrips: [ItemSection<TripBikeDataModel>] = []
    @Published private(set) var chargerRents: [ItemSection<ChargerRentModel>] = []
    @Published private(set) var evChargerRents: [ItemSection<EVChargerRentViewModel>] = []
//    @Published var selectedCellItem: String = ""

    // MARK: Power-bank paging

    /// Page size of `GET /api/rent` (powerbank docs/mobile-api.md "GET /api/rent":
    /// Spring `Pageable`, default `size=20`) - the same as Android and Mimo iOS.
    static let rentPageSize = 20

    /// Pages loaded so far, where the next one starts, and whether the end was
    /// reached. `chargerRents` are the day sections derived from its rows.
    @Published private(set) var chargerState = HistoryPageState<ChargerRentModel>(pageSize: HistoryViewModel.rentPageSize) { $0.id }

    /// Completion of the pull-to-refresh in flight on the charger tab, called
    /// once page 0 (or its error) comes back.
    private var chargerRefreshCompletion: ((Bool) -> Void)?

    init(
        coordinatoor: EVChargerCoordinator,
        worker: TripWorkerProtocol,
        walletWorker: WalletWorkerProtocol = Resolver.resolve(),
        messageService: MessageServiceProtocol = Resolver.resolve()
    ) {
        self.coordinatoor = coordinatoor
        self.worker = worker
        self.walletWorker = walletWorker
        self.messageService = messageService
        super.init()
        
        messageService.subscribe(self, for: .balanceUpdated)
        
//        getScooterTripList()
        refreshCharger()
        observeSelectedItem()
        loadDebt()
    }
    
    override func receive(message: MessageKey) {
        if message == .balanceUpdated {
            loadDebt()
        }
    }
    
    override func unsubscribe() {
        messageService.unsubscribe(self, from: .balanceUpdated)
    }
    
    func back() {
        coordinatoor.dissmiss()
    }

    /// Pull-to-refresh: re-reads the selected tab and the debt, and reports
    /// back once the list (or an error) arrives.
    func reload(completion: @escaping (Bool) -> Void) {
        if selectedItem == .charger {
            // Page 0 again; the rows on screen stay until it replaces them. A
            // pull while the previous one is still out ends the old indicator
            // without a success chime - the new request owns the result now.
            chargerRefreshCompletion?(false)
            chargerRefreshCompletion = completion
            refreshCharger()
            loadDebt()
            return
        }

        let loaded: AnyPublisher<Bool, Never>
        switch selectedItem {
        case .scooter: loaded = $scooterTrips.dropFirst().map { _ in true }.eraseToAnyPublisher()
        case .bike: loaded = $bikeTrips.dropFirst().map { _ in true }.eraseToAnyPublisher()
        case .charger: loaded = $chargerRents.dropFirst().map { _ in true }.eraseToAnyPublisher()
        case .evup: loaded = $evChargerRents.dropFirst().map { _ in true }.eraseToAnyPublisher()
        }
        let failed = $errorMessage.dropFirst().compactMap { $0 }.map { _ in false }

        var delivered = false
        loaded.merge(with: failed)
            .first()
            .timeout(.seconds(15), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                // Timed out without a value: end the indicator, no success chime.
                if case .finished = result, !delivered { completion(false) }
            }, receiveValue: { success in
                delivered = true
                completion(success)
            })
            .store(in: &cancellables)

        itemTapAction(item: selectedItem)
        loadDebt()
    }
    
    // MARK: - Debt
    
    /// Reads the wallet and the financial state together: the debt itself lives
    /// in the financial state, the card on file in the wallet, and the amount
    /// the user still owes is the difference between the two.
    func loadDebt() {
        Publishers.Zip(walletWorker.loadBalance(), walletWorker.loadFinancialState())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.message
                }
            } receiveValue: { [weak self] wallet, financialState in
                self?.debt = Debt(wallet: wallet, financialState: financialState)
            }
            .store(in: &cancellables)
    }
    
    /// With a card on file the debt is charged straight away; without one the
    /// wallet opens pre-filled so the user can top up and clear it.
    func payDebt() {
        guard let debt, !isPayingDebt else { return }
        
        if debt.hasAttachedCard {
            chargeAttachedCard(amount: debt.amount)
        } else {
            showWallet = true
        }
    }
    
    private func chargeAttachedCard(amount: Double) {
        isPayingDebt = true
        MILoader.show()
        
        walletWorker.depositFromAttachedCard(amount: amount)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                MILoader.hide()
                self?.isPayingDebt = false
                
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] wallet, attachCardResponse in
                if wallet != nil {
                    self?.debtPaid = true
                    self?.messageService.publish(.balanceUpdated)
                    self?.loadDebt()
                } else if let attachCardResponse {
                    // Same contract as the wallet: the bank may answer with a
                    // form the user has to complete before the charge goes through.
                    self?.attachCardURL = IdentifiableURL(id: attachCardResponse.formUrl)
                }
            }
            .store(in: &cancellables)
    }
    
    private func observeSelectedItem() {
        $selectedItem
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                print("Selected item changed to: \(newValue)")
                self?.itemTapAction(item: newValue)
            }
            .store(in: &cancellables)
    }
    
    private func itemTapAction(item: PickerOption) {
        switch item {
        case .scooter:
            getScooterTripList()
        case .bike:
            getBikeTripList()
        case .charger:
            // Loaded once; switching back keeps the pages already on screen
            // (a pull reloads). `init` has usually started page 0 already.
            if !chargerState.hasLoaded, !chargerState.isLoading { refreshCharger() }
        case .evup:
            getEvChargerRentList()
        }
    }

    // MARK: - Power-bank paging

    /// A row came on screen: when it is one of the last few, ask for the next
    /// page (unless one is loading, the end was reached or the last one failed).
    func chargerRowAppeared(_ item: ChargerRentModel) {
        guard chargerState.isNearEnd(item), let request = chargerState.beginNextPageIfNeeded() else { return }
        loadChargerPage(request)
    }

    /// First open and pull-to-refresh: page 0 of a fresh list.
    private func refreshCharger() {
        loadChargerPage(chargerState.beginRefresh())
    }

    private func loadChargerPage(_ request: HistoryPageState<ChargerRentModel>.Request) {
        worker.getChargerRentPage(page: request.page, size: request.size)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self, case .failure(let error) = completion else { return }
                // A stale answer (an older refresh, or a page other than the
                // one expected) is dropped without touching the list.
                guard self.chargerState.fail(error.message, for: request) else { return }
                self.errorMessage = error.message
                if request.isRefresh { self.finishChargerRefresh(false) }
            } receiveValue: { [weak self] page in
                guard let self, self.chargerState.receive(page, for: request) else { return }
                self.chargerRents = self.daySections(self.chargerState.items) { $0.start }
                if request.isRefresh { self.finishChargerRefresh(true) }
            }
            .store(in: &cancellables)
    }

    private func finishChargerRefresh(_ success: Bool) {
        let completion = chargerRefreshCompletion
        chargerRefreshCompletion = nil
        completion?(success)
    }

    /// Rows grouped by calendar day, newest day first, titled in the app language.
    private func daySections<Item>(_ items: [Item], start: (Item) -> Int) -> [ItemSection<Item>] {
        let grouped = Dictionary(grouping: items) { item in
            let date = Date(timeIntervalSince1970: TimeInterval(start(item) / 1000))
            return Calendar.current.startOfDay(for: date)
        }

        var locale: Locale = Locale.current
        if let language = StorageManager().fetch(key: .language, type: String.self) {
            locale = Locale(identifier: language)
        }

        // `grouped` is a dictionary - iterating it would put the day sections
        // in an arbitrary order. Use the sorted pairs.
        return grouped.sorted { $0.key > $1.key }.map { (date, items) in
            ItemSection(
                title: date.toString(dateStyle: .medium, timeStyle: .none, locale: locale),
                items: items
            )
        }
    }
    
    private func getScooterTripList() {
        worker.getScooterTripList()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] scooterTrips in
                let grouped = Dictionary(grouping: scooterTrips) { item in
                    let date = Date(timeIntervalSince1970: TimeInterval((item.start ?? 0) / 1000))
                    return Calendar.current.startOfDay(for: date)
                }

                let sorted = grouped.sorted { $0.key > $1.key }
                var locale: Locale = Locale.current
                if let language = StorageManager().fetch(key: .language, type: String.self) {
                    locale = Locale(identifier: language)
                }

                self?.scooterTrips = sorted.map { (date, items) in
                    ItemSection(
                        title: date.toString(dateStyle: .medium, timeStyle: .none, locale: locale),
                        items: items
                    )
                }
                
                print("Scooter trips: \(scooterTrips)")
            }
            .store(in: &cancellables)
    }
    
    private func getBikeTripList() {
        worker.getBikeTripList()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] bikeTrips in
                let grouped = Dictionary(grouping: bikeTrips) { item in
                    let date = Date(timeIntervalSince1970: TimeInterval((item.start ?? 0) / 1000))
                    return Calendar.current.startOfDay(for: date)
                }

                let sorted = grouped.sorted { $0.key > $1.key }
                var locale: Locale = Locale.current
                if let language = StorageManager().fetch(key: .language, type: String.self) {
                    locale = Locale(identifier: language)
                }

                self?.bikeTrips = sorted.map { (date, items) in
                    ItemSection(
                        title: date.toString(dateStyle: .medium, timeStyle: .none, locale: locale),
                        items: items
                    )
                }
                print("Bike trips: \(bikeTrips)")
            }
            .store(in: &cancellables)
    }
    
    private func getEvChargerRentList() {
        worker.getEVChargerRentList()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] evChargerRents in
                let evChargers = evChargerRents.map { $0.toViewMOdel() }
                let grouped = Dictionary(grouping: evChargers) { item in
                    let date = Date(timeIntervalSince1970: TimeInterval((item.start) / 1000))
                    return Calendar.current.startOfDay(for: date)
                }

                let sorted = grouped.sorted { $0.key > $1.key }
                var locale: Locale = Locale.current
                if let language = StorageManager().fetch(key: .language, type: String.self) {
                    locale = Locale(identifier: language)
                }

                self?.evChargerRents = sorted.map { (date, items) in
                    ItemSection(
                        title: date.toString(dateStyle: .medium, timeStyle: .none, locale: locale),
                        items: items
                    )
                }
                print("EvCharger rents: \(evChargerRents)")
            }
            .store(in: &cancellables)
    }
}

extension HistoryViewModel {
    enum PickerOption: String, SegmentedCapsuleOption {
        case scooter = "Scooter"
        case bike = "Bike"
        case charger = "Charger"
        case evup = "EvUp"
        
        var title: String { rawValue.capitalized }
    }
}

extension HistoryViewModel {
    struct ItemSection<T>: Identifiable {
        let id = UUID()
        let title: String
        let items: [T]
    }
}

// MARK: - Page state

/// Page-by-page loading for a history list. The state is a plain value with
/// no side effects so the rules are in one place and the view model only wires
/// requests to it:
///
/// - page 0 first; the next page when the last rows come on screen;
/// - a short page, or `page + 1 >= totalPages`, ends paging;
/// - pull-to-refresh asks for page 0 again and keeps the current rows on
///   screen until it arrives, then replaces them;
/// - an answer for a request that is no longer wanted (an older refresh, a
///   page other than the one expected) is ignored;
/// - rows are de-duplicated by id across pages;
/// - a failed page is retried on the next pull (the counter is not advanced),
///   and a success clears the error.
struct HistoryPageState<Item> {

    /// Every row loaded so far, newest first as the backend sorts them.
    private(set) var items: [Item] = []
    /// The page the next request asks for.
    private(set) var nextPage: Int = 0
    private(set) var isLoading = false
    private(set) var reachedEnd = false
    /// The page 0 request has answered at least once - before that the empty
    /// state must not show, the list is simply not here yet.
    private(set) var hasLoaded = false
    /// Message of the last failed page, cleared by the next successful one.
    private(set) var errorMessage: String?

    /// A refresh is in flight: the rows on screen are the old list and page 0
    /// will replace them.
    private(set) var isRefreshing = false

    /// Bumped by every refresh so a late answer for the previous list is told
    /// apart from the one being waited for.
    private(set) var generation = 0

    let pageSize: Int
    private let identifier: (Item) -> String

    init(pageSize: Int, identifier: @escaping (Item) -> String) {
        self.pageSize = pageSize
        self.identifier = identifier
    }

    /// Nothing is on screen and nothing is coming: show the empty state.
    var isEmpty: Bool { hasLoaded && items.isEmpty && !isLoading }

    /// Rows are on screen and another page may follow: show the footer loader
    /// while it loads.
    var showsFooter: Bool { !items.isEmpty && !reachedEnd && errorMessage == nil }

    // MARK: Requests

    /// A request the view model should send.
    struct Request {
        let page: Int
        let size: Int
        let generation: Int
        let isRefresh: Bool
    }

    /// Pull-to-refresh or the first open: page 0 of a fresh list.
    mutating func beginRefresh() -> Request {
        generation += 1
        isLoading = true
        isRefreshing = true
        reachedEnd = false
        // Whatever was wrong, the rider asked again.
        errorMessage = nil
        return Request(page: 0, size: pageSize, generation: generation, isRefresh: true)
    }

    /// The rows near the end came on screen: ask for the next page, unless one
    /// is already loading, the end was reached, or the last page failed (a
    /// failure stops paging until the next pull, so a dead backend does not
    /// loop on every scroll).
    mutating func beginNextPageIfNeeded() -> Request? {
        guard !isLoading, !reachedEnd, hasLoaded, errorMessage == nil else { return nil }
        isLoading = true
        return Request(page: nextPage, size: pageSize, generation: generation, isRefresh: false)
    }

    /// Whether `item` is one of the rows whose appearance should trigger the
    /// next page: within the last few of the list.
    func isNearEnd(_ item: Item, threshold: Int = 3) -> Bool {
        guard let index = items.firstIndex(where: { identifier($0) == identifier(item) }) else { return false }
        return index >= max(0, items.count - threshold)
    }

    // MARK: Answers

    /// A page came back. Returns false when it was stale and was dropped.
    @discardableResult
    mutating func receive(_ page: HistoryPage<Item>, for request: Request) -> Bool {
        guard request.generation == generation else { return false }
        guard request.isRefresh || request.page == nextPage else { return false }

        isLoading = false
        hasLoaded = true
        errorMessage = nil

        if request.isRefresh {
            isRefreshing = false
            items = dedupe(page.items)
        } else {
            items = dedupe(items + page.items)
        }

        nextPage = request.page + 1
        reachedEnd = page.isLast
        return true
    }

    /// The request failed. The page counter stays, so the same page is asked
    /// for again on the next pull; the rows already loaded stay on screen.
    @discardableResult
    mutating func fail(_ message: String, for request: Request) -> Bool {
        guard request.generation == generation else { return false }
        guard request.isRefresh || request.page == nextPage else { return false }

        isLoading = false
        isRefreshing = false
        // A failed first load still "has loaded": the empty state with the
        // error alert is more honest than a spinner that never ends.
        hasLoaded = true
        errorMessage = message
        return true
    }

    private func dedupe(_ rows: [Item]) -> [Item] {
        var seen = Set<String>()
        return rows.filter { seen.insert(identifier($0)).inserted }
    }
}

extension HistoryViewModel {
    /// What the user owes right now and how it can be settled.
    struct Debt: Equatable {
        /// Amount still to be paid, after whatever balance the wallet holds.
        let amount: Double
        let currency: String
        /// A card on file lets the debt be charged without leaving the screen.
        let hasAttachedCard: Bool
        
        var amountText: String {
            String(format: "%.2f", amount) + " " + currency
        }
        
        /// `nil` unless the account is in a debt state with something left to pay.
        /// The wallet screen shows `balance - additional` as a negative balance;
        /// this is the same figure with the sign flipped, so both agree.
        init?(wallet: WalletModel, financialState: FinancialStateModel) {
            let isDebtState: Bool
            switch financialState.state {
            case .Debt, .DebtOnDevice, .DebtOnCard:
                isDebtState = true
            case .Success, .ProfileIncomplete, .NoMinimalAmount:
                isDebtState = false
            }
            
            let owed = (financialState.additional ?? 0) - wallet.balance
            guard isDebtState, owed > 0 else { return nil }
            
            self.amount = owed
            self.currency = wallet.currency.currencyNameOrCode ?? wallet.currency
            self.hasAttachedCard = wallet.card != nil
        }
    }
}
