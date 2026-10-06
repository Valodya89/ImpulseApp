//
//  MimoError.swift
//  MimoBike
//
//  Created by Vardan on 12.05.21.
//

import Foundation
import Darwin
import MachO
import Network
import UIKit
import os

final class MimoError: Error {
    public var message: String

    init(error: NetworkError) {
        switch error {
        case .validatorError(let error):
            self.message = error
        case .responseError(let error):
            self.message = error
        case .serverError:
            self.message = "Something went wrong."
        case .invalidParse(let error):
            self.message = error
        case .tooFar(let error):
            self.message = error
        }
    }
}

public enum NetworkError: Error {
    case validatorError(_ errorMessage: String)
    case responseError(_ errorMessage: String)
    case serverError
    case invalidParse(_ errorMessage: String)
    case tooFar(_ errorMessage: String)
}

// =============================================================================
// MARK: - Mobile error reporting
// =============================================================================
//
// Reports crashes, unhandled errors and abnormal behaviour to the accounts
// service, `POST /mobile-errors` (accounts docs/mobile-api.md, heading
// "POST /mobile-errors", commit eb41a3e925cf7da27bc5c6e59b4cf47a9eb6e2f4),
// readable by admins in /api/admin/mobile-errors. Port of the Mimo iOS
// package (MimoBike/ErrorReporting), kept in this one file because the Xcode
// project is not synchronised with the file system.
//
// Pipeline:
//   report() -> guards (20/min, same type+message+top frame once per 10 min)
//            -> sanitise + clamp to the backend limits -> write to the disk
//               queue -> flush()
//   flush()  -> oldest first: 2xx and 4xx (except 429) delete the file;
//               429 / 5xx keep it and stop this pass (one retry, then the
//               report is dropped); no answer (offline) keeps it, stops and
//               does not count as an attempt. Flushed at launch, after every
//               report and when NWPathMonitor reports the network back.
//
// Sources:
//   - CrashHandler: NSSetUncaughtExceptionHandler + signal handlers. Nothing
//     is sent from a dying process: the crash is written to disk and sent as
//     CRASH on the next launch. Previous handlers (Crashlytics) are chained.
//   - NetworkFailureReporter: both HTTP stacks (SessionNetwork and
//     NetworkService) hand over every answer; 5xx and non-cancelled transport
//     failures while online are reported (gateway / CDN statuses and
//     unresolved hosts as OTHER, the rest as UNHANDLED_ERROR) with the method,
//     the path without query and a sanitised 500-character body excerpt.
//   - ErrorReporter.logError / reportAbnormalBehavior / reportIfUnexpected:
//     the explicit hook for callers.
//
// Identification: the backend's `x-s-app` header only knows MIMO / EVUP
// (same document); Impulse talks to its own accounts deployment and sends no
// `x-s-app` (like Impulse Android), so `extra["app"] = "impulse"` names the
// app in the report itself.
//
// Privacy: bearer tokens, JWTs, Luhn-valid card numbers (last four kept),
// phone numbers other than the rider's own (+ and 8-15 digits), and the
// secret / phone-named JSON and form fields are masked before anything is
// written to disk. A JWT is sent only while it is valid; the phone number
// (`userId`) only without one.

// MARK: - DTO

/// One `POST /mobile-errors` body (`MobileErrorReportDto`). The backend
/// answers 400 to anything over its limits, and a 4xx deletes the queued
/// file, so every limit is enforced here before a report is written to disk.
struct MobileErrorReport: Codable, Equatable {

    enum Kind: String, Codable {
        case crash = "CRASH"
        case unhandledError = "UNHANDLED_ERROR"
        case abnormalBehavior = "ABNORMAL_BEHAVIOR"
        case other = "OTHER"
    }

    let type: Kind
    let message: String
    let stackTrace: String?
    let screen: String?
    let action: String?
    let deviceId: String?
    let deviceModel: String?
    let osVersion: String?
    let appVersion: String?
    /// Phone number. Only meaningful when no JWT is attached - dropped at send
    /// time when one is (see `ErrorReportSender`).
    var userId: String?
    /// Epoch milliseconds on the device.
    let occurredAt: Int64
    let extra: [String: String]

    init(
        type: Kind,
        message: String,
        stackTrace: String?,
        screen: String?,
        action: String?,
        context: ErrorReportContext,
        occurredAt: Int64,
        extra: [String: String]
    ) {
        self.type = type
        self.message = Limits.clamp(message.isEmpty ? "(no message)" : message, Limits.message)
        self.stackTrace = stackTrace.map { Limits.clamp($0, Limits.stackTrace) }
        self.screen = screen.map { Limits.clamp($0, Limits.screen) }
        self.action = action.map { Limits.clamp($0, Limits.action) }
        self.deviceId = context.deviceId.map { Limits.clamp($0, Limits.deviceId) }
        self.deviceModel = Limits.clamp(context.deviceModel, Limits.deviceModel)
        self.osVersion = Limits.clamp(context.osVersion, Limits.osVersion)
        self.appVersion = Limits.clamp(context.appVersion, Limits.appVersion)
        self.userId = context.userId.map { Limits.clamp($0, Limits.userId) }
        self.occurredAt = occurredAt
        self.extra = Limits.clampExtra(context.baseExtra.merging(extra) { _, callSite in callSite })
    }

    /// Backend limits from `MobileErrorReportDto`.
    enum Limits {
        static let message = 2000
        static let stackTrace = 30000
        static let screen = 200
        static let action = 500
        static let deviceId = 200
        static let deviceModel = 200
        static let osVersion = 100
        static let appVersion = 50
        static let userId = 50
        static let extraEntries = 30
        static let extraValue = 2000
        /// Response bodies carried in `extra["responseBody"]`.
        static let responseBody = 500

        /// Cuts on UTF-16 length, which is how the backend measures a string,
        /// and never through the middle of a character.
        static func clamp(_ value: String, _ limit: Int) -> String {
            guard value.utf16.count > limit else { return value }

            var result = ""
            var length = 0
            for character in value {
                let characterLength = character.utf16.count
                guard length + characterLength <= limit else { break }
                result.append(character)
                length += characterLength
            }
            return result
        }

        /// Keeps the context keys ahead of call-site extras when the map is
        /// over its entry limit.
        static func clampExtra(_ extra: [String: String]) -> [String: String] {
            let priority = ErrorReportContext.baseExtraKeys
            let ordered = extra.keys.sorted { lhs, rhs in
                let lhsFirst = priority.contains(lhs), rhsFirst = priority.contains(rhs)
                return lhsFirst != rhsFirst ? lhsFirst : lhs < rhs
            }

            var clamped: [String: String] = [:]
            for key in ordered.prefix(extraEntries) {
                clamped[key] = clamp(extra[key] ?? "", extraValue)
            }
            return clamped
        }
    }
}

/// Everything about the device, install and session a report carries besides
/// the error itself. Captured when the report is created, so a crash that is
/// only sent on the next launch still reports the version it crashed on.
struct ErrorReportContext: Equatable {

    static let baseExtraKeys: Set<String> = [
        "app", "buildNumber", "buildType", "backendEnv", "locale", "network",
        "batteryLevel", "freeMemoryMb", "sessionId", "breadcrumbs"
    ]

    var deviceId: String?
    var deviceModel: String
    var osVersion: String
    var appVersion: String
    var userId: String?
    var baseExtra: [String: String]
}

/// What sits in the disk queue: the report plus how many answers from the
/// backend it has already used up.
struct QueuedErrorReport: Codable, Equatable {
    var attempts: Int
    var report: MobileErrorReport
}

// MARK: - Sanitiser

/// Masks secrets before a report is written: bearer tokens, JWTs, Luhn-valid
/// card numbers (last four kept), phone numbers other than the rider's own,
/// and the secret / phone-named JSON and form fields.
struct ReportSanitizer {

    static let secretFields = [
        "password", "pin", "otp", "code", "smsCode", "token", "access_token", "refresh_token",
        "accessToken", "refreshToken", "cvv", "cvc", "cardNumber", "pan", "secret"
    ]

    static let phoneFields = [
        "phone", "phoneNumber", "msisdn", "toPhone", "fromPhone", "recipientPhone", "username"
    ]

    /// The rider's own number is allowed through: it is the report's `userId`
    /// anyway, and it is what the admin searches for.
    let ownPhone: String?

    init(ownPhone: String? = nil) {
        self.ownPhone = ownPhone
    }

    func sanitize(_ text: String) -> String {
        guard !text.isEmpty else { return text }

        var result = text
        result = Self.bearer.stringByReplacingMatches(in: result, range: result.nsRange, withTemplate: "Bearer ***")
        result = Self.jwt.stringByReplacingMatches(in: result, range: result.nsRange, withTemplate: "***")
        result = Self.secretJSONField.stringByReplacingMatches(in: result, range: result.nsRange, withTemplate: "\"$1\"$2\"***\"")
        result = Self.secretFormField.stringByReplacingMatches(in: result, range: result.nsRange, withTemplate: "$1=***")
        result = maskPhoneFields(in: result)
        result = maskCardNumbers(in: result)
        result = maskPhoneNumbers(in: result)
        return result
    }

    func sanitize(_ extra: [String: String]) -> [String: String] {
        extra.mapValues { sanitize($0) }
    }

    /// A response body as it goes into `extra["responseBody"]`: text only,
    /// sanitised, cut to the body limit.
    func responseBody(_ data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }
        guard let text = String(data: data, encoding: .utf8) else {
            return "<\(data.count) bytes, not text>"
        }
        return MobileErrorReport.Limits.clamp(sanitize(text), MobileErrorReport.Limits.responseBody)
    }

    private static let bearer = try! NSRegularExpression(pattern: #"(?i)\bbearer\s+[A-Za-z0-9\-._~+/]+=*"#)
    /// Anything that starts like a base64url JSON object - every JWT does.
    private static let jwt = try! NSRegularExpression(pattern: #"\beyJ[A-Za-z0-9_\-]{8,}(?:\.[A-Za-z0-9_\-]*)*"#)
    private static let secretJSONField = try! NSRegularExpression(
        pattern: "(?i)\"(" + secretFields.joined(separator: "|") + ")\"(\\s*:\\s*)(?:\"(?:[^\"\\\\]|\\\\.)*\"|[0-9.]+)"
    )
    private static let secretFormField = try! NSRegularExpression(
        pattern: "(?i)\\b(" + secretFields.joined(separator: "|") + ")=([^&\\s\"]+)"
    )
    private static let phoneJSONField = try! NSRegularExpression(
        pattern: "(?i)\"(" + phoneFields.joined(separator: "|") + ")\"(\\s*:\\s*)\"([^\"]*)\""
    )
    /// 13-19 digits, optionally separated by single spaces or dashes; only a
    /// Luhn-valid run is masked, so ids and timestamps stay readable.
    private static let cardNumber = try! NSRegularExpression(pattern: #"(?<![\d])(?:\d[ -]?){12,18}\d(?![\d])"#)
    /// International format: + and 8-15 digits.
    private static let phoneNumber = try! NSRegularExpression(pattern: #"\+\d{8,15}\b"#)

    private func maskPhoneFields(in text: String) -> String {
        replaceMatches(of: Self.phoneJSONField, in: text) { match, source in
            let key = source.substring(match.range(at: 1))
            let separator = source.substring(match.range(at: 2))
            let value = source.substring(match.range(at: 3))
            return "\"\(key)\"\(separator)\"\(isOwnPhone(value) ? value : "***")\""
        }
    }

    private func maskPhoneNumbers(in text: String) -> String {
        replaceMatches(of: Self.phoneNumber, in: text) { match, source in
            let value = source.substring(match.range)
            return isOwnPhone(value) ? value : "+***"
        }
    }

    private func maskCardNumbers(in text: String) -> String {
        replaceMatches(of: Self.cardNumber, in: text) { match, source in
            let value = source.substring(match.range)
            let digits = value.filter(\.isNumber)
            guard Self.passesLuhn(digits), !isOwnPhone(value) else { return value }
            return "**** **** **** " + digits.suffix(4)
        }
    }

    private func isOwnPhone(_ value: String) -> Bool {
        guard let ownPhone, !ownPhone.isEmpty else { return false }
        let own = ownPhone.filter(\.isNumber)
        let candidate = value.filter(\.isNumber)
        return !own.isEmpty && (candidate == own || candidate.hasSuffix(own) || own.hasSuffix(candidate) && candidate.count >= 8)
    }

    private func replaceMatches(
        of expression: NSRegularExpression,
        in text: String,
        with replacement: (NSTextCheckingResult, NSString) -> String
    ) -> String {
        let source = text as NSString
        let matches = expression.matches(in: text, range: text.nsRange)
        guard !matches.isEmpty else { return text }

        let result = NSMutableString(string: text)
        for match in matches.reversed() {
            result.replaceCharacters(in: match.range, with: replacement(match, source))
        }
        return result as String
    }

    static func passesLuhn(_ digits: String) -> Bool {
        guard (13...19).contains(digits.count) else { return false }
        var sum = 0
        for (index, character) in digits.reversed().enumerated() {
            guard var digit = character.wholeNumberValue else { return false }
            if index % 2 == 1 {
                digit *= 2
                if digit > 9 { digit -= 9 }
            }
            sum += digit
        }
        return sum % 10 == 0
    }
}

private extension String {
    var nsRange: NSRange { NSRange(location: 0, length: (self as NSString).length) }
}

private extension NSString {
    func substring(_ range: NSRange) -> String {
        range.location == NSNotFound ? "" : substring(with: range)
    }
}

// MARK: - Disk queue

/// One JSON file per report in a directory excluded from backups, named so a
/// plain sort is oldest-first. Writes are synchronous and queue-free on
/// purpose - the uncaught-exception handler calls them from a dying thread.
final class ErrorReportQueue {

    let directory: URL
    let maxFiles: Int

    init(directory: URL, maxFiles: Int) {
        self.directory = directory
        self.maxFiles = maxFiles

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        var excluded = directory
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? excluded.setResourceValues(values)
    }

    /// Oldest first.
    func files() -> [URL] {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private static let sequenceLock = NSLock()
    private static var sequence = 0

    @discardableResult
    func write(_ queued: QueuedErrorReport) -> URL? {
        guard let data = try? JSONEncoder().encode(queued) else { return nil }

        Self.sequenceLock.lock()
        Self.sequence += 1
        let sequence = Self.sequence
        Self.sequenceLock.unlock()
        let name = String(format: "%013lld-%06d-%@.json", queued.report.occurredAt, sequence, UUID().uuidString)
        let url = directory.appendingPathComponent(name)

        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return nil
        }

        trim()
        return url
    }

    func read(_ url: URL) -> QueuedErrorReport? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(QueuedErrorReport.self, from: data)
    }

    func update(_ queued: QueuedErrorReport, at url: URL) {
        guard let data = try? JSONEncoder().encode(queued) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func remove(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
    }

    /// Oldest reports go first when the queue is over its cap.
    func trim() {
        let files = files()
        guard files.count > maxFiles else { return }

        for file in files.prefix(files.count - maxFiles) {
            remove(file)
        }
    }
}

// MARK: - Guards

/// At most `maxPerMinute` reports a minute, and the same error - type,
/// message and top stack frame - at most once per `duplicateWindow`.
final class ReportGuards {

    let maxPerMinute: Int
    let duplicateWindow: TimeInterval

    private var recentReportTimes: [Date] = []
    private var lastSeenByFingerprint: [String: Date] = [:]

    init(maxPerMinute: Int, duplicateWindow: TimeInterval) {
        self.maxPerMinute = maxPerMinute
        self.duplicateWindow = duplicateWindow
    }

    /// Not thread-safe by itself: the reporter calls it on its io queue.
    func admit(type: MobileErrorReport.Kind, message: String, stackTrace: String?, at now: Date) -> Bool {
        lastSeenByFingerprint = lastSeenByFingerprint.filter { now.timeIntervalSince($0.value) < duplicateWindow }
        let fingerprint = Self.fingerprint(type: type, message: message, stackTrace: stackTrace)
        guard lastSeenByFingerprint[fingerprint] == nil else { return false }

        recentReportTimes.removeAll { now.timeIntervalSince($0) >= 60 }
        guard recentReportTimes.count < maxPerMinute else { return false }

        recentReportTimes.append(now)
        lastSeenByFingerprint[fingerprint] = now
        return true
    }

    static func fingerprint(type: MobileErrorReport.Kind, message: String, stackTrace: String?) -> String {
        [type.rawValue, message, topFrame(of: stackTrace)].joined(separator: "|")
    }

    /// The first frame that is not the reporting machinery itself, without its
    /// frame index, so the same call site matches across reports.
    static func topFrame(of stackTrace: String?) -> String {
        guard let stackTrace else { return "" }

        let frame = stackTrace
            .split(separator: "\n")
            .first { line in
                !line.contains("ErrorReporter") && !line.contains("ReportGuards") && !line.contains("NetworkFailureReporter")
            } ?? ""

        return frame
            .split(separator: " ", omittingEmptySubsequences: true)
            .dropFirst()
            .joined(separator: " ")
    }
}

// MARK: - Sender

struct ErrorReportSenderConfiguration {
    /// `POST /mobile-errors` on the accounts host. Nil when no URL can be
    /// built, which keeps the queue waiting instead of dropping it.
    var endpoint: () -> URL?
    var session: URLSession
    /// `app-version` header value.
    var appVersion: () -> String
    /// A valid access token, or nil to send the report anonymously.
    var accessToken: () -> String?
}

enum ErrorReportSendOutcome: Equatable {
    /// Accepted (2xx) or refused for good (4xx other than 429): delete the file.
    case delete
    /// 5xx or 429: keep the file, count an attempt and stop this flush.
    case retryLater
    /// No answer at all (offline, timeout): keep the file and stop this flush
    /// without counting an attempt - a report queued offline must still be
    /// there when the network returns.
    case unreachable
}

/// Sends one report and says what to do with the queued file afterwards.
/// Synchronous: the reporter runs it on its own serial send queue.
final class ErrorReportSender {

    static let endpointPath = "mobile-errors"

    private let configuration: ErrorReportSenderConfiguration

    init(configuration: ErrorReportSenderConfiguration) {
        self.configuration = configuration
    }

    func send(_ original: MobileErrorReport) -> (outcome: ErrorReportSendOutcome, status: Int?) {
        guard let url = configuration.endpoint() else {
            return (.unreachable, nil)
        }

        var report = original
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // No `x-s-app`: the backend only defines MIMO / EVUP for it, and Impulse
        // has its own accounts deployment. The app is named in extra["app"].
        request.setValue("IOS", forHTTPHeaderField: "os-type")
        request.setValue(configuration.appVersion(), forHTTPHeaderField: "app-version")

        // With a token the backend takes the user from it (userIdVerified); the
        // phone number is only a fallback for anonymous reports.
        if let token = configuration.accessToken(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            report.userId = nil
        }

        guard let body = try? JSONEncoder().encode(report) else { return (.delete, nil) }
        request.httpBody = body

        let semaphore = DispatchSemaphore(value: 0)
        var outcome = ErrorReportSendOutcome.unreachable
        var status: Int?

        configuration.session.dataTask(with: request) { _, response, error in
            defer { semaphore.signal() }

            guard error == nil, let code = (response as? HTTPURLResponse)?.statusCode else {
                outcome = .unreachable
                return
            }
            status = code

            switch code {
            case 200..<300:
                outcome = .delete
            case 429:
                // Over the 60/minute IP limit: the report waits for the next flush.
                outcome = .retryLater
            case 400..<500:
                outcome = .delete
            default:
                outcome = .retryLater
            }
        }.resume()

        semaphore.wait()
        return (outcome, status)
    }
}

// MARK: - Core pipeline

struct MobileErrorReporterConfiguration {
    var queueDirectory: URL
    var sender: ErrorReportSenderConfiguration
    /// Device, install and session facts for every report.
    var context: () -> ErrorReportContext
    /// The rider's own phone number: the only one the sanitiser lets through.
    var ownPhone: () -> String?
    /// Fallback `action` for ABNORMAL_BEHAVIOR reports without one.
    var lastAction: () -> String?
    var now: () -> Date = Date.init

    var maxQueuedFiles = 30
    var maxAttemptsPerReport = 2
    var maxReportsPerMinute = 20
    var duplicateWindow: TimeInterval = 10 * 60
}

final class MobileErrorReporterCore {

    let configuration: MobileErrorReporterConfiguration
    let queue: ErrorReportQueue

    private let guards: ReportGuards
    private let sender: ErrorReportSender

    /// File writes and guard bookkeeping; kept apart from `sendQueue` so a
    /// report is on disk at once even while a slow request holds the sender.
    private let ioQueue = DispatchQueue(label: "ru.impulsepower.error-reporter.io")
    private let sendQueue = DispatchQueue(label: "ru.impulsepower.error-reporter.send")

    /// Set by a 429 or a report that must wait: nothing more is sent until the
    /// next launch or until the network comes back.
    private let stopLock = NSLock()
    private var flushStoppedUntilNetwork = false

    init(configuration: MobileErrorReporterConfiguration) {
        self.configuration = configuration
        self.queue = ErrorReportQueue(directory: configuration.queueDirectory, maxFiles: configuration.maxQueuedFiles)
        self.guards = ReportGuards(
            maxPerMinute: configuration.maxReportsPerMinute,
            duplicateWindow: configuration.duplicateWindow
        )
        self.sender = ErrorReportSender(configuration: configuration.sender)
    }

    /// Builds, guards, sanitises and queues a report, then flushes.
    func report(
        type: MobileErrorReport.Kind,
        message: String,
        stackTrace: String?,
        screen: String?,
        action: String?,
        extra: [String: String]
    ) {
        let now = configuration.now()
        let occurredAt = Self.milliseconds(now)
        let context = configuration.context()
        let lastAction = configuration.lastAction()

        ioQueue.async {
            guard self.guards.admit(type: type, message: message, stackTrace: stackTrace, at: now) else { return }

            let report = self.makeReport(
                type: type, message: message, stackTrace: stackTrace, screen: screen,
                action: action ?? (type == .abnormalBehavior ? (lastAction ?? "no user action recorded") : nil),
                context: context, occurredAt: occurredAt, extra: extra
            )
            self.queue.write(QueuedErrorReport(attempts: 0, report: report))
            self.flush()
        }
    }

    /// Queues a report that bypasses the guards - a crash converted on the next
    /// launch. Synchronous, so the caller can flush right after it.
    func enqueue(
        type: MobileErrorReport.Kind,
        message: String,
        stackTrace: String?,
        screen: String?,
        action: String?,
        context: ErrorReportContext,
        occurredAt: Int64,
        extra: [String: String]
    ) {
        let report = makeReport(
            type: type, message: message, stackTrace: stackTrace, screen: screen,
            action: action, context: context, occurredAt: occurredAt, extra: extra
        )
        queue.write(QueuedErrorReport(attempts: 0, report: report))
    }

    /// Synchronous and queue-free: the uncaught-exception handler calls it from
    /// a thread that is about to die. Nothing is sent from a dying process.
    @discardableResult
    func writeImmediately(
        type: MobileErrorReport.Kind,
        message: String,
        stackTrace: String?,
        screen: String?,
        extra: [String: String]
    ) -> Bool {
        let report = makeReport(
            type: type, message: message, stackTrace: stackTrace, screen: screen,
            action: nil, context: configuration.context(),
            occurredAt: Self.milliseconds(configuration.now()), extra: extra
        )
        return queue.write(QueuedErrorReport(attempts: 0, report: report)) != nil
    }

    private func makeReport(
        type: MobileErrorReport.Kind,
        message: String,
        stackTrace: String?,
        screen: String?,
        action: String?,
        context: ErrorReportContext,
        occurredAt: Int64,
        extra: [String: String]
    ) -> MobileErrorReport {
        let sanitizer = ReportSanitizer(ownPhone: configuration.ownPhone())
        var context = context
        context.baseExtra = sanitizer.sanitize(context.baseExtra)

        return MobileErrorReport(
            type: type,
            message: sanitizer.sanitize(message),
            stackTrace: stackTrace.map { sanitizer.sanitize($0) },
            screen: screen,
            action: action.map { sanitizer.sanitize($0) },
            context: context,
            occurredAt: occurredAt,
            extra: sanitizer.sanitize(extra)
        )
    }

    /// Sends queued reports oldest-first until the queue is empty or a report
    /// has to wait. `networkReturned` lifts a stop caused by an earlier pass.
    func flush(networkReturned: Bool = false) {
        sendQueue.async {
            self.stopLock.lock()
            if networkReturned { self.flushStoppedUntilNetwork = false }
            let stopped = self.flushStoppedUntilNetwork
            self.stopLock.unlock()
            guard !stopped else { return }

            guard self.configuration.sender.endpoint() != nil else { return }

            for file in self.queue.files() {
                guard var queued = self.queue.read(file) else {
                    // Unreadable (a half-written file): it can never be sent, so it
                    // must not block the queue behind it.
                    self.queue.remove(file)
                    continue
                }

                let result = self.sender.send(queued.report)
                #if DEBUG
                print("ErrorReporter: \(queued.report.type.rawValue) -> \(result.status.map { "HTTP \($0)" } ?? "no response"), \(result.outcome)")
                #endif

                switch result.outcome {
                case .delete:
                    self.queue.remove(file)
                case .retryLater:
                    queued.attempts += 1
                    if queued.attempts >= self.configuration.maxAttemptsPerReport {
                        self.queue.remove(file)
                    } else {
                        self.queue.update(queued, at: file)
                    }
                    // A 429 means the IP is over its budget: sending more now would
                    // only burn the remaining attempts. Wait for the next launch or
                    // for the network to come back.
                    if result.status == 429 {
                        self.stopLock.lock()
                        self.flushStoppedUntilNetwork = true
                        self.stopLock.unlock()
                    }
                    return
                case .unreachable:
                    return
                }
            }
        }
    }

    static func milliseconds(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000).rounded())
    }

    /// The caller's stack, starting at the code that reported.
    static func currentStackTrace() -> String {
        let frames = Thread.callStackSymbols
        let firstCallerFrame = frames.firstIndex { !$0.contains("ErrorReporter") } ?? 0
        return frames[firstCallerFrame...].joined(separator: "\n")
    }
}

// MARK: - Breadcrumbs

/// The last few screen changes and actions, newest last, for `extra`
/// ["breadcrumbs"] and the crash marker. Thread-safe.
final class Breadcrumbs {

    static let maxEntries = 10

    private let lock = NSLock()
    private var entries: [String] = []
    private var _lastAction: String?

    func recordScreen(_ name: String) {
        append("screen:\(name)")
    }

    func recordAction(_ name: String) {
        lock.lock()
        _lastAction = name
        lock.unlock()
        append("action:\(name)")
    }

    var trail: String {
        lock.lock(); defer { lock.unlock() }
        return entries.joined(separator: " > ")
    }

    var lastAction: String? {
        lock.lock(); defer { lock.unlock() }
        return _lastAction
    }

    private func append(_ entry: String) {
        lock.lock()
        entries.append(entry.replacingOccurrences(of: "\n", with: " "))
        if entries.count > Self.maxEntries {
            entries.removeFirst(entries.count - Self.maxEntries)
        }
        let trail = entries.joined(separator: " > ")
        lock.unlock()
        CrashHandler.updateBreadcrumbs(trail)
    }
}

// MARK: - App binding

/// The app-facing reporter: binds the pipeline to the accounts endpoint, the
/// keychain, the device context, the crash handlers and the network monitor.
final class ErrorReporter {

    static let shared = ErrorReporter()

    /// Random id per launch, so the reports of one run can be grouped.
    static let sessionId = UUID().uuidString

    let breadcrumbs = Breadcrumbs()
    let core: MobileErrorReporterCore

    private let networkStatus = NetworkStatus()
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "ru.impulsepower.error-reporter.network")
    private var isStarted = false

    /// "wifi", "cellular" or "offline", as last seen by the path monitor.
    var networkKind: String { networkStatus.kind }
    var isOnline: Bool { networkStatus.isOnline }

    private init() {
        let breadcrumbs = self.breadcrumbs
        let networkStatus = self.networkStatus

        let sender = ErrorReportSenderConfiguration(
            endpoint: { ErrorReporter.endpoint },
            session: ErrorReporter.makeSession(),
            appVersion: { AppReportContext.appVersionHeader },
            accessToken: {
                // An expired token would earn a 401 - which deletes the report -
                // so the report goes anonymous instead.
                let keychain = KeychainManager()
                guard let token = keychain.getAccessToken(), !token.isEmpty, !keychain.isTokenExpired() else { return nil }
                return token
            }
        )

        let configuration = MobileErrorReporterConfiguration(
            queueDirectory: ErrorReporter.reportsDirectory,
            sender: sender,
            context: { AppReportContext.current(network: networkStatus.kind, breadcrumbs: breadcrumbs.trail) },
            ownPhone: { AppReportContext.phoneNumber },
            lastAction: { breadcrumbs.lastAction }
        )
        core = MobileErrorReporterCore(configuration: configuration)
    }

    // MARK: Lifecycle

    /// Call once at launch, on the main thread. Installs the crash handlers,
    /// converts a crash left by the previous run into a CRASH report, flushes
    /// the queue and starts flushing again whenever the network returns.
    func start() {
        guard !isStarted else { return }
        isStarted = true

        CrashHandler.install(reportsDirectory: Self.reportsDirectory)
        ScreenTracker.install()
        AppReportContext.startBatteryMonitoring()

        DispatchQueue.global(qos: .utility).async {
            CrashHandler.convertPendingCrashes(in: Self.reportsDirectory) { crash in
                self.core.enqueue(
                    type: .crash,
                    message: crash.message,
                    stackTrace: crash.stackTrace,
                    screen: crash.screen,
                    action: nil,
                    context: crash.context,
                    occurredAt: crash.occurredAt,
                    extra: crash.extra
                )
            }
            self.core.flush()
        }

        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let wasOnline = self.networkStatus.isOnline
            self.networkStatus.update(from: path)
            CrashHandler.updateNetwork(self.networkStatus.kind)
            if self.networkStatus.isOnline && !wasOnline {
                self.core.flush(networkReturned: true)
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    // MARK: Reporting

    /// Reports `UNHANDLED_ERROR` unless the error is an expected one (network
    /// failure, cancellation, the app's own business errors).
    func reportIfUnexpected(_ error: Error, action: String? = nil, extra: [String: String] = [:]) {
        guard ErrorClassifier.isUnexpected(error) else { return }

        report(
            type: .unhandledError,
            message: "Unhandled: \(ErrorClassifier.describe(error))",
            stackTrace: MobileErrorReporterCore.currentStackTrace(),
            action: action,
            extra: extra
        )
    }

    /// For code that notices something is wrong but has no `Error` to show for
    /// it - a timeout that should never fire, a capture that returned nothing.
    func reportAbnormalBehavior(_ message: String, action: String? = nil, extra: [String: String] = [:]) {
        report(
            type: .abnormalBehavior,
            message: message,
            stackTrace: MobileErrorReporterCore.currentStackTrace(),
            action: action,
            extra: extra
        )
    }

    /// An error-level log line. With an error it is an UNHANDLED_ERROR, without
    /// one an ABNORMAL_BEHAVIOR - the one entry point for "log at error level".
    func logError(_ message: String, error: Error? = nil, extra: [String: String] = [:]) {
        if let error {
            report(
                type: .unhandledError,
                message: "Log: \(message): \(ErrorClassifier.describe(error))",
                stackTrace: MobileErrorReporterCore.currentStackTrace(),
                action: nil,
                extra: extra
            )
        } else {
            report(
                type: .abnormalBehavior,
                message: "Log: \(message)",
                stackTrace: MobileErrorReporterCore.currentStackTrace(),
                action: nil,
                extra: extra
            )
        }
    }

    func report(
        type: MobileErrorReport.Kind,
        message: String,
        stackTrace: String?,
        action: String? = nil,
        extra: [String: String] = [:]
    ) {
        let trace: String?
        switch type {
        case .crash, .unhandledError:
            trace = stackTrace ?? MobileErrorReporterCore.currentStackTrace()
        case .abnormalBehavior, .other:
            trace = stackTrace
        }

        core.report(
            type: type,
            message: message,
            stackTrace: trace,
            screen: ScreenTracker.currentScreen,
            action: action,
            extra: extra
        )
    }

    /// A user action worth remembering for the breadcrumb trail and as the
    /// `action` of a later ABNORMAL_BEHAVIOR report.
    func recordAction(_ name: String) {
        breadcrumbs.recordAction(name)
    }

    /// Called by the uncaught-exception handler, synchronously, from a thread
    /// that is about to die.
    func writeCrash(message: String, stackTrace: String?, extra: [String: String]) {
        core.writeImmediately(
            type: .crash,
            message: message,
            stackTrace: stackTrace,
            screen: ScreenTracker.currentScreen,
            extra: extra
        )
    }

    func flush() {
        core.flush()
    }

    // MARK: Configuration

    static let reportsDirectory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("ErrorReports", isDirectory: true)
    }()

    /// `POST /mobile-errors` on the accounts host of this build's backend.
    /// Debug builds accept `-ImpulseErrorReportsURL <url>` as a launch argument.
    static var endpoint: URL? {
        #if DEBUG
        if let override = UserDefaults.standard.string(forKey: "ImpulseErrorReportsURL") {
            return URL(string: override)
        }
        #endif
        return URL(string: MimoBaseURLs.accounts.rawValue + ErrorReportSender.endpointPath)
    }

    private static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 20
        configuration.timeoutIntervalForResource = 30
        configuration.waitsForConnectivity = false
        return URLSession(configuration: configuration)
    }
}

/// Thread-safe snapshot of the path monitor, read on every report.
final class NetworkStatus {
    private let lock = NSLock()
    private var _kind = "unknown"
    private var _isOnline = true

    var kind: String {
        lock.lock(); defer { lock.unlock() }
        return _kind
    }

    var isOnline: Bool {
        lock.lock(); defer { lock.unlock() }
        return _isOnline
    }

    func update(from path: NWPath) {
        let online = path.status == .satisfied
        let kind: String
        if !online {
            kind = "offline"
        } else if path.usesInterfaceType(.wifi) || path.usesInterfaceType(.wiredEthernet) {
            kind = "wifi"
        } else if path.usesInterfaceType(.cellular) {
            kind = "cellular"
        } else {
            kind = "wifi"
        }

        lock.lock()
        _isOnline = online
        _kind = kind
        lock.unlock()
    }
}

// MARK: - Error classification

enum ErrorClassifier {

    /// "URLError: The request timed out." / "DecodingError: ..." - never "null".
    static func describe(_ error: Error) -> String {
        let nsError = error as NSError
        let typeName = String(describing: type(of: error))
        let description = error.localizedDescription
        if nsError.domain == NSURLErrorDomain || nsError.domain == NSPOSIXErrorDomain {
            return "\(typeName) \(nsError.domain) \(nsError.code): \(description)"
        }
        return "\(typeName): \(description)"
    }

    /// Expected and not reported: transport failures, cancellations, the app's
    /// own request / business errors. Reported: decoding failures, unexpected
    /// HTTP statuses and unknown error types.
    static func isUnexpected(_ error: Error) -> Bool {
        if error is CancellationError { return false }
        if error is URLError { return false }
        if error is DecodingError { return true }
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain { return false }

        if let apiError = error as? APIError {
            switch apiError {
            case .responseError, .authorizationError:
                return false
            case .invalidURL, .missingData, .requestFailed, .decodingFailed:
                return true
            }
        }
        if let sessionError = error as? NetworkSessionErrors {
            switch sessionError {
            case .sessionExpired:
                return false
            case .invalidRequest(_, let underlying):
                return underlying.map { isUnexpected($0) } ?? true
            case .invalidStatusCode(let code):
                return code >= 500
            case .resultsError, .unknown:
                return true
            }
        }
        if let networkError = error as? NetworkError {
            switch networkError {
            case .invalidParse, .serverError:
                return true
            case .validatorError, .responseError, .tooFar:
                return false
            }
        }
        if error is MimoError { return false }
        return true
    }
}

// MARK: - Context

/// The device, install and session facts every report carries. Safe to call
/// from any thread: battery level is cached on the main thread, everything
/// else is thread-safe to read.
enum AppReportContext {

    static func current(network: String, breadcrumbs: String) -> ErrorReportContext {
        let info = Bundle.main.infoDictionary
        let deviceId = DeviceCheckManager.shared.deviceUnicToken

        return ErrorReportContext(
            deviceId: deviceId.isEmpty ? nil : deviceId,
            deviceModel: deviceModelIdentifier,
            osVersion: osVersionString,
            appVersion: info?["CFBundleShortVersionString"] as? String ?? "unknown",
            userId: phoneNumber,
            baseExtra: [
                "app": "impulse",
                "buildNumber": info?["CFBundleVersion"] as? String ?? "unknown",
                "buildType": buildType,
                "backendEnv": backendEnvironment,
                "locale": locale,
                "network": network,
                "batteryLevel": batteryLevelString,
                "freeMemoryMb": "\(freeMemoryMb)",
                "sessionId": ErrorReporter.sessionId,
                "breadcrumbs": breadcrumbs
            ]
        )
    }

    /// The rider's phone number: `userId` of an anonymous report, and the one
    /// number the sanitiser lets through.
    static var phoneNumber: String? {
        StorageManager().fetch(key: .phoneNumber, type: String.self).flatMap { $0.isEmpty ? nil : $0 }
    }

    static var locale: String {
        StorageManager().fetch(key: .language, type: String.self) ?? String(Locale.current.deviceLanguageCode)
    }

    /// The `app-version` header value, in the format both network stacks send:
    /// "1.0.0" goes out as "1.00", "1.2" as "1.2".
    static var appVersionHeader: String {
        guard let marketingVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String else {
            return ""
        }

        let components = marketingVersion.components(separatedBy: ".")
        if components.count > 2 {
            return "\(components[0]).\(components[1])\(components[2])"
        } else if components.count == 2 {
            return "\(components[0]).\(components[1])"
        }
        return marketingVersion
    }

    static var buildType: String {
        #if DEBUG
        return "debug"
        #else
        return "release"
        #endif
    }

    /// The Dev and Prod targets compile different `MimoBaseURLs`.
    static var backendEnvironment: String {
        MimoBaseURLs.accounts.rawValue.contains("://dev-") ? "dev" : "prod"
    }

    /// "iPhone18,1". On the simulator the emulated model comes from its environment.
    static var deviceModelIdentifier: String {
        if let simulated = ProcessInfo.processInfo.environment["SIMULATOR_MODEL_IDENTIFIER"] {
            return simulated
        }

        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafeBytes(of: &systemInfo.machine) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
    }

    /// "iOS 18.4.0". `ProcessInfo` rather than `UIDevice`, which belongs to the
    /// main thread.
    static var osVersionString: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "iOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /// Memory the process may still allocate, in megabytes.
    static var freeMemoryMb: Int {
        Int(os_proc_available_memory() / (1024 * 1024))
    }

    private static let batteryLock = NSLock()
    private static var cachedBatteryLevel: Float = -1

    /// Main thread. Turns battery monitoring on and keeps a copy of the level
    /// that a background queue may read.
    static func startBatteryMonitoring() {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        storeBatteryLevel(device.batteryLevel)

        NotificationCenter.default.addObserver(
            forName: UIDevice.batteryLevelDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            storeBatteryLevel(UIDevice.current.batteryLevel)
        }
    }

    private static func storeBatteryLevel(_ level: Float) {
        batteryLock.lock()
        cachedBatteryLevel = level
        batteryLock.unlock()
    }

    /// "0.85", or "unknown" on the simulator and before monitoring starts.
    static var batteryLevelString: String {
        batteryLock.lock()
        let level = cachedBatteryLevel
        batteryLock.unlock()
        return level < 0 ? "unknown" : String(format: "%.2f", level)
    }
}

// MARK: - Screen tracking

/// The current screen: the last view controller that appeared, ignoring
/// UIKit containers. Swizzles `viewDidAppear(_:)` once; also pushed into the
/// crash marker buffer so a signal crash still knows where it happened.
enum ScreenTracker {

    private static let lock = NSLock()
    private static var _currentScreen: String?
    private static var isInstalled = false

    static var currentScreen: String? {
        lock.lock(); defer { lock.unlock() }
        return _currentScreen
    }

    /// Explicit tracking for SwiftUI screens or places the swizzle cannot see.
    static func track(_ screen: String) {
        lock.lock()
        let changed = _currentScreen != screen
        _currentScreen = screen
        lock.unlock()
        guard changed else { return }
        CrashHandler.updateScreen(screen)
        ErrorReporter.shared.breadcrumbs.recordScreen(screen)
    }

    static func install() {
        guard !isInstalled else { return }
        isInstalled = true

        guard let original = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewDidAppear(_:))),
              let swizzled = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.impulseReporting_viewDidAppear(_:))) else {
            return
        }
        method_exchangeImplementations(original, swizzled)
    }

    private static let ignoredPrefixes = ["UINavigationController", "UITabBarController", "UIInputWindowController",
                                          "UIEditingOverlayViewController", "UICompatibilityInputViewController",
                                          "UISystemKeyboardDockController", "UIPredictionViewController",
                                          "UIAlertController", "UIApplicationRotationFollowingController",
                                          "_UI", "UISearchController", "UIPageViewController", "UISplitViewController"]

    static func didAppear(_ controller: UIViewController) {
        let name = String(describing: type(of: controller))
        guard !ignoredPrefixes.contains(where: { name.hasPrefix($0) }) else { return }
        track(name)
    }
}

extension UIViewController {
    @objc fileprivate func impulseReporting_viewDidAppear(_ animated: Bool) {
        // After the exchange this selector holds the original implementation.
        impulseReporting_viewDidAppear(animated)
        ScreenTracker.didAppear(self)
    }
}

// MARK: - HTTP source

/// Called by both network stacks with the outcome of every request. Reports
/// every 5xx, and every transport failure that is not a cancellation while
/// the device is online. Gateway / CDN statuses (502-504, 520-527) and
/// unresolved hosts are OTHER - the backend is down, not the app; everything
/// else is UNHANDLED_ERROR. The /mobile-errors request itself is never
/// reported, so a failing reporter cannot feed itself.
enum NetworkFailureReporter {

    /// 502, 503, 504 and Cloudflare's 520-527: the service or the gateway in front
    /// of it is down. Expected, never a report.
    static func isBackendOutage(_ status: Int) -> Bool {
        (502...504).contains(status) || (520...527).contains(status)
    }

    static func report(request: URLRequest, response: URLResponse?, data: Data?, error: Error?) {
        guard let url = request.url, !url.path.hasSuffix("/" + ErrorReportSender.endpointPath) else { return }

        let method = request.httpMethod ?? "GET"
        let flow = "HTTP \(method) \(url.path)"
        var extra = ["url": url.absoluteString.components(separatedBy: "?").first ?? url.absoluteString]

        if let error {
            let nsError = error as NSError
            guard nsError.domain != NSURLErrorDomain || nsError.code != URLError.cancelled.rawValue,
                  !(error is CancellationError) else { return }
            guard ErrorReporter.shared.isOnline else { return }

            let unresolvedHost = nsError.domain == NSURLErrorDomain
                && (nsError.code == URLError.cannotFindHost.rawValue || nsError.code == URLError.dnsLookupFailed.rawValue)
            extra["errorCode"] = "\(nsError.domain) \(nsError.code)"

            ErrorReporter.shared.report(
                type: unresolvedHost ? .other : .unhandledError,
                message: "\(flow): \(ErrorClassifier.describe(error))",
                stackTrace: nil,
                extra: extra
            )
            return
        }

        guard let status = (response as? HTTPURLResponse)?.statusCode, status >= 500 else { return }

        // A backend or gateway outage (502-504, Cloudflare 520-527) is an expected
        // failure: the rider already sees the 'server unavailable' message and it is
        // a backend fact, not an app bug, so it is not reported - like offline and
        // 401. A 500 and other unexpected statuses are still reported.
        if NetworkFailureReporter.isBackendOutage(status) { return }

        extra["status"] = "\(status)"
        if let body = ReportSanitizer(ownPhone: AppReportContext.phoneNumber).responseBody(data) {
            extra["responseBody"] = body
        }

        ErrorReporter.shared.report(
            type: .unhandledError,
            message: "\(flow): \(status)",
            stackTrace: nil,
            extra: extra
        )
    }
}

// MARK: - Crash handler

/// Catches crashes and leaves a file behind; nothing is sent from a dying
/// process. `ErrorReporter.start()` turns the file into a CRASH report on the
/// next launch.
///
/// Two entry points, because Swift crashes rarely raise an NSException:
///   - NSSetUncaughtExceptionHandler: Objective-C exceptions. Writes a complete
///     report file.
///   - signal handlers (SIGABRT, SIGSEGV, SIGBUS, SIGILL, SIGTRAP, SIGFPE):
///     force unwraps, fatalError, out-of-range, bad memory access. A signal
///     handler may only call async-signal-safe functions, so it writes a raw
///     marker with `write(2)` from buffers prepared at install time; the marker
///     is converted into a report on the next launch.
///
/// Both chain to the previously installed handler / action (Crashlytics).
/// With a debugger attached, lldb stops on the signal before the handler
/// runs: test crashes by launching the app from the home screen.
enum CrashHandler {

    private static let rawMarkerExtension = "crashraw"

    struct ConvertedCrash {
        let message: String
        let stackTrace: String?
        let screen: String?
        let context: ErrorReportContext
        let occurredAt: Int64
        let extra: [String: String]
    }

    static func install(reportsDirectory: URL) {
        try? FileManager.default.createDirectory(at: reportsDirectory, withIntermediateDirectories: true)
        prepareSignalSafeBuffers(reportsDirectory: reportsDirectory)
        installExceptionHandler()
        installSignalHandlers()
    }

    // Uncaught NSException

    private static var previousExceptionHandler: (@convention(c) (NSException) -> Void)?

    private static func installExceptionHandler() {
        previousExceptionHandler = NSGetUncaughtExceptionHandler()

        NSSetUncaughtExceptionHandler { exception in
            // An uncaught exception ends in abort(), which raises SIGABRT; the
            // flag stops the signal handler from filing the same crash twice.
            impulseCrashAlreadyRecorded = 1

            ErrorReporter.shared.writeCrash(
                message: "Crash: Uncaught \(exception.name.rawValue): \(exception.reason ?? "no reason")",
                stackTrace: exception.callStackSymbols.joined(separator: "\n"),
                extra: ["exceptionName": exception.name.rawValue]
            )

            CrashHandler.previousExceptionHandler?(exception)
        }
    }

    // Signals

    static let handledSignals: [Int32] = [SIGABRT, SIGSEGV, SIGBUS, SIGILL, SIGTRAP, SIGFPE]

    private static func installSignalHandlers() {
        // Stack overflows crash with the stack exhausted; without an alternate
        // stack the handler itself could not run.
        let alternateStackSize = 64 * 1024
        var alternateStack = stack_t()
        alternateStack.ss_sp = UnsafeMutableRawPointer.allocate(byteCount: alternateStackSize, alignment: 16)
        alternateStack.ss_size = alternateStackSize
        alternateStack.ss_flags = 0
        sigaltstack(&alternateStack, nil)

        for signal in handledSignals {
            var action = sigaction()
            action.__sigaction_u.__sa_sigaction = impulseCrashSignalHandler
            action.sa_flags = SA_SIGINFO | SA_ONSTACK
            sigemptyset(&action.sa_mask)

            sigaction(signal, &action, &previousSignalActions[Int(signal)])
        }
    }

    // Next launch

    /// Turns raw signal markers from a previous run into CRASH reports.
    static func convertPendingCrashes(in directory: URL, enqueue: (ConvertedCrash) -> Void) {
        let markers = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == rawMarkerExtension } ?? []

        for marker in markers {
            defer { try? FileManager.default.removeItem(at: marker) }

            guard let contents = try? String(contentsOf: marker, encoding: .utf8),
                  let crash = crash(fromRawMarker: contents) else { continue }
            enqueue(crash)
        }
    }

    /// Marker layout, written by `impulseCrashSignalHandler`:
    ///
    ///     key=value lines
    ///     signal=<n>
    ///     time=<epoch seconds>
    ///     ---
    ///     <backtrace_symbols_fd output>
    private static func crash(fromRawMarker contents: String) -> ConvertedCrash? {
        let parts = contents.components(separatedBy: "\n---\n")
        guard let header = parts.first else { return nil }

        var fields: [String: String] = [:]
        for line in header.split(separator: "\n") {
            guard let separator = line.firstIndex(of: "=") else { continue }
            fields[String(line[..<separator])] = String(line[line.index(after: separator)...])
        }

        guard let signalNumber = fields["signal"].flatMap(Int32.init) else { return nil }

        let signalName = String(cString: strsignal(signalNumber))
        let occurredAt = fields["time"].flatMap(Int64.init).map { $0 * 1000 }
            ?? MobileErrorReporterCore.milliseconds(Date())
        let stackTrace = parts.count > 1 ? crashedFrames(parts[1]) : nil

        // Version and build come from the crashed run, not from this launch.
        let current = AppReportContext.current(network: "unknown", breadcrumbs: fields["breadcrumbs"] ?? "")
        var baseExtra = current.baseExtra
        baseExtra["buildNumber"] = fields["build"] ?? baseExtra["buildNumber"]
        baseExtra["sessionId"] = fields["session"] ?? baseExtra["sessionId"]
        baseExtra["network"] = fields["network"] ?? "unknown"

        var extra = ["signal": "\(signalNumber)"]
        if let loadAddress = fields["loadAddress"] {
            // Needed to symbolicate the raw addresses of a stripped release build.
            extra["loadAddress"] = loadAddress
        }

        let context = ErrorReportContext(
            deviceId: current.deviceId,
            deviceModel: current.deviceModel,
            osVersion: fields["os"] ?? current.osVersion,
            appVersion: fields["app"] ?? current.appVersion,
            userId: current.userId,
            baseExtra: baseExtra
        )

        return ConvertedCrash(
            message: "Crash: Signal \(signalNumber) (SIG\(signalAbbreviation(signalNumber))): \(signalName)",
            stackTrace: stackTrace,
            screen: fields["screen"].flatMap { $0.isEmpty ? nil : $0 },
            context: context,
            occurredAt: occurredAt,
            extra: extra
        )
    }

    /// `backtrace` runs inside the handler, so the trace opens with the handler
    /// and the kernel's `_sigtramp`; the crash itself starts right after that.
    private static func crashedFrames(_ trace: String) -> String {
        let lines = trace.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
        guard let trampoline = lines.firstIndex(where: { $0.contains("_sigtramp") }) else {
            return lines.joined(separator: "\n")
        }
        return lines[(trampoline + 1)...].joined(separator: "\n")
    }

    private static func signalAbbreviation(_ signal: Int32) -> String {
        switch signal {
        case SIGABRT: return "ABRT"
        case SIGSEGV: return "SEGV"
        case SIGBUS: return "BUS"
        case SIGILL: return "ILL"
        case SIGTRAP: return "TRAP"
        case SIGFPE: return "FPE"
        default: return "\(signal)"
        }
    }

    // Signal-safe state: everything the handler touches is allocated here, once.

    fileprivate static var markerPath: UnsafeMutablePointer<CChar>?
    fileprivate static var staticHeader: UnsafeMutablePointer<CChar>?
    fileprivate static var staticHeaderLength = 0
    fileprivate static let screenBufferSize = 256
    fileprivate static let screenBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: screenBufferSize)
    fileprivate static let breadcrumbsBufferSize = 1024
    fileprivate static let breadcrumbsBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: breadcrumbsBufferSize)
    fileprivate static let networkBufferSize = 16
    fileprivate static let networkBuffer = UnsafeMutablePointer<CChar>.allocate(capacity: networkBufferSize)
    fileprivate static let previousSignalActions = UnsafeMutablePointer<sigaction>.allocate(capacity: Int(NSIG))
    fileprivate static let maxFrames: Int32 = 128
    fileprivate static let frameBuffer = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: Int(maxFrames))

    private static func prepareSignalSafeBuffers(reportsDirectory: URL) {
        screenBuffer.initialize(repeating: 0, count: screenBufferSize)
        breadcrumbsBuffer.initialize(repeating: 0, count: breadcrumbsBufferSize)
        networkBuffer.initialize(repeating: 0, count: networkBufferSize)
        previousSignalActions.initialize(repeating: sigaction(), count: Int(NSIG))

        // One marker name per launch: a process crashes at most once.
        let name = "\(MobileErrorReporterCore.milliseconds(Date()))-crash.\(rawMarkerExtension)"
        markerPath = strdup(reportsDirectory.appendingPathComponent(name).path)

        let info = Bundle.main.infoDictionary
        var header = ""
        header += "app=\(info?["CFBundleShortVersionString"] as? String ?? "unknown")\n"
        header += "build=\(info?["CFBundleVersion"] as? String ?? "unknown")\n"
        header += "os=\(AppReportContext.osVersionString)\n"
        header += "session=\(ErrorReporter.sessionId)\n"
        header += "loadAddress=\(mainImageLoadAddress())\n"
        staticHeader = strdup(header)
        staticHeaderLength = header.utf8.count

        // Resolving `backtrace` lazily can allocate; do it now, not mid-crash.
        frameBuffer.initialize(repeating: nil, count: Int(maxFrames))
        _ = backtrace(frameBuffer, 1)
    }

    static func updateScreen(_ screen: String) {
        copy(screen, into: screenBuffer, size: screenBufferSize)
    }

    static func updateBreadcrumbs(_ trail: String) {
        copy(trail, into: breadcrumbsBuffer, size: breadcrumbsBufferSize)
    }

    static func updateNetwork(_ kind: String) {
        copy(kind, into: networkBuffer, size: networkBufferSize)
    }

    private static func copy(_ value: String, into buffer: UnsafeMutablePointer<CChar>, size: Int) {
        // Newlines would corrupt the key=value marker.
        let sanitized = value.replacingOccurrences(of: "\n", with: " ")
        _ = sanitized.withCString { strlcpy(buffer, $0, size) }
    }

    private static func mainImageLoadAddress() -> String {
        guard let header = _dyld_get_image_header(0) else { return "unknown" }
        return String(format: "0x%lx", UInt(bitPattern: header))
    }
}

/// Set once a crash has been written, so the SIGABRT that follows an uncaught
/// exception - or a second fault inside the handler - does not write again.
fileprivate var impulseCrashAlreadyRecorded: sig_atomic_t = 0

/// Async-signal-safe: `open`, `write`, `close`, `time`, `strlen`,
/// `backtrace_symbols_fd` and `sigaction` only, on buffers prepared at install.
private func impulseCrashSignalHandler(_ signal: Int32, _ info: UnsafeMutablePointer<__siginfo>?, _ context: UnsafeMutableRawPointer?) {
    if impulseCrashAlreadyRecorded == 0 {
        impulseCrashAlreadyRecorded = 1
        impulseWriteRawCrashMarker(signal: signal)
    }

    // Hand the signal back to whoever had it before (Crashlytics, or the OS
    // default that produces the system crash log) and re-raise it.
    sigaction(signal, &CrashHandler.previousSignalActions[Int(signal)], nil)
    raise(signal)
}

private func impulseWriteRawCrashMarker(signal: Int32) {
    guard let path = CrashHandler.markerPath else { return }

    let fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
    guard fd >= 0 else { return }
    defer { close(fd) }

    if let header = CrashHandler.staticHeader {
        _ = write(fd, header, CrashHandler.staticHeaderLength)
    }

    impulseWriteLiteral(fd, "screen=")
    _ = write(fd, CrashHandler.screenBuffer, strlen(CrashHandler.screenBuffer))
    impulseWriteLiteral(fd, "\nbreadcrumbs=")
    _ = write(fd, CrashHandler.breadcrumbsBuffer, strlen(CrashHandler.breadcrumbsBuffer))
    impulseWriteLiteral(fd, "\nnetwork=")
    _ = write(fd, CrashHandler.networkBuffer, strlen(CrashHandler.networkBuffer))
    impulseWriteLiteral(fd, "\nsignal=")
    impulseWriteDecimal(fd, Int64(signal))
    impulseWriteLiteral(fd, "\ntime=")
    impulseWriteDecimal(fd, Int64(time(nil)))
    impulseWriteLiteral(fd, "\n---\n")

    let count = backtrace(CrashHandler.frameBuffer, CrashHandler.maxFrames)
    backtrace_symbols_fd(CrashHandler.frameBuffer, count, fd)
}

/// `StaticString` literals live in the binary, so writing one allocates nothing.
private func impulseWriteLiteral(_ fd: Int32, _ literal: StaticString) {
    _ = write(fd, literal.utf8Start, literal.utf8CodeUnitCount)
}

/// Formats into a stack buffer - no String, no allocation.
private func impulseWriteDecimal(_ fd: Int32, _ value: Int64) {
    var digits: (CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar,
                 CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar, CChar) =
        (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)

    withUnsafeMutableBytes(of: &digits) { raw in
        let buffer = raw.bindMemory(to: CChar.self)
        var remaining = value < 0 ? -value : value
        var index = buffer.count

        repeat {
            index -= 1
            buffer[index] = CChar(48 + remaining % 10)
            remaining /= 10
        } while remaining > 0 && index > 1

        if value < 0 {
            index -= 1
            buffer[index] = 45 // "-"
        }

        _ = write(fd, buffer.baseAddress! + index, buffer.count - index)
    }
}
