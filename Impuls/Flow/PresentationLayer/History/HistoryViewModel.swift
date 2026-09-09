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
        getChargerRentList()
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
            getChargerRentList()
        case .evup:
            getEvChargerRentList()
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
    
    private func getChargerRentList() {
        worker.getChargerRentList()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.errorMessage = error.message
                default: break
                }
            } receiveValue: { [weak self] chargerRents in
                let grouped = Dictionary(grouping: chargerRents) { item in
                    let date = Date(timeIntervalSince1970: TimeInterval((item.start) / 1000))
                    return Calendar.current.startOfDay(for: date)
                }

                let sorted = grouped.sorted { $0.key > $1.key }
                var locale: Locale = Locale.current
                if let language = StorageManager().fetch(key: .language, type: String.self) {
                    locale = Locale(identifier: language)
                }

                // `grouped` is a dictionary - iterating it put the day sections in
                // an arbitrary order, unlike every other tab. Use the sorted pairs.
                self?.chargerRents = sorted.map { (date, items) in
                    ItemSection(
                        title: date.toString(dateStyle: .medium, timeStyle: .none, locale: locale),
                        items: items
                    )
                }
                print("Charger rents: \(chargerRents)")
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
