//
//  MimoWalletViewModel.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 28.04.24.
//

import Combine

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
    @Published private(set) var balance: String = "0.0"
    @Published private(set) var isBalanceNegative: Bool = false
    @Published private(set) var freeMinutes: String = "0"
    
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
    let transactionListViewModel: TransactionListViewModel = TransactionListViewModel(worker: TransactionWorker())
    
    init(worker: WalletWorkerProtocol, productType: MimoProductType? = nil) {
        self.worker = worker
        self.productType = productType
        super.init()
        setupUI()
    }
    
    func setupUI() {
        productItemViewModels = ProductItemMapper.mapProductItems(productType: productType)
    }
    
    func loadData() {
        Publishers.Zip5(worker.loadPaymentMethods(), worker.loadBalance(), worker.loadFinancialState(), worker.getUser(), worker.getAccount())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.mimoError = error
                }
            } receiveValue: { [weak self] paymentMethods, wallet, financialState, user, account in
                self?.handleWalletResponse(paymentMethods: paymentMethods, wallet: wallet, financialState: financialState)
                
                self?.user = user
                self?.freeMinutes = String(format: "%.1f", account.minutes ?? 0)
            }
            .store(in: &BAG)
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
        self.wallet = wallet
        self.financialState = financialState
        
        self.currency = wallet.currency.currencyName
        
        let balance = (wallet.balance - (financialState.additional ?? 0))
        self.balance = String(format: "%.2f", balance)
        self.isBalanceNegative = balance < 0
        
        self.paymentMethods = paymentMethods
        self.cardPaymentMethods = paymentMethods.filter { $0.type == .card }
        self.otherPaymentMethods = paymentMethods.filter { $0.type != .card }
        
        if let card = wallet.card {
            selectedPaymentMethod = .none
        } else {
            selectedPaymentMethod = otherPaymentMethods.first
        }
        
        self.phoneNumber = wallet.id
    }
}
