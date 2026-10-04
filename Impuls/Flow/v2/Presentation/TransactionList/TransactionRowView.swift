//
//  TransactionRowView.swift
//  Impuls
//
//  One wallet transaction, drawn the same way in the full list and in the
//  wallet's recent-activity preview: a tinted direction glyph, what it was
//  (income or outcome, then where the money came from or went), the time,
//  the signed amount, and a badge when the backend says it is not settled.
//

import SwiftUI

struct TransactionRowView: View {

    let item: TransactionDTO

    var body: some View {
        HStack(spacing: 12) {
            Image(item.isIncome ? "icon_transaction_income" : "icon_transaction_outcome")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundColor(item.isIncome ? .successGreen : .appSecondaryLabel)
                .frame(width: 36, height: 36)
                .background(item.isIncome ? Color.greenTint : Color.appFill)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(item.directionTitle)
                    .font(.robotoMedium15)
                    .foregroundColor(.appLabel)
                    .lineLimit(1)

                Text(item.sourceTitle + " · " + item.timeText)
                    .font(.robotoRegular12)
                    .foregroundColor(.gray5)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 4) {
                HStack(alignment: .lastTextBaseline, spacing: 3) {
                    Text(item.signedAmountText)
                        .font(.robotoBold15)
                        .foregroundColor(item.isIncome ? .successGreen : .appLabel)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)

                    Text(item.currencyTitle)
                        .font(.robotoMedium12)
                        .foregroundColor(.gray5)
                }

                if let badge = item.statusBadge {
                    MimoBadge(title: badge.title, tone: badge.tone)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(minHeight: 60)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Presentation

extension TransactionDTO {

    /// Direction comes from the type alone: a ride or purchase (MIMO_PAY), a
    /// transfer sent (MIMO_WITHDRAWAL_LOCAL) and a card-attachment hold are
    /// spending; every deposit, bonus and received transfer is income.
    var isIncome: Bool {
        switch type {
        case .mimoPay, .mimoWithdrawalLocal,
             .evocaCardAttachment, .idCardAttachment, .idCardAttachmentMir, .ameriaCardAttachment, .tinkoffCardAttachment:
            return false
        default:
            return true
        }
    }

    /// "Income" / "Outcome", the keys the transaction list already uses.
    var directionTitle: String {
        isIncome
            ? "MOBILE_charger.income".localized(fallback: "Income")
            : "MOBILE_charger.outcome".localized(fallback: "Outcome")
    }

    /// Where the money came from or went, in the rider's words: a ride, a
    /// transfer, a bank card, a provider's name.
    var sourceTitle: String {
        switch type {
        case .mimoPay:
            return "MOBILE_transactions_kind_ride".localized(fallback: "Ride")
        case .mimoWithdrawalLocal:
            return "MOBILE_transactions_kind_transfer_sent".localized(fallback: "Transfer sent")
        case .mimoDepositLocal:
            return "MOBILE_transactions_kind_transfer_received".localized(fallback: "Transfer received")
        case .mimoBonus:
            return "MOBILE_transactions_kind_bonus".localized(fallback: "Bonus")
        case .evocaCardAttachment, .idCardAttachment, .idCardAttachmentMir, .ameriaCardAttachment, .tinkoffCardAttachment:
            return "MOBILE_transactions_kind_card_attached".localized(fallback: "Card attached")
        case .evocaDepositBinding, .idDepositBinding, .idDepositBindingMir, .ameriaDepositBinding, .tinkoffDepositBinding,
             .evocaDeposit, .idDeposit, .idDepositMir, .ameriaDeposit, .tinkoffDeposit, .inecoDeposit:
            return "MOBILE_transactions_kind_card".localized(fallback: "Bank card")
        case .idramDeposit:
            return "Idram"
        case .idramDepositTerminal:
            return "Idram " + Self.terminalWord
        case .telcellDeposit:
            return "Telcell"
        case .telcellTerminalDeposit:
            return "Telcell " + Self.terminalWord
        case .easypayDeposit:
            return "EasyPay"
        case .cryptoCloudDeposit:
            return "MOBILE_transactions_kind_crypto".localized(fallback: "Crypto")
        case .fastshiftDepositTerminal:
            return "Fastshift " + Self.terminalWord
        case .other:
            // A `TransactionType` this build does not know: a generic label
            // rather than a failed page.
            return "MOBILE_transactions_kind_other".localized(fallback: "Payment")
        }
    }

    private static var terminalWord: String {
        "MOBILE_transactions_kind_terminal".localized(fallback: "terminal")
    }

    var dateValue: Date {
        Date(timeIntervalSince1970: TimeInterval(date) / 1000)
    }

    var timeText: String {
        DateFormatter.transactionTimeFormatter.string(from: dateValue)
    }

    /// "+1 500" / "−300": grouped, at most two decimals.
    var signedAmountText: String {
        (isIncome ? "+" : "−") + MimoWalletViewModel.format(amount: abs(amount))
    }

    /// A badge whenever the backend says the transaction is not a settled
    /// charge. ipay's `TransactionStatus` is WAITING, CHARGE, REJECT, DEBT,
    /// REFUND (docs/mobile-api.md, GET /api/transactions); older spellings are
    /// kept for safety, CHARGE and anything unknown show nothing.
    var statusBadge: (title: String, tone: MimoBadge.Tone)? {
        let value = status.uppercased()

        if ["PENDING", "IN_PROGRESS", "PROCESSING", "CREATED", "WAITING"].contains(value) {
            return ("MOBILE_transactions_status_pending".localized(fallback: "Pending"), .amber)
        }
        if ["FAILED", "FAIL", "REJECT", "REJECTED", "DECLINED", "CANCELED", "CANCELLED", "ERROR"].contains(value) {
            return ("MOBILE_transactions_status_failed".localized(fallback: "Failed"), .red)
        }
        if value == "DEBT" {
            return ("MOBILE_wallet_debt_badge".localized(fallback: "Debt"), .red)
        }
        if value == "REFUND" {
            return ("MOBILE_transactions_status_refund".localized(fallback: "Refund"), .gray)
        }

        return nil
    }
}

extension DateFormatter {

    /// Time of day for a transaction row, in the rider's locale.
    static var transactionTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "HH:mm"

        return formatter
    }
}
