//
//  ShowDebtViewController.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 23.08.22.
//

import UIKit

protocol ShowDebtViewControllerDdelegate: AnyObject {
    func didSelectPayDdebt()
    func didSelectTransfer(wallet: WalletDebts)
    func didSelectTransfer()
}

class ShowDebtViewController: UIViewController, StoryboardInitializable, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wallets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DebtTBCell", for: indexPath) as? DebtTBCell
        cell?.setData(wallet: self.wallets[indexPath.row])
        cell?.delegate = self
        
        return cell!
    }
    

    @IBOutlet weak var debtLabel: UILabel!
    @IBOutlet weak var payDebtBtn: UILocalizedButton!
    
    @IBOutlet weak var debtTb: UITableView!
    weak var delegate: ShowDebtViewControllerDdelegate?
    
    var amount =  0.0
    var wallets: [WalletDebts] = []    
    
    override func viewDidLoad() {
        self.debtTb.isHidden = true
        
        super.viewDidLoad()
       
        updateUI(amount: amount, wallets: wallets)
    }
    
    func updateUI(amount: Double, wallets: [WalletDebts]) {
        self.wallets = wallets
        if wallets.count > 0 {
            self.debtTb.isHidden = false
            debtTb.delegate = self
            debtTb.dataSource = self
            self.debtTb.reloadData()
        }
        DispatchQueue.main.async {
            self.payDebtBtn.layer.cornerRadius = self.payDebtBtn.frame.height / 2
            self.amount = amount
            self.debtLabel.text = "\(amount - (UserManager.share.walletModel?.balance ?? 0.0).rounded()) ֏"
        }
    }
    
    @IBAction func closeActioon(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func payDebtAction(_ sender: UILocalizedButton) {
        UserManager.share.debtAmount = amount
        self.dismiss(animated: true) { [delegate] in
            delegate?.didSelectPayDdebt()
        }
    }
}

extension ShowDebtViewController: DebtTBCellDelegate {
    
    func didSelectTransfer(wallet: WalletDebts) {
        delegate?.didSelectTransfer()
        self.dismiss(animated: true) { [delegate] in
            delegate?.didSelectTransfer(wallet: wallet)
        }
    }
}

// MARK: - Debt screen v2 (SwiftUI)
//
// The redesigned full-screen "Pay your debt" screen, presented over the
// power-bank map when ipay GET /api/state (ipay:docs/mobile-api.md
// 'GET /api/state') reports DEBT or DEBT_ON_DEVICE, and before / after a scan
// refused for a debt (powerbank:docs/error-codes.md 'Rent rule violations':
// SHARING_user_has_debt, SHARING_device_has_debt, SHARING_card_has_debt).
//
//   payable = max(additional - round(balance), 0)
//   card attached && payable > 0  -> "Pay with card ··1234": confirm, then
//                                    PATCH /api/bank/card/attached/deposit {amount}
//   otherwise                      -> "Pay debt": wallet prefilled with payable
//   wallets[] of other accounts    -> account lookup -> transfer prefilled
//
// It cannot be swiped away; X closes it. It closes itself once a fresh state
// no longer reports anything to settle (after the wallet, a transfer or the
// bank form), and right after a successful card charge.

import SwiftUI
import Combine
import SwiftMessages

/// Maps a refused `PATCH /api/bank/card/attached/deposit` to the copy shown in
/// the "Payment failed" alert (ipay:docs/mobile-api.md: 403 IPAY_card_not_exists,
/// 403 IPAY_amount_less_then_acceptable, 402 IPAY_payment_rejected_by_payment_provider /
/// bank.system.exception / getnet.charge.failed or the bank's raw text).
/// The raw bank text is never shown.
enum DebtPaymentFailure {

    static func reason(for message: String) -> String {
        switch message {
        case "IPAY_card_not_exists":
            return "MOBILE_debt_pay_no_card".localized(fallback: "There is no card attached to your wallet.")
        case "IPAY_amount_less_then_acceptable":
            return "MOBILE_debt_pay_below_minimum".localized(fallback: "The amount is below the minimum for a card payment.")
        case "IPAY_payment_rejected_by_payment_provider", "bank.system.exception", "getnet.charge.failed":
            return "MOBILE_debt_pay_declined".localized(fallback: "Your bank declined the payment.")
        default:
            if isTransportFailure(message) {
                return "MOBILE_debt_pay_network".localized(fallback: "No connection. Check your internet and try again.")
            }
            return "MOBILE_debt_pay_failed".localized(fallback: "The payment could not be completed. Try again later.")
        }
    }

    private static func isTransportFailure(_ message: String) -> Bool {
        let markers = ["NetworkSessionErrors", "operation couldn't be completed", "operation couldn’t be completed",
                       "Impuls.", "Error Domain", "Internet", "offline", "timed out", "network connection"]
        return markers.contains { message.range(of: $0, options: .caseInsensitive) != nil }
    }
}

final class DebtScreenViewModel: MimoBaseViewModel, ObservableObject {

    enum Route {
        case paid
        case wallet(amount: Double)
        case transfer(phoneNumber: String, user: ContactsListModel?, debt: Double)
    }

    enum AlertKind: Swift.Identifiable {
        case confirmCardPayment
        case paymentFailed(reason: String)
        case invite(phoneNumber: String)

        var id: String {
            switch self {
            case .confirmCardPayment: return "confirm"
            case .paymentFailed(let reason): return "failed|" + reason
            case .invite(let phoneNumber): return "invite|" + phoneNumber
            }
        }
    }

    @Published private(set) var financialState: FinancialStateModel?
    @Published private(set) var wallet: WalletModel?
    @Published private(set) var isLoading = false
    /// One card charge or one account lookup at a time.
    @Published private(set) var isBusy = false
    @Published var alert: AlertKind?
    /// The bank asked for a form before charging the attached card.
    @Published var attachCardURL: IdentifiableURL?
    @Published var banner: ErrorMessage?
    @Published var successBanner: SuccessMessage?
    @Published var route: Route?

    var close: () -> Void = {}

    private let worker: WalletWorkerProtocol
    private let messageService: MessageServiceProtocol
    private let authRepository = AuthRepository()
    private var cancellables = Set<AnyCancellable>()
    private var isFinished = false

    init(financialState: FinancialStateModel?,
         wallet: WalletModel?,
         worker: WalletWorkerProtocol = Resolver.resolve(),
         messageService: MessageServiceProtocol = Resolver.resolve()) {
        self.financialState = financialState
        self.wallet = wallet
        self.worker = worker
        self.messageService = messageService
        super.init()

        // The wallet sheet publishes this as it goes away and on every top-up;
        // a fresh state then decides whether anything is left to settle.
        messageService.subscribe(self, for: .balanceUpdated)

        if financialState == nil || wallet == nil {
            reload()
        }
    }

    // MARK: Figures

    /// Own open debts, `additional` of GET /api/state (present on DEBT only).
    var debt: Double { financialState?.additional ?? 0 }

    /// What is still to be paid after the wallet balance; never negative.
    var payable: Double { max(debt - (wallet?.balance ?? 0).rounded(), 0) }

    var currency: String {
        guard let code = wallet?.currency else { return "" }
        return code.currencyNameOrCode ?? code
    }

    var cardLast4: String? {
        guard let mask = wallet?.card?.cardMask, mask.count >= 4 else { return nil }
        return String(mask.suffix(4))
    }

    var canPayWithCard: Bool { cardLast4 != nil && payable > 0 }

    /// Debts other accounts left on this phone or bank card (`wallets[]`).
    var otherDebts: [WalletDebts] {
        (financialState?.wallets ?? []).filter { ($0.debtSum ?? 0) > 0 }
    }

    var isInDebt: Bool {
        switch financialState?.state {
        case .Debt, .DebtOnDevice, .DebtOnCard: return true
        default: return false
        }
    }

    /// Only other accounts owe: no hero card and no pay button.
    var showsHero: Bool { payable > 0 || otherDebts.isEmpty }

    var isSettled: Bool { !isInDebt || (payable <= 0 && otherDebts.isEmpty) }

    var amountText: String { MimoWalletViewModel.format(amount: payable) }

    var payWithCardTitle: String {
        Self.fill("MOBILE_debt_pay_with_card".localized(fallback: "Pay with card ··%@"), [cardLast4 ?? ""])
    }

    var confirmationText: String {
        Self.fill("MOBILE_debt_pay_confirm".localized(fallback: "Pay %@ from your card ·%@?"),
                  [MimoWalletViewModel.format(amount: payable.rounded()) + " " + currency, cardLast4 ?? ""])
    }

    // MARK: Loading

    /// Reads the state and the wallet again. Closes the screen when nothing is
    /// left to settle; a failed read keeps it up and says so.
    func reload() {
        guard !isLoading, !isFinished else { return }
        isLoading = true

        Publishers.Zip(worker.loadFinancialState(), worker.loadBalance())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.banner = ErrorMessage(title: "MOBILE__global_attention".localized(),
                                               body: UIViewController.userFacingErrorMessage(from: error.message))
                }
            } receiveValue: { [weak self] financialState, wallet in
                guard let self else { return }
                self.financialState = financialState
                self.wallet = wallet
                if self.isSettled {
                    self.finish()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Actions

    func primaryAction() {
        if canPayWithCard {
            alert = .confirmCardPayment
        } else {
            payWithWallet()
        }
    }

    func payWithWallet() {
        guard payable > 0 else { return }
        route = .wallet(amount: payable)
    }

    /// PATCH /api/bank/card/attached/deposit {amount: payable}; the deposit
    /// pipeline settles the debt first. Success refreshes balances and closes.
    func confirmCardPayment() {
        guard canPayWithCard, !isBusy else { return }
        isBusy = true
        MILoader.show()

        worker.depositFromAttachedCard(amount: payable)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self else { return }
                MILoader.hide()
                self.isBusy = false
                if case .failure(let error) = completion {
                    self.alert = .paymentFailed(reason: DebtPaymentFailure.reason(for: error.message))
                }
            } receiveValue: { [weak self] wallet, attachCardResponse in
                guard let self else { return }
                MILoader.hide()
                self.isBusy = false
                if wallet != nil {
                    self.messageService.publish(.balanceUpdated)
                    self.finish()
                } else if let attachCardResponse {
                    // Same contract as the wallet: the bank may want a form
                    // completed before the charge goes through.
                    self.attachCardURL = IdentifiableURL(id: attachCardResponse.formUrl)
                }
            }
            .store(in: &cancellables)
    }

    func bankFormClosed() {
        messageService.publish(.balanceUpdated)
        reload()
    }

    /// A debt row: look the account up (accounts GET /api/user/{phone}, the
    /// transfer search's call) and open the transfer prefilled; unknown
    /// accounts get the invite prompt.
    func settle(_ debt: WalletDebts) {
        guard let phoneNumber = debt.walletId, !phoneNumber.isEmpty, !isBusy else { return }
        isBusy = true
        MILoader.show()

        authRepository.isMimoUser(phoneNumber: phoneNumber) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                MILoader.hide()
                self.isBusy = false

                switch result {
                case .success(.isMimoUser(let user)):
                    self.route = .transfer(phoneNumber: phoneNumber, user: user, debt: debt.debtSum ?? 0)
                case .success(.noSuchUser):
                    self.alert = .invite(phoneNumber: phoneNumber)
                case .success(.error), .failure:
                    self.banner = ErrorMessage(title: "MOBILE__global_attention".localized(),
                                               body: "MOBILE_transfer_user_check_failed".localized(fallback: "We could not check this account. Try again."))
                }
            }
        }
    }

    func invite(phoneNumber: String) {
        authRepository.inviteUser(phoneNumber: phoneNumber) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.successBanner = SuccessMessage(title: "MOBILE_global_success_title".localized(),
                                                         body: "MOBILE_transfer_invite_sent".localized())
                case .failure(let error):
                    self?.banner = ErrorMessage(title: "MOBILE__global_attention".localized(),
                                                body: UIViewController.userFacingErrorMessage(from: error.message))
                }
            }
        }
    }

    private func finish() {
        guard !isFinished else { return }
        isFinished = true
        route = .paid
    }

    // MARK: Messaging

    override func receive(message: MessageKey) {
        guard message == .balanceUpdated else { return }
        reload()
    }

    override func unsubscribe() {
        messageService.unsubscribe(self, from: .balanceUpdated)
    }

    /// `String(format:)` when the server text carries as many `%@` as there
    /// are values; otherwise the values are appended so nothing is lost.
    private static func fill(_ template: String, _ values: [String]) -> String {
        let placeholders = template.components(separatedBy: "%@").count - 1
        if placeholders == values.count {
            return String(format: template, arguments: values)
        }
        return ([template] + values).joined(separator: " ")
    }
}

struct DebtScreenView: View {

    @ObservedObject var viewModel: DebtScreenViewModel

    var body: some View {
        VStack(spacing: 0) {
            MimoSheetHeader(title: "MOBILE_debt_pay_title".localized(fallback: "Pay your debt")) {
                viewModel.close()
            }

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.financialState == nil || viewModel.wallet == nil {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else {
                            loadFailedState
                        }
                    } else {
                        if viewModel.showsHero {
                            heroCard
                        }
                        if viewModel.payable > 0 {
                            blockedStrip
                        }
                        if !viewModel.otherDebts.isEmpty {
                            debtsSection
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }

            if viewModel.payable > 0 {
                bottomBar
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appSecondaryBackground.ignoresSafeArea())
        .alert(item: $viewModel.alert) { alert in
            switch alert {
            case .confirmCardPayment:
                return Alert(title: Text(viewModel.confirmationText),
                             primaryButton: .default(Text("MOBILE_debt_pay_action".localized(fallback: "Pay"))) {
                                 viewModel.confirmCardPayment()
                             },
                             secondaryButton: .cancel(Text("MOBILE_global_cancel".localized())))
            case .paymentFailed(let reason):
                return Alert(title: Text("MOBILE_debt_pay_failed_title".localized(fallback: "Payment failed")),
                             message: Text(reason),
                             primaryButton: .default(Text("MOBILE_debt_pay_other_methods".localized(fallback: "Other ways to pay"))) {
                                 viewModel.payWithWallet()
                             },
                             secondaryButton: .cancel(Text("MOBILE_global_cancel".localized())))
            case .invite(let phoneNumber):
                let invite = "MOBILE_transfer_invite".localized()
                return Alert(title: Text("\(invite) \(phoneNumber)"),
                             message: Text("MOBILE_transfer_invite_or_not".localized()),
                             primaryButton: .default(Text(invite)) {
                                 viewModel.invite(phoneNumber: phoneNumber)
                             },
                             secondaryButton: .cancel(Text("MOBILE_global_cancel".localized())))
            }
        }
        .sheet(item: $viewModel.attachCardURL, onDismiss: { viewModel.bankFormClosed() }) { url in
            InAppWebView(url: url.id)
        }
        .swiftMessage(message: $viewModel.banner)
        .swiftMessage(message: $viewModel.successBanner)
    }

    // MARK: Pieces

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MOBILE_you_have_a_debt".localized(fallback: "You have a debt of"))
                .font(.robotoMedium15)
                .foregroundColor(.appSecondaryLabel)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(viewModel.amountText)
                    .font(.robotoBold36)
                    .foregroundColor(.errorRed)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(viewModel.currency)
                    .font(.robotoBold20)
                    .foregroundColor(.errorRed)
                    .lineLimit(1)
            }

            Text("MOBILE_debt_amount_hint".localized(fallback: "Your wallet balance is already taken off this amount."))
                .font(.robotoRegular13)
                .foregroundColor(.appSecondaryLabel)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appBackground)
        .cornerRadius(20)
    }

    private var blockedStrip: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.errorRed)
            Text("MOBILE_pay_to_continue".localized(fallback: "Pay to continue."))
                .font(.robotoMedium14)
                .foregroundColor(.errorRed)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.redTint)
        .cornerRadius(12)
    }

    private var debtsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MOBILE_debt_list_title".localized(fallback: "Debts"))
                .font(.robotoBold17)
                .foregroundColor(.appLabel)
                .padding(.top, 8)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.otherDebts.enumerated()), id: \.offset) { index, debt in
                    Button {
                        VibrateManager.vibrate()
                        viewModel.settle(debt)
                    } label: {
                        debtRow(debt)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isBusy)

                    if index < viewModel.otherDebts.count - 1 {
                        Rectangle()
                            .fill(Color.appSeparator)
                            .frame(height: 1)
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color.appBackground)
            .cornerRadius(16)
        }
    }

    private func debtRow(_ debt: WalletDebts) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(debt.walletId ?? "")
                    .font(.robotoMedium15)
                    .foregroundColor(.appLabel)
                    .lineLimit(1)
                Text("MOBILE_transfer_send_money".localized(fallback: "Send money"))
                    .font(.robotoRegular13)
                    .foregroundColor(.appSecondaryLabel)
            }

            Spacer(minLength: 8)

            Text("-" + MimoWalletViewModel.format(amount: debt.debtSum ?? 0) + " " + viewModel.currency)
                .font(.robotoBold15)
                .foregroundColor(.errorRed)
                .lineLimit(1)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.appSecondaryLabel)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var loadFailedState: some View {
        VStack(spacing: 12) {
            Text("MOBILE_lostConnection_message".localized())
                .font(.robotoRegular15)
                .foregroundColor(.appSecondaryLabel)
                .multilineTextAlignment(.center)
            Button {
                viewModel.reload()
            } label: {
                Text("MOBILE_global_retry".localized(fallback: "Try again"))
            }
            .buttonStyle(MimoSecondaryButton())
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Rectangle().fill(Color.dividerColor).frame(height: 1)
            Button {
                VibrateManager.vibrate()
                viewModel.primaryAction()
            } label: {
                Text(viewModel.canPayWithCard ? viewModel.payWithCardTitle : "MOBILE_pay_debt".localized(fallback: "Pay debt"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .buttonStyle(MimoButton(isEnabled: !viewModel.isBusy))
            .disabled(viewModel.isBusy)
            .padding(.vertical, 12)
        }
        .background(Color.appSecondaryBackground)
    }
}

/// UIKit bridge for the debt screen v2. Presented full screen, not dismissable
/// by swipe. Presents the wallet and the transfer flow over itself and closes
/// once a fresh state says nothing is left; `onPaid` then runs (reload the
/// map's balance, resume a refused scan).
final class DebtHostingController: UIHostingController<DebtScreenView> {

    /// Refusal codes of a start held back by a debt
    /// (powerbank:docs/error-codes.md 'Rent rule violations').
    static let debtRefusalCodes: Set<String> = ["SHARING_user_has_debt", "SHARING_device_has_debt", "SHARING_card_has_debt"]

    static func isDebtRefusal(_ message: String?) -> Bool {
        guard let message else { return false }
        return debtRefusalCodes.contains(message)
    }

    /// Any state with a debt the rider can settle here.
    static func isDebtState(_ state: FinancialState?) -> Bool {
        switch state {
        case .Debt, .DebtOnDevice, .DebtOnCard: return true
        default: return false
        }
    }

    /// The states that open the screen when the map opens: DEBT_ON_CARD does not.
    static func presentsOnMapOpen(_ state: FinancialState?) -> Bool {
        state == .Debt || state == .DebtOnDevice
    }

    private let viewModel: DebtScreenViewModel
    private var onPaid: (() -> Void)?
    private var cancellables = Set<AnyCancellable>()

    init(financialState: FinancialStateModel?, wallet: WalletModel?, onPaid: (() -> Void)?) {
        let viewModel = DebtScreenViewModel(financialState: financialState, wallet: wallet)
        self.viewModel = viewModel
        self.onPaid = onPaid
        super.init(rootView: DebtScreenView(viewModel: viewModel))

        modalPresentationStyle = .fullScreen
        isModalInPresentation = true
        view.backgroundColor = .appSecondaryBackground

        viewModel.close = { [weak self] in self?.dismiss(animated: true) }

        viewModel.$route
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] route in
                self?.viewModel.route = nil
                self?.handle(route)
            }
            .store(in: &cancellables)

        // The transfer sheet only posts this as it goes away; a fresh state
        // then says whether the other account's debt is cleared.
        NotificationCenter.default.publisher(for: NSNotification.Name("TransferToFriendViewController"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.viewModel.reload() }
            .store(in: &cancellables)
    }

    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func handle(_ route: DebtScreenViewModel.Route) {
        switch route {
        case .paid:
            let onPaid = onPaid
            self.onPaid = nil
            // A wallet / transfer sheet may still be up: take everything down.
            if let presented = presentedViewController {
                presented.dismiss(animated: false)
            }
            dismiss(animated: true) { onPaid?() }
        case .wallet(let amount):
            present(WalletHostingController(productType: .charger, initialAmount: amount), animated: true)
        case .transfer(let phoneNumber, let user, let debt):
            BaseRouter.shared.showTransferToFirendViewController(self, phoneNumber: phoneNumber, transferUser: user, debt: debt)
        }
    }
}
