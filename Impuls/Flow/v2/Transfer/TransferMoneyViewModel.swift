//
//  TransferMoneyViewModel.swift
//  Impuls
//
//  State for the v2 "Transfer money to a friend" flow. Two steps: find the
//  recipient (phone number, address book, or a recent recipient), then pick
//  an amount and send. Reuses the legacy `TransferViewModel` (lookup, invite,
//  recent recipients) and `TransferToFriendsViewModel` (the transfer call) so
//  the backend contract is unchanged.
//

import Foundation
import Combine
import PhoneNumberKit

/// A user money can be sent to: the phone number the backend keys wallets
/// by, plus whatever profile data the lookup returned.
struct TransferRecipient: Equatable {
    let phoneNumber: String
    let contact: ContactsListModel?

    var displayName: String {
        let name = ((contact?.receiverName ?? "") + " " + (contact?.receiverSurname ?? ""))
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return name.isEmpty ? phoneNumber : name
    }

    /// Phone number, unless the name already is the phone number.
    var displayPhone: String? {
        displayName == phoneNumber ? nil : phoneNumber
    }

    var avatarURL: URL? {
        contact?.receiverAvatar?.getURL()
    }

    static func == (lhs: TransferRecipient, rhs: TransferRecipient) -> Bool {
        lhs.phoneNumber == rhs.phoneNumber
    }
}

/// One of the numbers of a picked address-book contact. `Identifiable` so the
/// confirmation dialog can list them.
struct TransferPhoneChoice: Identifiable {
    let id = UUID()
    let number: String
}

final class TransferMoneyViewModel: ObservableObject {

    enum Step {
        case findRecipient
        case amount
    }

    // MARK: - Step 1: find

    @Published var step: Step
    @Published var selectedCountry: CountryCodeResponse? {
        didSet {
            guard selectedCountry?.code != oldValue?.code else { return }

            updateNumberMask()
            phoneNumber = ""
        }
    }
    @Published var phoneNumber: String = "" {
        didSet {
            guard let mask = numberMask, !mask.isEmpty else { return }

            let formatted = phoneNumber.format(with: mask)
            if phoneNumber != formatted {
                phoneNumber = formatted
            }

            let limit = mask.trimmingCharacters(in: .whitespaces).count
            if phoneNumber.count > limit {
                phoneNumber = String(phoneNumber.prefix(limit))
            }
        }
    }
    @Published private(set) var exampleNumber: String?
    @Published private(set) var recentRecipients: [TransferRecipient] = []
    /// True once GET api/transactions/withdrawals answered, so the empty state
    /// is shown only for a confirmed empty list, never while loading.
    @Published private(set) var recentRecipientsLoaded = false

    /// Set when the looked-up number is not a Mimo user; the view asks
    /// whether to send an invitation.
    @Published var invitePhoneNumber: String?
    /// A contact with several numbers: the view asks which one to use.
    @Published var contactPhoneChoices: [TransferPhoneChoice] = []

    // MARK: - Step 2: amount

    @Published private(set) var recipient: TransferRecipient?
    @Published var amount: String = "" {
        didSet {
            let digits = amount.filter { $0.isNumber }
            let trimmed = String(digits.prefix(7))
            if amount != trimmed {
                amount = trimmed
            }
        }
    }

    // MARK: - Feedback

    /// One-shot banners. The view's `swiftMessage` binding writes nil back
    /// once a banner is dismissed, and a new value replaces whatever is still
    /// on screen, so an error never survives the problem it reported. Set
    /// only through `present(_:)`, which holds a banner back while the screen
    /// is not visible and drops it once the screen closed.
    @Published var successMessage: SuccessMessage?
    @Published var errorMessage: ErrorMessage?
    /// Flipped once a transfer went through; the view closes the screen.
    @Published var didTransfer = false

    /// Between the view's onAppear and onDisappear. onDisappear fires when the
    /// sheet is dismissed (not when the app goes to the background), so a
    /// result that lands after the rider closed the screen is never shown over
    /// whatever replaced it.
    private var isScreenVisible = false
    /// A result that arrived while the screen was not visible, shown on the
    /// next appearance instead of being lost.
    private var pendingError: ErrorMessage?
    private var pendingSuccess: SuccessMessage?
    /// True while PATCH api/wallet/transfer is in flight: the send button is
    /// disabled and a second tap is ignored until the answer arrives.
    @Published private(set) var isTransferring = false

    let balance: Double
    let currency: String
    /// The flow opened straight on the amount step (debt payment), so the
    /// header closes the screen instead of returning to the search step.
    let startedOnAmount: Bool

    private let finder = TransferViewModel()
    private let transfer = TransferToFriendsViewModel()
    private let transferGuard = SubmissionGuard()
    private let phoneNumberKit = PhoneNumberKit()
    private var numberMask: String?

    /// Allowed amount range from ipay GET api/wallet/transfer/ranges (docs/mobile-api.md).
    /// nil until a statusCode-200 answer arrives; the app never ships its own limits -
    /// while unknown any positive amount is sent and the backend refusal
    /// (IPAY_deposit_local_wrong_amount) is shown.
    @Published private(set) var ranges: (min: Double, max: Double)?
    private let rangesNetwork = SessionNetwork()
    static let quickAmounts: [Double] = [500, 1_000, 2_000, 5_000]

    init(wallet: WalletModel?, recipient: TransferRecipient? = nil, debt: Double? = nil) {
        let wallet = wallet ?? UserManager.share.walletModel
        self.balance = wallet?.balance ?? 0
        self.currency = wallet?.currency.currencyNameOrCode ?? UserManager.walletCurrencyTitle
        self.recipient = recipient
        self.startedOnAmount = recipient != nil
        self.step = recipient == nil ? .findRecipient : .amount

        if let debt = debt, debt > 0 {
            self.amount = String(Int(debt.rounded(.up)))
        }

        let countries = ApplicationSettings.shared.countryCodes
        // `ApplicationSettings.isoCountryCode` is the alpha-3 code; the country
        // list is keyed by alpha-2, so the device region is the match here.
        let deviceCode = Locale.current.regionCode
        self.selectedCountry = countries.first(where: { $0.code == deviceCode })
            ?? countries.first(where: { $0.code == "AM" })
            ?? countries.first
        updateNumberMask()
        loadRanges()

        transferGuard.publisher.assign(to: &$isTransferring)
    }

    // MARK: - Derived

    var canFind: Bool {
        !phoneNumber.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var amountValue: Double? {
        Double(amount)
    }

    var canTransfer: Bool {
        (amountValue ?? 0) > 0
    }

    /// The send button: a valid amount and nothing already on its way.
    var canSend: Bool {
        canTransfer && !isTransferring
    }

    var formattedBalance: String {
        TransferMoneyViewModel.format(amount: balance)
    }

    /// Dial code + digits, the way the legacy phone picker built it.
    var fullPhoneNumber: String {
        ((selectedCountry?.dial_code ?? "") + phoneNumber)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
    }

    var isPhoneNumberValid: Bool {
        phoneNumberKit.isValidPhoneNumber(fullPhoneNumber)
    }

    static func format(amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = amount.rounded() == amount ? 0 : 2
        formatter.groupingSeparator = " "
        formatter.usesGroupingSeparator = true

        return formatter.string(from: NSNumber(value: amount)) ?? String(amount)
    }

    // MARK: - Lifecycle

    /// Called from the view's onAppear: banners held back while the screen
    /// was away are shown now.
    func screenAppeared() {
        isScreenVisible = true

        if let pendingError {
            self.pendingError = nil
            errorMessage = pendingError
        }
        if let pendingSuccess {
            self.pendingSuccess = nil
            successMessage = pendingSuccess
        }
    }

    /// Called from the view's onDisappear: an error still on screen is taken
    /// down with the sheet; a success toast is left to finish on its own.
    func screenDisappeared() {
        isScreenVisible = false
        errorMessage = nil
    }

    private func present(_ error: ErrorMessage) {
        guard isScreenVisible else {
            pendingError = error
            return
        }

        errorMessage = error
    }

    private func present(_ success: SuccessMessage) {
        guard isScreenVisible else {
            pendingSuccess = success
            return
        }

        successMessage = success
    }

    /// Hands a network answer to the main queue. The loader is taken down
    /// whatever happened to the screen; the body runs only while the view
    /// model (and so the screen) is still alive, and shows its banners
    /// through `present(_:)`, so a late answer never surfaces over another
    /// screen.
    private static func deliver(to viewModel: TransferMoneyViewModel?,
                                _ body: @escaping (TransferMoneyViewModel) -> Void) {
        DispatchQueue.main.async {
            MILoader.hide()
            guard let viewModel else { return }

            body(viewModel)
        }
    }

    // MARK: - Step 1 actions

    func loadRecentRecipients() {
        finder.fetchContacts { [weak self] result in
            DispatchQueue.main.async {
                guard let self, case .success(let contacts) = result else { return }

                self.recentRecipientsLoaded = true

                // One row per receiver: the withdrawals list has an entry per
                // transfer, so a friend paid twice would show up twice.
                var seen = Set<String>()
                self.recentRecipients = contacts.compactMap { contact -> TransferRecipient? in
                    guard let phone = contact.receiverId, !phone.isEmpty,
                          seen.insert(phone).inserted else { return nil }

                    return TransferRecipient(phoneNumber: phone, contact: contact)
                }
            }
        }
    }

    func findTapped() {
        guard canFind else { return }
        guard isPhoneNumberValid else {
            present(ErrorMessage(
                title: "MOBILE__global_attention".localized(),
                body: "MOBILE_transfer_invalid_phone".localized(fallback: "Please enter a valid phone number")
            ))

            return
        }

        lookUp(phoneNumber: fullPhoneNumber)
    }

    /// Numbers coming from the address book: a contact with one number is
    /// looked up straight away, otherwise the view asks which one to use.
    func contactPicked(phoneNumbers: [String]) {
        let numbers = phoneNumbers.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard !numbers.isEmpty else {
            present(ErrorMessage(
                title: "MOBILE__global_attention".localized(),
                body: "MOBILE_transfer_contact_no_phone".localized(fallback: "This contact has no phone number")
            ))

            return
        }

        if numbers.count == 1 {
            contactNumberChosen(numbers[0])
        } else {
            contactPhoneChoices = numbers.map { TransferPhoneChoice(number: $0) }
        }
    }

    func contactNumberChosen(_ raw: String) {
        contactPhoneChoices = []
        lookUp(phoneNumber: normalize(contactNumber: raw))
    }

    func recentRecipientTapped(_ recipient: TransferRecipient) {
        select(recipient)
    }

    func inviteConfirmed() {
        guard let phoneNumber = invitePhoneNumber else { return }

        invitePhoneNumber = nil
        MILoader.show()
        finder.inviteUser(phoneNumber: phoneNumber) { [weak self] result in
            TransferMoneyViewModel.deliver(to: self) { viewModel in
                switch result {
                case .success:
                    viewModel.present(SuccessMessage(
                        title: "MOBILE_verify_successful_alert".localized(),
                        body: "MOBILE_transfer_invite_sent".localized(fallback: "Invitation sent")
                    ))
                case .failure(let error):
                    viewModel.present(ErrorMessage(
                        title: "MOBILE__global_attention".localized(),
                        body: MimoError(error: error).message
                    ))
                }
            }
        }
    }

    // MARK: - Step 2 actions

    func backToSearch() {
        amount = ""
        recipient = nil
        step = .findRecipient
    }

    func quickAmountTapped(_ value: Double) {
        VibrateManager.vibrate()
        amount = String(Int(value))
    }

    func isQuickAmountSelected(_ value: Double) -> Bool {
        amountValue == value
    }

    func formattedQuickAmount(_ value: Double) -> String {
        TransferMoneyViewModel.format(amount: value)
    }

    func transferTapped() {
        guard let recipient = recipient else { return }

        // The same checks ipay runs, in its order (docs/mobile-api.md,
        // "PATCH /api/wallet/transfer"), each with the copy its refusal would
        // carry, so nothing is sent that is known to come back refused.
        guard let amount = amountValue, amount > 0 else {
            refuseTransfer("MOBILE_transfer_fill_amount".localized(fallback: "Please fill a valid amount"))
            return
        }

        // Only a known range is enforced here; otherwise the backend decides.
        if let ranges, amount < ranges.min || amount > ranges.max {
            refuseTransfer(TransferMoneyErrors.wrongAmount.userMessage)
            return
        }

        // receiverId must match ^\+[0-9]{9,14}$; a recent or prefilled
        // recipient is normalised the same way as a typed number.
        guard let receiverId = normalizedReceiverId(recipient.phoneNumber) else {
            refuseTransfer(TransferMoneyErrors.noSuchUser.userMessage)
            return
        }

        // 418 IPAY_duplicate_receiver, refused before the request.
        guard !TransferMoneyErrors.isOwnNumber(receiverId) else {
            refuseTransfer(TransferMoneyErrors.sameReceiver.userMessage)
            return
        }

        if amount > balance {
            refuseTransfer(TransferMoneyErrors.notEnoughBalance.userMessage)
            return
        }

        // One transfer at a time: a tap while the previous one is still
        // answering does nothing. Released below on every outcome, so the
        // requirements sheet's retry (and a plain retry after an error) can
        // send again.
        guard transferGuard.begin() else { return }

        MILoader.show()
        transfer.transferMoney(amount: amount, phoneNumber: receiverId) { [weak self] result in
            // The guard dies with the view model, so a screen closed mid-flight
            // needs no release; a live one is released before anything is shown.
            TransferMoneyViewModel.deliver(to: self) { viewModel in
                viewModel.transferGuard.end()

                switch result {
                case .success:
                    UserManager.share.isOpenDebtScreen = false
                    NotificationCenter.default.post(name: Constant.Notifications.updateUserUI, object: nil)
                    viewModel.present(SuccessMessage(
                        title: "MOBILE_global_success_title".localized(),
                        body: "MOBILE_transfer_success_body".localized(fallback: "Money sent to") + " " + recipient.displayName
                    ))
                    viewModel.didTransfer = true
                case .failure(.rulesNotMet(let rejection)):
                    // The sender does not meet the TRANSFER rules (a rule
                    // switched on after this screen was opened): walk through
                    // them, then send again with the same recipient and amount.
                    UserManager.share.isOpenDebtScreen = true
                    guard viewModel.isScreenVisible else { return }

                    ActionEligibilityFlow.handle(rejection, check: .transfer, retry: { [weak viewModel] in
                        viewModel?.transferTapped()
                    })
                case .failure(let error):
                    viewModel.refuseTransfer(error.userMessage)
                }
            }
        }
    }

    /// A transfer that did not go through, for whichever reason: the debt
    /// flow is told to come back, and the reason replaces any earlier banner.
    private func refuseTransfer(_ reason: String) {
        UserManager.share.isOpenDebtScreen = true
        present(ErrorMessage(
            title: "MOBILE_transfer_transfer_failed".localized(),
            body: reason
        ))
    }

    // MARK: - Private

    /// A refused or failed answer keeps the last known range (or none).
    private func loadRanges() {
        rangesNetwork.request(with: URLBuilder(from: AuthAPI.transferRanges)) { [weak self] result in
            guard case .success(let data) = result,
                  let envelope = try? JSONDecoder().decode(BaseResponseModel<[String: Double]>.self, from: data),
                  envelope.statusCode == 200,
                  let content = envelope.content,
                  let min = content["min"], let max = content["max"], min <= max else { return }

            DispatchQueue.main.async { self?.ranges = (min, max) }
        }
    }

    private func lookUp(phoneNumber raw: String) {
        // The number looked up is the one PATCH api/wallet/transfer will get as
        // receiverId, so it is brought to the backend's shape first and refused
        // here with the copy ipay would answer with (IPAY_no_such_user for a
        // malformed id, IPAY_duplicate_receiver for the rider's own number).
        guard let phoneNumber = normalizedReceiverId(raw) else {
            present(ErrorMessage(
                title: "MOBILE__global_attention".localized(),
                body: TransferMoneyErrors.noSuchUser.userMessage
            ))

            return
        }

        guard !TransferMoneyErrors.isOwnNumber(phoneNumber) else {
            present(ErrorMessage(
                title: "MOBILE__global_attention".localized(),
                body: TransferMoneyErrors.sameReceiver.userMessage
            ))

            return
        }

        MILoader.show()
        finder.isMimoUser(phoneNumber: phoneNumber) { [weak self] status in
            TransferMoneyViewModel.deliver(to: self) { viewModel in
                switch status {
                case .isMimoUser(let contact):
                    viewModel.select(TransferRecipient(phoneNumber: phoneNumber, contact: contact))
                case .noSuchUser:
                    // The invite alert is a view-driven binding; held back the
                    // same way as a banner while the screen is away.
                    guard viewModel.isScreenVisible else { return }

                    viewModel.invitePhoneNumber = phoneNumber
                case .error:
                    viewModel.present(ErrorMessage(
                        title: "MOBILE__global_attention".localized(),
                        body: "MOBILE_transfer_check_failed".localized(fallback: "Failed to check contact user")
                    ))
                }
            }
        }
    }

    /// Brings a number to the shape ipay keys wallets by: E.164 (`+` and
    /// 9-14 digits, docs/mobile-api.md "PATCH /api/wallet/transfer"). Parsed
    /// with PhoneNumberKit for the selected country first; otherwise only
    /// formatting is stripped and a `00` trunk prefix becomes `+`. No country
    /// code is ever added that the rider did not enter. nil when the result
    /// still does not match the pattern.
    private func normalizedReceiverId(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let region = selectedCountry?.code ?? PhoneNumberKit.defaultRegionCode()
        if let parsed = try? phoneNumberKit.parse(trimmed, withRegion: region, ignoreType: true) {
            let e164 = phoneNumberKit.format(parsed, toType: .e164)
            if TransferMoneyErrors.isValidReceiverId(e164) {
                return e164
            }
        }

        var number = trimmed.filter { $0.isNumber || $0 == "+" }
        if number.hasPrefix("00") {
            number = "+" + number.dropFirst(2)
        }

        return TransferMoneyErrors.isValidReceiverId(number) ? number : nil
    }

    private func select(_ recipient: TransferRecipient) {
        self.recipient = recipient
        step = .amount
    }

    /// Address-book numbers arrive in any local format. Parse them with the
    /// selected country as the default region; a number that cannot be
    /// parsed is passed on as typed and refused by the receiver-id check in
    /// `lookUp` (no `+374` is invented for it any more).
    private func normalize(contactNumber raw: String) -> String {
        let region = selectedCountry?.code ?? PhoneNumberKit.defaultRegionCode()
        if let parsed = try? phoneNumberKit.parse(raw, withRegion: region, ignoreType: true) {
            return phoneNumberKit.format(parsed, toType: .e164)
        }

        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func updateNumberMask() {
        let countryCode = selectedCountry?.code ?? ""
        let dialCode = selectedCountry?.dial_code ?? ""
        let example = phoneNumberKit.getFormattedExampleNumber(forCountry: countryCode,
                                                              ofType: .mobile,
                                                              withFormat: .international)
        exampleNumber = example?.replacingOccurrences(of: dialCode, with: "").trimmingCharacters(in: .whitespaces)
        numberMask = exampleNumber?.replacingOccurrences(of: "[0-9]", with: "#", options: .regularExpression)
    }
}

// MARK: - Single-flight guard

/// Admits one in-flight submission per user action - send money, top up,
/// scan-to-rent, activate a package. `begin()` returns true for exactly one
/// caller until `end()` releases it, whatever thread the taps come from, so a
/// request that is already on its way is never sent a second time; a refused
/// call does nothing (no queueing). The owner mirrors `publisher` into a
/// published flag its screen uses to disable the button, and calls `end()` on
/// success, error and cancellation alike. Shared by the wallet, the charger
/// map and the rates screen.
final class SubmissionGuard {

    private let lock = NSLock()
    private var inFlight = false
    private let subject = CurrentValueSubject<Bool, Never>(false)

    /// True from an accepted `begin()` until the matching `end()`.
    var isSubmitting: Bool {
        lock.lock()
        defer { lock.unlock() }
        return inFlight
    }

    /// The in-flight state, delivered on the main thread (synchronously when
    /// `begin()`/`end()` are called there) so a SwiftUI button follows it in
    /// the same turn of the run loop.
    var publisher: AnyPublisher<Bool, Never> {
        subject.removeDuplicates().eraseToAnyPublisher()
    }

    /// Claims the slot. False when a submission is already in flight: the
    /// caller must return without sending anything.
    @discardableResult
    func begin() -> Bool {
        lock.lock()
        guard !inFlight else {
            lock.unlock()
            return false
        }
        inFlight = true
        lock.unlock()
        publish()

        return true
    }

    /// Releases the slot. Safe to call more than once.
    func end() {
        lock.lock()
        let wasInFlight = inFlight
        inFlight = false
        lock.unlock()
        if wasInFlight {
            publish()
        }
    }

    private func publish() {
        if Thread.isMainThread {
            subject.send(isSubmitting)
        } else {
            // Report the state as it is when the hop lands, so a begin/end
            // pair from a background thread never arrives out of order.
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.subject.send(self.isSubmitting)
            }
        }
    }
}

extension TransferMoneyErrors {

    /// Human-readable reason. The backend's message is itself a translation
    /// key (`IPAY_*`), so prefer its translation and fall back to English
    /// when the dictionary has no entry.
    var userMessage: String {
        switch self {
        case .notEnoughBalance:
            return "MOBILE_transfer_not_enough_money".localized()
        case .wrongAmount:
            return "MOBILE_min_value_to_transfer".localized()
        case .sameReceiver:
            return (code ?? "").localized(fallback: "You cannot transfer money to yourself")
        case .transferNotAllowed:
            return (code ?? "").localized(fallback: "Transfers are not allowed for this wallet")
        case .noSuchUser, .noSuchWallet:
            return (code ?? "").localized(fallback: "The recipient does not have an Impulse wallet")
        case .serviceUnavailable:
            // Same wording as a card attach while accounts is down.
            return (code ?? "").localized(fallback: "The service is temporarily unavailable. Please try again later.")
        case .rulesNotMet(let rejection):
            // Shown only when the requirements sheet could not take over:
            // the first failing rule's code is a shared locale key.
            return rejection.message.localized(fallback: "MOBILE_requirements_checklist_subtitle".localized(fallback: "A few things need your attention first."))
        case .other:
            return "MOBILE_transfer_failed_generic".localized(fallback: "The transfer could not be completed. Please try again.")
        }
    }
}
