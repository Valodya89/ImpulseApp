//
//  EligibilityModels.swift
//  Impuls
//
//  One rule the rider does not meet yet. The same shape comes back from every
//  service's `eligibility` pre-check and inside `content.violations` of a
//  rejected action (attach card, scan, book, start charging).
//
//  The backend's rule set is configurable, so every value is read leniently:
//  an unknown rule, code or target never fails decoding, it just falls back to
//  a generic "update your profile" item with no redirect.
//

import Foundation

struct EligibilityViolation: Decodable, Identifiable, Equatable {

    /// Where to send the rider to fix the rule.
    enum Target: String {
        case profile = "PROFILE"
        case emailVerification = "EMAIL_VERIFICATION"
        case documents = "DOCUMENTS"
        case address = "ADDRESS"
        case wallet = "WALLET"
        case card = "CARD"
        case support = "SUPPORT"
        case none = "NONE"
    }

    /// A number or text to show next to the message (balance, currency, amount,
    /// max, current, distance ...).
    enum Detail: Equatable {
        case number(Double)
        case text(String)
        case flag(Bool)

        var displayValue: String {
            switch self {
            case .number(let value):
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.maximumFractionDigits = value.rounded() == value ? 0 : 2
                formatter.groupingSeparator = " "
                return formatter.string(from: NSNumber(value: value)) ?? String(value)
            case .text(let value):
                return value
            case .flag(let value):
                return value ? "MOBILE_global_yes".localized(fallback: "Yes") : "MOBILE_global_no".localized(fallback: "No")
            }
        }
    }

    let rule: String
    /// Message key, localized through the locale module.
    let code: String
    let targetValue: String
    /// Inputs to show on the target screen; empty when there is nothing to fill.
    let fields: [String]
    let details: [String: Detail]

    var id: String { rule + "|" + code + "|" + targetValue }

    var target: Target {
        Target(rawValue: targetValue.uppercased()) ?? .none
    }

    init(rule: String, code: String, target: String, fields: [String] = [], details: [String: Detail] = [:]) {
        self.rule = rule
        self.code = code
        self.targetValue = target
        self.fields = fields
        self.details = details
    }

    private enum CodingKeys: String, CodingKey {
        case rule, code, target, fields, details
    }

    private struct DetailKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }

        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { return nil }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        rule = (try? container.decodeIfPresent(String.self, forKey: .rule)) ?? ""
        code = (try? container.decodeIfPresent(String.self, forKey: .code)) ?? ""
        targetValue = (try? container.decodeIfPresent(String.self, forKey: .target)) ?? Target.none.rawValue
        fields = (try? container.decodeIfPresent([String].self, forKey: .fields)) ?? []

        var details: [String: Detail] = [:]
        if let detailsContainer = try? container.nestedContainer(keyedBy: DetailKey.self, forKey: .details) {
            for key in detailsContainer.allKeys {
                if let value = try? detailsContainer.decode(Bool.self, forKey: key) {
                    details[key.stringValue] = .flag(value)
                } else if let value = try? detailsContainer.decode(Double.self, forKey: key) {
                    details[key.stringValue] = .number(value)
                } else if let value = try? detailsContainer.decode(String.self, forKey: key) {
                    details[key.stringValue] = .text(value)
                }
                // Nested or null values have nothing to display.
            }
        }
        self.details = details
    }
}

/// `content` of every `eligibility` endpoint.
struct EligibilityResult: Decodable {
    let action: String?
    let country: String?
    let satisfied: Bool
    let violations: [EligibilityViolation]

    private enum CodingKeys: String, CodingKey {
        case action, country, satisfied, violations
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        action = try? container.decodeIfPresent(String.self, forKey: .action)
        country = try? container.decodeIfPresent(String.self, forKey: .country)
        violations = (try? container.decodeIfPresent([EligibilityViolation].self, forKey: .violations)) ?? []
        // A response without the flag is judged by its list.
        satisfied = (try? container.decodeIfPresent(Bool.self, forKey: .satisfied)) ?? violations.isEmpty
    }
}

/// An action the backend refused because of unmet rules: `statusCode` and
/// `message` describe the first failing rule, `violations` lists all of them.
struct ActionRejection {
    let statusCode: Int
    let message: String
    let violations: [EligibilityViolation]
    /// The pre-check matching the refused request, when it can be told from it.
    let check: EligibilityCheck?

    private struct Content: Decodable {
        let violations: [EligibilityViolation]?
    }

    private struct Envelope: Decodable {
        let statusCode: Int?
        let message: String?
        let content: Content?
    }

    /// Reads a rejection out of a response body. Returns nil for anything that
    /// is not a refusal carrying `content.violations`.
    static func parse(data: Data, request: URLRequest?) -> ActionRejection? {
        // Almost no response has violations - skip decoding for those.
        guard data.range(of: Data("\"violations\"".utf8)) != nil,
              let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
              let violations = envelope.content?.violations, !violations.isEmpty,
              let statusCode = envelope.statusCode, !(200..<300).contains(statusCode) else {
            return nil
        }

        return ActionRejection(
            statusCode: statusCode,
            message: envelope.message ?? violations[0].code,
            violations: violations,
            check: request.flatMap { EligibilityCheck(rejectedRequest: $0) }
        )
    }
}
