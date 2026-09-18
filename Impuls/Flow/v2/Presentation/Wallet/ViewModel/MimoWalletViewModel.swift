//
//  MimoWalletViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.04.24.
//

import Combine
import Foundation
import UIKit

final class MimoWalletViewModel: MimoBaseViewModel, ObservableObject {
    
    private var BAG = Set<AnyCancellable>()
    
    private let worker: WalletWorkerProtocol
    private let productType: MimoProductType?
    
    private var phoneNumber: String = ""
    
    @Published var amount: String = ""
    
    private(set) var user: UserResponse?
    @Published private(set) var wallet: WalletModel?
    @Published private(set) var financialState: FinancialStateModel?
    
    @Published private(set) var currency: String = ""
    /// Balance, grouped for reading ("12 500", "-1 200.5").
    @Published private(set) var balance: String = "0"
    @Published private(set) var isBalanceNegative: Bool = false
    let transactionListViewModel: TransactionListViewModel = TransactionListViewModel(worker: TransactionWorker())
    @Published private(set) var freeMinutes: String = "0"

    /// True while the first wallet load (or a reload with nothing shown yet)
    /// is in flight, so the screen can draw placeholders instead of zeros.
    @Published private(set) var isLoading: Bool = false
    /// Set when a load fails before anything was shown; the screen offers a
    /// retry instead of an empty wallet.
    @Published private(set) var loadFailed: Bool = false

    /// Promo codes are switched on and off server-side; the entry stays hidden
    /// while the flag says so. Shown until the flag arrives, as the old wallet
    /// showed it.
    @Published private(set) var isPromoAvailable: Bool = true

    /// The newest few transactions, for the inline preview on the wallet.
    @Published private(set) var recentTransactions: [TransactionDTO] = []
    
    @Published private(set) var cardPaymentMethods: [PaymentMethodModel] = []
    @Published private(set) var otherPaymentMethods: [PaymentMethodModel] = []
    @Published private(set) var paymentMethods: [PaymentMethodModel] = []
    @Published var selectedPaymentMethod: PaymentMethodModel?
    
    @Published var attachCardURL: IdentifiableURL?
    
    @Published var promoCode: String = ""
    
    @Published var depositSuccess: Bool = false
    @Published var telcellDepositSuccess: Bool = false
    @Published var easyPayDepositSuccess: Bool = false
    @Published var fastshiftDepositSuccess: Bool = false
    @Published var myAmeriaDepositSuccess: Bool = false
    @Published var promoCodeSuccess: Bool = false
    
    @Published var productItemViewModels: [ProductItemViewModel] = []

    /// - Parameter initialAmount: Pre-fills the top-up field, e.g. with an
    ///   outstanding debt so the user only has to confirm the payment.
    init(worker: WalletWorkerProtocol, productType: MimoProductType? = nil, initialAmount: Double? = nil) {
        self.worker = worker
        self.productType = productType
        super.init()
        setupUI()

        if let initialAmount, initialAmount > 0 {
            amount = Self.amountText(initialAmount)
        }

        transactionListViewModel.$transactions
            .receive(on: DispatchQueue.main)
            .map { Array($0.prefix(MimoWalletViewModel.recentTransactionsLimit)) }
            .assign(to: &$recentTransactions)

        loadPromoAvailability()

        // The scene posts this when the app is reopened by a payment provider's
        // callback URL, so money added through an external redirect shows up
        // without reopening the screen.
        NotificationCenter.default.publisher(for: Constant.Notifications.paymentCallback)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadData()
            }
            .store(in: &BAG)
    }

    /// Amount grouped for reading: "12 500", "1 200.5". At most two decimals.
    static func format(amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = amount.rounded() == amount ? 0 : 2
        formatter.groupingSeparator = " "
        formatter.usesGroupingSeparator = true

        return formatter.string(from: NSNumber(value: amount)) ?? String(amount)
    }

    /// The amount field uses a number pad, so a fractional debt is rounded up
    /// to the next whole unit - rounding down would leave part of it unpaid.
    static func amountText(_ amount: Double) -> String {
        String(Int(amount.rounded(.up)))
    }
    
    func setupUI() {
        productItemViewModels = ProductItemMapper.mapProductItems(productType: productType)
    }
    
    func loadData() {
        if wallet == nil {
            isLoading = true
            loadFailed = false
        } else {
            // Every later load is a refresh after something happened (a top-up,
            // a promo, a redirect back) - the preview should show it too.
            transactionListViewModel.reload()
        }

        Publishers.Zip4(worker.loadPaymentMethods(), worker.loadBalance(), worker.loadFinancialState(), worker.getUser())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.loadFailed = self.wallet == nil
                    self.mimoError = error
                }
            } receiveValue: { [weak self] paymentMethods, wallet, financialState, user in
                self?.handleWalletResponse(paymentMethods: paymentMethods, wallet: wallet, financialState: financialState)

                self?.user = user
            }
            .store(in: &BAG)
    }

    private func loadPromoAvailability() {
        worker.checkPromoStatus()
            .receive(on: DispatchQueue.main)
            .sink { _ in
                // A failed flag read keeps the entry visible; the submit call
                // still validates the code server-side.
            } receiveValue: { [weak self] status in
                self?.isPromoAvailable = status.active
            }
            .store(in: &BAG)
    }

    // MARK: - Derived state for the screen

    static let recentTransactionsLimit = 3

    var amountValue: Double? {
        Double(amount)
    }

    /// The primary button only fires with a real amount; every provider path
    /// rejects zero anyway, this just says so before the tap.
    var canProceed: Bool {
        wallet != nil && (amountValue ?? 0) > 0
    }

    /// Button title: the amount about to be paid once one is typed, otherwise
    /// the generic call to action.
    var proceedTitle: String {
        if let amountValue, amountValue > 0 {
            return "MOBILE_wallet_top_up".localized(fallback: "Top up") + " · " + Self.format(amount: amountValue) + " " + currency
        }
        return "MOBILE_wallet_pay_proceed_to_payment".localized()
    }

    /// One-tap amounts, sized to the wallet's currency.
    var quickAmounts: [Double] {
        switch wallet?.currency.uppercased() {
        case "AMD":
            return [500, 1_000, 2_000, 5_000]
        case "RUB":
            return [100, 300, 500, 1_000]
        case "ARS":
            return [1_000, 2_000, 5_000, 10_000]
        default:
            return [5, 10, 20, 50]
        }
    }

    /// Selecting the attached card: `nil` is what `deposit()` routes to it.
    func selectAttachedCard() {
        selectedPaymentMethod = nil
    }

    func select(_ method: PaymentMethodModel) {
        selectedPaymentMethod = method
    }

    /// Reload after a failed first load, or from the screen's retry.
    func reload() {
        loadData()
    }

    /// Pull-to-refresh: reports back once the wallet (or an error) arrives.
    func reload(completion: @escaping (Bool) -> Void) {
        var delivered = false
        let loaded = $wallet.dropFirst().map { _ in true }
        let failed = $errorMessage.dropFirst().compactMap { $0 }.map { _ in false }

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
            .store(in: &BAG)

        loadData()
    }
    
    func deposit() {
        switch selectedPaymentMethod?.provider {
        case .none:
            depositFromAttachedCard()
        case .idram:
            depositFromIDram()
        case .telcell:
            depositFromTelCell()
        case .fastshift:
            depositFromFastshift()
        case .myameria:
            depositFromMyAmeria()
        case .easypay:
            depositFromEasyPay()
        case .cryptoCloud:
            depositFromCrypto()
        default:
            break
        }
    }
    
    func submit(promoCode: String) {
        worker.submitPromo(code: promoCode)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] _ in
                // The bonus lands on the balance, so re-read it - this is what makes
                // the new amount visible here and everywhere else.
                self?.loadData()
                self?.promoCodeSuccess = true
            }
            .store(in: &BAG)
    }
    
    func deleteAttachedCard() {
        worker.deleteCard()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] _ in
                self?.loadData()
            }
            .store(in: &BAG)
    }
    
    func attachCard(provider: PaymentMethodProvider = .tinkoff ) {
        worker.attachCard(provider: provider)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] attachCardResponse in
                self?.attachCardURL = IdentifiableURL(id: attachCardResponse.formUrl)
            }
            .store(in: &BAG)
    }
    
    private func depositFromAttachedCard() {
        let amount = NSString(string: amount).doubleValue
        
        worker.depositFromAttachedCard(amount: amount)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] (wallet, attachCardResponse) in
                if wallet != nil {
                    self?.loadData()
                    self?.depositSuccess = true
                } else if let attachCardResponse {
                    self?.attachCardURL = IdentifiableURL(id: attachCardResponse.formUrl)
                }
            }
            .store(in: &BAG)
    }
    
    private func depositFromIDram() {
        let amount = NSString(string: amount).doubleValue
        
        guard amount > 0 else {
            errorMessage = "MOBILE_validation_gratherThan0".localized()
            return
        }
        
        if UIApplication.shared.canOpenURL(URL(string: "idramapp://launch?itm=558788989")!) {
            IdramPaymentManager.pay(
                withReceiverName: "MIMO Bike",
                receiverId: "110000222",
                title: phoneNumber,
                amount: amount as NSNumber,
                hasTip: false,
                callbackURLScheme: "mimo://"
            )
        } else {
            errorMessage = "MOBILE_no_idram_app".localized()
        }
    }
    
    private func depositFromTelCell() {
        let amount = NSString(string: amount).doubleValue
        
        guard amount > 0 else {
            errorMessage = "MOBILE_validation_gratherThan0".localized()
            return
        }
        
        worker.depositFromTelCell(amount: amount, phoneNumber: phoneNumber)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] _ in
                self?.telcellDepositSuccess = true
            }
            .store(in: &BAG)
    }
    
    private func depositFromEasyPay() {
        let amount = NSString(string: amount).doubleValue
        
        guard amount > 0 else {
            errorMessage = "MOBILE_validation_gratherThan0".localized()
            return
        }
        
        worker.depositFromEasyPay(amount: amount, phoneNumber: phoneNumber)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] result in
                self?.easyPayDepositSuccess = true
                if UIApplication.shared.canOpenURL(URL(string: result.formUrl)!) {
                    
                } else {
                    self?.errorMessage = "MOBILE_no_idram_app".localized()
                }
            }
            .store(in: &BAG)
    }
    
    private func depositFromFastshift() {
        let amount = NSString(string: amount).doubleValue
        
        guard amount > 0 else {
            errorMessage = "MOBILE_validation_gratherThan0".localized()
            return
        }
        
        worker.depositFromFastshift(amount: amount, phoneNumber: phoneNumber)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] result in
                self?.fastshiftDepositSuccess = true
                if UIApplication.shared.canOpenURL(URL(string: result.formUrl)!) {
                    UIApplication.shared.open(URL(string: result.formUrl)!)
                } else {
                    self?.errorMessage = "MOBILE_no_idram_app".localized()
                }
            }
            .store(in: &BAG)
    }
    
    private func depositFromMyAmeria() {
        let amount = NSString(string: amount).doubleValue
        
        guard amount > 0 else {
            errorMessage = "MOBILE_validation_gratherThan0".localized()
            return
        }
        
        worker.depositFromMyAmeria(amount: amount)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] result in
                self?.myAmeriaDepositSuccess = true
                if UIApplication.shared.canOpenURL(URL(string: result.paymentUrl)!) {
                    UIApplication.shared.open(URL(string: result.paymentUrl)!)
                } else {
                    self?.errorMessage = "MOBILE_no_idram_app".localized()
                }
            }
            .store(in: &BAG)
    }
    
    private func depositFromCrypto() {
        let amount = NSString(string: amount).doubleValue
        
        guard amount >= 1000 else {
            errorMessage = "MOBILE_min_value_to_transfer_crypto".localized()
            return
        }
        
        worker.depositFromCrypto(amount: amount)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] attachCardResponse in
                self?.attachCardURL = IdentifiableURL(id: attachCardResponse.formUrl)
            }
            .store(in: &BAG)
    }
}

extension MimoWalletViewModel {
    
    private func handleWalletResponse(paymentMethods: [PaymentMethodModel], wallet: WalletModel, financialState: FinancialStateModel) {
        let previousBalance = self.wallet?.balance

        self.wallet = wallet
        self.financialState = financialState
        
        self.currency = wallet.currency.currencyName
        
        let balance = (wallet.balance - (financialState.additional ?? 0))
        self.balance = Self.format(amount: balance)
        self.isBalanceNegative = balance < 0

        // A rider sent here by a debt prompt should not have to work out how
        // much clears it: the field opens on that amount, as the old wallet's
        // did. Only on first load and only while nothing has been typed.
        if previousBalance == nil, balance < 0, amount.isEmpty {
            amount = Self.amountText(-balance)
        }
        
        self.paymentMethods = paymentMethods
        self.cardPaymentMethods = paymentMethods.filter { $0.type == .card }
        self.otherPaymentMethods = paymentMethods.filter { $0.type != .card }
        
        if wallet.card != nil {
            selectedPaymentMethod = .none
        } else {
            selectedPaymentMethod = otherPaymentMethods.first
        }
        
        self.phoneNumber = wallet.id

        // Every top-up ends up reloading the wallet here - attached card, promo
        // code, and the redirect/terminal providers once the rider comes back -
        // so broadcasting on an actual change covers all of them at once. Only
        // fires when a balance was already known, so opening the wallet is not
        // treated as a change.
        if let previousBalance, previousBalance != wallet.balance {
            Resolver.resolve(MessageServiceProtocol.self).publish(.balanceUpdated)
        }
    }
}
