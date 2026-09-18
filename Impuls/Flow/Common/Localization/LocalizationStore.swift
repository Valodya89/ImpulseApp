//
//  LocalizationStore.swift
//  Impuls
//
//  Keeps the server translations on disk so the app has texts without a
//  network: the cached dictionary is applied at launch, the backend copy is
//  fetched in the background and merged in when (and if) it arrives.
//

import Foundation
import Combine

final class LocalizationStore {
    
    static let shared = LocalizationStore()
    
    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "ru.impulsepower.localization-store", qos: .utility)
    /// The in-flight background refresh. Kept here, not in the splash worker,
    /// which is released as soon as the splash screen is gone.
    private var refresh: AnyCancellable?
    
    private init() { }
    
    // MARK: - Current language
    
    var currentLanguageCode: String {
        StorageManager().fetch(key: .language, type: String.self) ?? Locale.current.deviceLanguageCode
    }
    
    // MARK: - Disk
    
    /// The last dictionary saved for the language, or nil when none was saved yet.
    func load(languageCode: String) -> [String: String]? {
        guard let url = fileURL(for: languageCode),
              let data = try? Data(contentsOf: url),
              let dictionary = try? JSONDecoder().decode([String: String].self, from: data),
              !dictionary.isEmpty
        else { return nil }
        return dictionary
    }
    
    /// Saves atomically off the main thread. An empty dictionary is never
    /// written: it would only replace good texts with nothing.
    func save(_ dictionary: [String: String], languageCode: String) {
        guard !dictionary.isEmpty else { return }
        queue.async {
            guard let url = self.fileURL(for: languageCode),
                  let data = try? JSONEncoder().encode(dictionary) else { return }
            try? self.fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: url, options: .atomic)
        }
    }
    
    // MARK: - In memory
    
    /// Makes the dictionary the one every `localized()` call reads and tells
    /// the localized labels/buttons to redraw.
    func apply(_ dictionary: [String: String]) {
        guard !dictionary.isEmpty else { return }
        let post = {
            Mimo.Localization.localizations = dictionary
            NotificationCenter.default.post(name: Constant.Notifications.TranslationsUpdate, object: nil)
        }
        if Thread.isMainThread { post() } else { DispatchQueue.main.async(execute: post) }
    }
    
    /// Loads the saved texts of the current language into memory. Call once at
    /// launch so nothing is shown as a raw key before the backend answers.
    func restoreCached() {
        guard let cached = load(languageCode: currentLanguageCode) else { return }
        Mimo.Localization.localizations = cached
    }
    
    /// Backend texts win; keys the backend did not return (a module that
    /// failed, a slow link that timed out) keep their cached value, so a
    /// partial answer never blanks the UI.
    func merge(fetched: [String: String], into cached: [String: String]?) -> [String: String] {
        var merged = cached ?? [:]
        fetched.forEach { merged[$0.key] = $0.value }
        return merged
    }
    
    /// Merges, saves and applies a backend answer for the language.
    /// Returns the dictionary now in use.
    @discardableResult
    func store(fetched: [String: String], languageCode: String) -> [String: String] {
        let merged = merge(fetched: fetched, into: load(languageCode: languageCode))
        guard !merged.isEmpty else { return merged }
        save(merged, languageCode: languageCode)
        // A refresh that lands after the rider switched language must not
        // overwrite the texts of the language now on screen.
        if languageCode == currentLanguageCode {
            apply(merged)
        }
        return merged
    }
    
    /// Runs a backend refresh to completion regardless of who started it.
    func runInBackground(_ publisher: AnyPublisher<[String: String], Never>) {
        refresh = publisher.sink { _ in }
    }
    
    // MARK: - Private
    
    private func fileURL(for languageCode: String) -> URL? {
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let safe = languageCode.replacingOccurrences(of: "/", with: "_")
        return base.appendingPathComponent("Localization", isDirectory: true)
            .appendingPathComponent("translations-\(safe).json")
    }
}
