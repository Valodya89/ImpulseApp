//
//  TransferMoneyCheckModel.swift
//  MimoBike
//
//  Created by Sedrak Igityan on 03.06.21.
//

import Foundation

enum TransferMoneyCheckModel {
    
    case success
    case failure(TransferMoneyErrors?)
    
    init(data: Data) {
        // Refused for unmet TRANSFER payment rules: the envelope carries every
        // failing rule in `content.violations` (ipay docs/mobile-api.md,
        // "PATCH /api/wallet/transfer"). Read it before the code mapping below
        // so a new rule type never ends up as the generic failure.
        if let rejection = ActionRejection.parse(data: data, request: nil) {
            self = .failure(.rulesNotMet(rejection))
            return
        }

        do {
            let checkModel = try JSONDecoder().decode(BaseResponseModel<EmptyResponseModel>.self, from: data)

            // The backend reports business failures as HTTP 200 with the real status in
            // the envelope, so the status code is what decides the outcome. Keying off a
            // recognised error message instead treated every unrecognised failure —
            // a wallet lock, an unknown receiver — as a completed transfer.
            // Known refusals (ipay docs/mobile-api.md, "PATCH /api/wallet/transfer"):
            // 400 IPAY_deposit_local_wrong_amount, 418 IPAY_duplicate_receiver,
            // 404 IPAY_no_such_wallet / IPAY_no_such_user, 402 IPAY_no_such_balance,
            // 412 IPAY_transfer_not_allowed, 503 IPAY_accounts_service_unavailable.
            guard checkModel.statusCode == 200 else {
                self = .failure(TransferMoneyErrors(code: checkModel.message))
                return
            }

            self = .success
        } catch {
            self = .failure(nil)
        }
        
    }
}

enum TransferMoneyErrors: Error {
    case sameReceiver
    case notEnoughBalance
    case wrongAmount
    case transferNotAllowed
    case noSuchUser
    case noSuchWallet
    /// ipay could not reach the accounts service while checking the sender.
    case serviceUnavailable
    /// The sender does not meet the TRANSFER payment rules; the rejection
    /// lists them all so the requirements sheet can walk the rider through.
    case rulesNotMet(ActionRejection)
    case other

    /// The envelope `message` of each known refusal; also its locale key.
    var code: String? {
        switch self {
        case .sameReceiver: return "IPAY_duplicate_receiver"
        case .notEnoughBalance: return "IPAY_no_such_balance"
        case .wrongAmount: return "IPAY_deposit_local_wrong_amount"
        case .transferNotAllowed: return "IPAY_transfer_not_allowed"
        case .noSuchUser: return "IPAY_no_such_user"
        case .noSuchWallet: return "IPAY_no_such_wallet"
        case .serviceUnavailable: return "IPAY_accounts_service_unavailable"
        case .rulesNotMet(let rejection): return rejection.message
        case .other: return nil
        }
    }

    /// What ipay accepts as `receiverId` on PATCH /api/wallet/transfer: a
    /// `+`-prefixed phone number of 9-14 digits (`@Pattern("^\\+[0-9]{9,14}$")`,
    /// docs/mobile-api.md). Anything else is refused by bean validation before
    /// the wallet lookup, so the app checks it first and shows the copy the
    /// receiver lookup would give (IPAY_no_such_user).
    static let receiverIdPattern = "^\\+[0-9]{9,14}$"

    static func isValidReceiverId(_ receiverId: String) -> Bool {
        receiverId.range(of: receiverIdPattern, options: .regularExpression) != nil
    }

    /// True when `receiverId` is the rider's own number (the phone the session
    /// was opened with), compared digit by digit so a missing `+` or stray
    /// formatting never hides a self-transfer. ipay answers it with
    /// 418 IPAY_duplicate_receiver; the app refuses before the request.
    static func isOwnNumber(_ receiverId: String) -> Bool {
        guard let own = StorageManager().fetch(key: .phoneNumber, type: String.self) else { return false }

        let ownDigits = own.filter { $0.isNumber }
        let receiverDigits = receiverId.filter { $0.isNumber }

        return !ownDigits.isEmpty && ownDigits == receiverDigits
    }

    init(code: String?) {
        switch code {
        case "IPAY_duplicate_receiver": self = .sameReceiver
        case "IPAY_no_such_balance": self = .notEnoughBalance
        case "IPAY_deposit_local_wrong_amount": self = .wrongAmount
        case "IPAY_transfer_not_allowed": self = .transferNotAllowed
        case "IPAY_no_such_user": self = .noSuchUser
        case "IPAY_no_such_wallet": self = .noSuchWallet
        case "IPAY_accounts_service_unavailable": self = .serviceUnavailable
        default: self = .other
        }
    }
}
