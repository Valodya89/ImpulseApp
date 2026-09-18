//
//  MimoSocketLog.swift
//  Impuls
//
//  One place every STOMP socket (scooter, bike, power bank, EV) reports its
//  lifecycle to, so an unexpected close can be read back in order: when the
//  app asked to connect, when the socket came up, when and why it went down,
//  and what the app was doing at that moment (foreground / background).
//
//  Where the lines go:
//  - Xcode console (`print`) and the unified log (Console.app, subsystem = the
//    bundle id, category "socket"). SwiftStomp's own lines (close code, reason,
//    reconnect scheduler) are next to them under "SwiftStomp".
//  - `Documents/socket.log` inside the app container, so a run without Xcode
//    attached can still be read back (Xcode > Devices > Download Container).
//

import Foundation
import OSLog
import UIKit

enum MimoSocketLog {

    /// Which socket a line belongs to.
    enum Socket: String {
        case scooter = "SCOOTER"
        case bike = "BIKE"
        case charger = "POWERBANK"
        case evCharger = "EV"
    }

    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "Impuls", category: "socket")
    private static let queue = DispatchQueue(label: "impuls.socket.log", qos: .utility)
    private static let maxFileBytes = 512 * 1024

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter
    }()

    private static let fileURL: URL? = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("socket.log")
    }()

    /// Last known app state, kept here because socket callbacks arrive off the
    /// main thread where `UIApplication.applicationState` must not be read.
    private static var appState = "launching"
    private static var observers: [NSObjectProtocol] = []

    /// Call once at launch: records foreground / background transitions, which
    /// is what an "automatic" close usually lines up with (iOS suspends the
    /// app's sockets shortly after it goes to the background).
    static func start() {
        guard observers.isEmpty else { return }

        let center = NotificationCenter.default
        let transitions: [(Notification.Name, String)] = [
            (UIApplication.didFinishLaunchingNotification, "active"),
            (UIApplication.didBecomeActiveNotification, "active"),
            (UIApplication.willResignActiveNotification, "inactive"),
            (UIApplication.didEnterBackgroundNotification, "background"),
            (UIApplication.willEnterForegroundNotification, "foreground (inactive)"),
            (UIApplication.willTerminateNotification, "terminating")
        ]
        for (name, state) in transitions {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { _ in
                appState = state
                write(level: .default, "[APP] \(name.rawValue.replacingOccurrences(of: "UIApplication", with: ""))")
            })
        }

        DispatchQueue.main.async {
            appState = describe(UIApplication.shared.applicationState)
        }
        write(level: .default, "[APP] socket log started · file: \(fileURL?.path ?? "-")")
    }

    static func info(_ socket: Socket, _ event: String, _ details: String? = nil) {
        write(level: .default, line(socket, event, details))
    }

    static func error(_ socket: Socket, _ event: String, _ details: String? = nil) {
        write(level: .error, line(socket, event, details))
    }

    /// "312s" since `date`, or "-" when the socket was never up.
    static func age(since date: Date?) -> String {
        guard let date else { return "-" }
        return "\(Int(Date().timeIntervalSince(date)))s"
    }

    /// A STOMP destination is the rider's phone number; only its tail is logged.
    static func masked(_ destination: String?) -> String {
        guard let destination, !destination.isEmpty else { return "-" }
        return "…" + destination.suffix(4)
    }

    // MARK: - Private

    private static func line(_ socket: Socket, _ event: String, _ details: String?) -> String {
        var text = "[SOCKET][\(socket.rawValue)] \(event)"
        if let details, !details.isEmpty {
            text += " · \(details)"
        }
        return text + " · app=\(appState)"
    }

    private static func describe(_ state: UIApplication.State) -> String {
        switch state {
        case .active: return "active"
        case .inactive: return "inactive"
        case .background: return "background"
        @unknown default: return "unknown"
        }
    }

    private static func write(level: OSLogType, _ text: String) {
        let stamped = "\(formatter.string(from: Date())) \(text)"
        print(stamped)
        logger.log(level: level, "\(text, privacy: .public)")

        queue.async {
            append(stamped + "\n")
        }
    }

    private static func append(_ text: String) {
        guard let fileURL, let data = text.data(using: .utf8) else { return }

        let manager = FileManager.default
        if let size = (try? manager.attributesOfItem(atPath: fileURL.path)[.size] as? NSNumber)?.intValue,
           size > maxFileBytes {
            // Keep the file readable: drop the oldest half once it grows past the cap.
            if let old = try? Data(contentsOf: fileURL) {
                try? old.suffix(maxFileBytes / 2).write(to: fileURL)
            }
        }

        if let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { try? handle.close() }
            _ = try? handle.seekToEnd()
            try? handle.write(contentsOf: data)
        } else {
            try? data.write(to: fileURL)
        }
    }
}
