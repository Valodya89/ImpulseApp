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

    @Published var successMessage: SuccessMessage?
    @Published var errorMessage: ErrorMessage?
    /// Flipped once a transfer went through; the view closes the screen.
    @Published var didTransfer = false

    let balance: Double
    let currency: String
    /// The flow opened straight on the amount step (debt payment), so the
    /// header closes the screen instead of returning to the search step.
    let startedOnAmount: Bool

    private let finder = TransferViewModel()
    private let transfer = TransferToFriendsViewModel()
    private let phoneNumberKit = PhoneNumberKit()
    private var numberMask: String?

    /// Below this the backend rejects the transfer (`IPAY_deposit_local_wrong_amount`).
    static let minimumAmount: Double = 100
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

    // MARK: - Step 1 actions

    func loadRecentRecipients() {
        finder.fetchContacts { [weak self] result in
            DispatchQueue.main.async {
                guard case .success(let contacts) = result else { return }

                self?.recentRecipients = contacts.compactMap { contact -> TransferRecipient? in
                    guard let phone = contact.receiverId, !phone.isEmpty else { return nil }

                    return TransferRecipient(phoneNumber: phone, contact: contact)
                }
            }
        }
    }

    func findTapped() {
        guard canFind else { return }
        guard isPhoneNumberValid else {
            errorMessage = ErrorMessage(
                title: "MOBILE__global_attention".localized(),
                body: "MOBILE_transfer_invalid_phone".localized(fallback: "Please enter a valid phone number")
            )

            return
        }

        lookUp(phoneNumber: fullPhoneNumber)
    }

    /// Numbers coming from the address book: a contact with one number is
    /// looked up straight away, otherwise the view asks which one to use.
    func contactPicked(phoneNumbers: [String]) {
        let numbers = phoneNumbers.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        guard !numbers.isEmpty else {
            errorMessage = ErrorMessage(
                title: "MOBILE__global_attention".localized(),
                body: "MOBILE_transfer_contact_no_phone".localized(fallback: "This contact has no phone number")
            )

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
            DispatchQueue.main.async {
                MILoader.hide()

                switch result {
                case .success:
                    self?.successMessage = SuccessMessage(
                        title: "MOBILE_verify_successful_alert".localized(),
                        body: "MOBILE_transfer_invite_sent".localized(fallback: "Invitation sent")
                    )
                case .failure(let error):
                    self?.errorMessage = ErrorMessage(
                        title: "MOBILE__global_attention".localized(),
                        body: MimoError(error: error).message
                    )
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
        guard let amount = amountValue, amount > 0 else {
            UserManager.share.isOpenDebtScreen = true
            errorMessage = ErrorMessage(
                title: "MOBILE_transfer_transfer_failed".localized(),
                body: "MOBILE_transfer_fill_amount".localized(fallback: "Please fill a valid amount")
            )

            return
        }

        if amount < TransferMoneyViewModel.minimumAmount {
            UserManager.share.isOpenDebtScreen = true
            errorMessage = ErrorMessage(
                title: "MOBILE_transfer_transfer_failed".localized(),
                body: "MOBILE_min_value_to_transfer".localized()
            )

            return
        }

        if amount > balance {
            UserManager.share.isOpenDebtScreen = true
            errorMessage = ErrorMessage(
                title: "MOBILE_transfer_transfer_failed".localized(),
                body: "MOBILE_transfer_not_enough_money".localized()
            )

            return
        }

        MILoader.show()
        transfer.transferMoney(amount: amount, phoneNumber: recipient.phoneNumber) { [weak self] result in
            DispatchQueue.main.async {
                MILoader.hide()
                guard let self = self else { return }

                switch result {
                case .success:
                    UserManager.share.isOpenDebtScreen = false
                    NotificationCenter.default.post(name: Constant.Notifications.updateUserUI, object: nil)
                    self.successMessage = SuccessMessage(
                        title: "MOBILE_global_success_title".localized(),
                        body: "MOBILE_transfer_success_body".localized(fallback: "Money sent to") + " " + recipient.displayName
                    )
                    self.didTransfer = true
                case .failure(let error):
                    UserManager.share.isOpenDebtScreen = true
                    self.errorMessage = ErrorMessage(
                        title: "MOBILE_transfer_transfer_failed".localized(),
                        body: error.userMessage
                    )
                }
            }
        }
    }

    // MARK: - Private

    private func lookUp(phoneNumber: String) {
        MILoader.show()
        finder.isMimoUser(phoneNumber: phoneNumber) { [weak self] status in
            DispatchQueue.main.async {
                MILoader.hide()
                guard let self = self else { return }

                switch status {
                case .isMimoUser(let contact):
                    self.select(TransferRecipient(phoneNumber: phoneNumber, contact: contact))
                case .noSuchUser:
                    self.invitePhoneNumber = phoneNumber
                case .error:
                    self.errorMessage = ErrorMessage(
                        title: "MOBILE__global_attention".localized(),
                        body: "MOBILE_transfer_check_failed".localized(fallback: "Failed to check contact user")
                    )
                }
            }
        }
    }

    private func select(_ recipient: TransferRecipient) {
        self.recipient = recipient
        step = .amount
    }

    /// Address-book numbers arrive in any local format. Parse them with the
    /// selected country as the default region, and fall back to the legacy
    /// Armenian normalisation when parsing fails.
    private func normalize(contactNumber raw: String) -> String {
        let region = selectedCountry?.code ?? PhoneNumberKit.defaultRegionCode()
        if let parsed = try? phoneNumberKit.parse(raw, withRegion: region, ignoreType: true) {
            return phoneNumberKit.format(parsed, toType: .e164)
        }

        var number = raw
        number.removeAll(where: { $0.isWhitespace })
        number = number.replacingOccurrences(of: "-", with: "")

        if number.hasPrefix("0") {
            number.removeFirst()
            number = "+374" + number
        }

        if number.hasPrefix("374") {
            number = "+" + number
        }

        return number
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
            return rawValue.localized(fallback: "You cannot transfer money to yourself")
        case .transferNotAllowed:
            return rawValue.localized(fallback: "Transfers are not allowed for this wallet")
        case .noSuchUser, .noSuchWallet:
            return rawValue.localized(fallback: "The recipient does not have an Impulse wallet")
        case .other:
            return "MOBILE_transfer_failed_generic".localized(fallback: "The transfer could not be completed. Please try again.")
        }
    }
}
