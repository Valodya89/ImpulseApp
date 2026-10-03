//
//  ViolationPresentation.swift
//  Impuls
//
//  How a violation reads on screen: its localized message, the numbers that
//  come with it, and the inputs it asks for.
//
//  Every text comes from the locale service; the English here is only the
//  bundled fallback for a key the server has not delivered yet. The keys are
//  shared with Android and the other apps - keep the names and wording in step.
//

import Foundation

/// An input a rule can ask for. Field names and rules are matched without
/// regard to case or separators ("postalCode", "address.postal_code" and
/// "ADDRESS_POSTAL_CODE" are the same input).
enum RequirementField: String, CaseIterable {
    case name
    case surname
    case gender
    case birthday
    case email
    case country
    case addressCountry
    case city
    case street
    case postalCode
    case document
    case documentNumber

    static let addressFields: [RequirementField] = [.addressCountry, .city, .street, .postalCode]

    init?(_ value: String) {
        let key = value.lowercased().filter { $0.isLetter }

        switch key {
        case "name", "firstname": self = .name
        case "surname", "lastname": self = .surname
        case "gender": self = .gender
        case "birthday", "birthdate": self = .birthday
        case "email": self = .email
        case "country": self = .country
        case "addresscountry": self = .addressCountry
        case "city", "addresscity": self = .city
        case "street", "addressstreet": self = .street
        case "postalcode", "addresspostalcode": self = .postalCode
        case "document": self = .document
        case "documentnumber": self = .documentNumber
        default: return nil
        }
    }

    /// One title per rule: `MOBILE_requirement_<RULE>`.
    var title: String {
        switch self {
        case .name:
            return "MOBILE_requirement_NAME".localized(fallback: "First name")
        case .surname:
            return "MOBILE_requirement_SURNAME".localized(fallback: "Last name")
        case .gender:
            return "MOBILE_requirement_GENDER".localized(fallback: "Gender")
        case .birthday:
            return "MOBILE_requirement_BIRTHDAY".localized(fallback: "Date of birth")
        case .email:
            return "MOBILE_requirement_EMAIL".localized(fallback: "Email")
        case .country, .addressCountry:
            return "MOBILE_requirement_ADDRESS_COUNTRY".localized(fallback: "Country")
        case .city:
            return "MOBILE_requirement_ADDRESS_CITY".localized(fallback: "City")
        case .street:
            return "MOBILE_requirement_ADDRESS_STREET".localized(fallback: "Street and house number")
        case .postalCode:
            return "MOBILE_requirement_ADDRESS_POSTAL_CODE".localized(fallback: "Postal code")
        case .document:
            return "MOBILE_requirement_DOCUMENT".localized(fallback: "Identity document")
        case .documentNumber:
            return "MOBILE_requirement_DOCUMENT_NUMBER".localized(fallback: "Document number")
        }
    }
}

extension EligibilityViolation.Target {

    /// What to do when the violation's own code has no translation: one
    /// sentence per redirect target.
    var genericMessage: String {
        switch self {
        case .profile:
            return "MOBILE_requirements_generic_profile".localized(fallback: "Complete your profile to continue.")
        case .emailVerification:
            return "MOBILE_requirements_generic_email".localized(fallback: "Verify your email address to continue.")
        case .documents:
            return "MOBILE_requirements_generic_documents".localized(fallback: "Add your identity document to continue.")
        case .address:
            return "MOBILE_requirements_generic_address".localized(fallback: "Add your address to continue.")
        case .wallet:
            return "MOBILE_requirements_generic_wallet".localized(fallback: "Top up your wallet to continue.")
        case .card:
            return "MOBILE_requirements_generic_card".localized(fallback: "Add a bank card to continue.")
        case .support:
            return "MOBILE_requirements_generic_support".localized(fallback: "Contact support to continue.")
        case .none:
            return "MOBILE_requirements_generic_none".localized(fallback: "This is not available right now.")
        }
    }
}

extension EligibilityViolation {

    /// The violation's message key from the locale service, or the target's
    /// generic sentence when the code is empty or not translated. Nothing is
    /// hardcoded per rule: the rule set is configurable on the backend.
    var message: String {
        guard !code.isEmpty else { return target.genericMessage }

        var text = code.localized(fallback: target.genericMessage)

        // A translation may place the numbers itself.
        for (key, value) in details {
            text = text.replacingOccurrences(of: "{\(key)}", with: value.displayValue)
        }

        return text
    }

    /// The numbers that come with the rule, e.g. "Balance: 120 RUB · Required: 500 RUB".
    var detailsLine: String? {
        let currency = details["currency"]?.displayValue
        let money: Set<String> = ["balance", "amount", "min", "max", "current", "debt", "required"]

        let parts: [String] = details.keys.sorted().compactMap { key in
            guard key != "currency", let value = details[key] else { return nil }

            var text = value.displayValue
            if let currency, money.contains(key.lowercased()) {
                text += " " + currency
            }

            return "\(Self.detailLabel(for: key)): \(text)"
        }

        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// `MOBILE_requirements_detail_<key>`; a key without a translation is
    /// shown as it came, capitalised.
    private static func detailLabel(for key: String) -> String {
        let fallback: String
        switch key.lowercased() {
        case "balance": fallback = "Balance"
        case "debt": fallback = "Debt"
        case "required": fallback = "Required"
        default: fallback = key.prefix(1).uppercased() + key.dropFirst()
        }

        return "MOBILE_requirements_detail_\(key)".localized(fallback: fallback)
    }

    /// Inputs this rule asks for: the listed `fields`, or the one its rule
    /// names when the list is absent.
    var requiredFields: [RequirementField] {
        let listed = fields.compactMap { RequirementField($0) }
        if !listed.isEmpty { return listed }

        return RequirementField(rule).map { [$0] } ?? []
    }

    /// The button that opens the target's screen. The row above it already
    /// says what to do, so the button only continues.
    var actionTitle: String {
        switch target {
        case .none:
            return "MOBILE_global_ok".localized(fallback: "OK")
        default:
            return "MOBILE_global_continue".localized(fallback: "Continue")
        }
    }

    var iconName: String {
        switch target {
        case .profile: return "person.crop.circle"
        case .emailVerification: return "envelope"
        case .documents: return "doc.text.viewfinder"
        case .address: return "house"
        case .wallet: return "creditcard"
        case .card: return "creditcard.fill"
        case .support: return "bubble.left.and.bubble.right"
        case .none: return "exclamationmark.circle"
        }
    }
}

extension Optional where Wrapped == EligibilityCheck {

    /// The headline of the checklist: what the rider was about to do.
    var purposeTitle: String {
        switch self {
        case .attachCard?:
            return "MOBILE_requirements_purpose_attach_card".localized(fallback: "To add a bank card")
        case .transfer?:
            return "MOBILE_requirements_purpose_transfer".localized(fallback: "To send money")
        case .sharing(action: .startRide)?:
            return "MOBILE_requirements_purpose_bike".localized(fallback: "To start a bike ride")
        case .sharing(action: .book)?:
            return "MOBILE_requirements_purpose_bike_book".localized(fallback: "To book a bike")
        case .scooter?:
            return "MOBILE_requirements_purpose_scooter".localized(fallback: "To start a scooter ride")
        case .powerbank(_, action: .startRent, _, _)?:
            return "MOBILE_requirements_purpose_powerbank".localized(fallback: "To rent a power bank")
        case .powerbank(_, action: .book, _, _)?:
            return "MOBILE_requirements_purpose_powerbank_book".localized(fallback: "To book a power bank")
        case .evCharging?:
            return "MOBILE_requirements_purpose_charging".localized(fallback: "To start charging")
        case nil:
            return "MOBILE_requirements_purpose_generic".localized(fallback: "To continue")
        }
    }
}

extension Array where Element == EligibilityViolation {

    /// Everything to fill on the first violation's screen: its own inputs plus
    /// those of the other rules sent to the same screen, so one visit covers them.
    var primaryFields: [RequirementField] {
        guard let primary = first else { return [] }

        var fields: [RequirementField] = []
        for violation in self where violation.targetValue == primary.targetValue {
            for field in violation.requiredFields where !fields.contains(field) {
                fields.append(field)
            }
        }

        return fields
    }
}
