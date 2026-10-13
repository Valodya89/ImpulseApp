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
    /// The in-flight background refreshes (the current language, English).
    /// Kept here, not in the splash worker, which is released as soon as the
    /// splash screen is gone.
    private var refreshes: [UUID: AnyCancellable] = [:]
    private let lock = NSLock()
    /// The saved dictionaries read so far, by language code; `nil` records
    /// that nothing is saved for the code, so a key lookup that misses never
    /// hits the disk twice. Guarded by `lock`.
    private var loaded: [String: [String: String]?] = [:]
    /// The codes with a file on disk, listed once. Guarded by `lock`.
    private var codesOnDisk: [String]?
    
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
    
    /// Every language code with a saved dictionary ("ru", "en", "en-US", ...).
    /// The directory is listed once; a `save` adds its code.
    func cachedLanguageCodes() -> [String] {
        lock.lock()
        if let codes = codesOnDisk {
            lock.unlock()
            return codes
        }
        lock.unlock()
        var codes: [String] = []
        if let directory = directoryURL,
           let names = try? fileManager.contentsOfDirectory(atPath: directory.path) {
            codes = names.compactMap { name -> String? in
                guard name.hasPrefix(Self.filePrefix), name.hasSuffix(Self.fileSuffix) else { return nil }
                let code = name.dropFirst(Self.filePrefix.count).dropLast(Self.fileSuffix.count)
                return code.isEmpty ? nil : String(code)
            }
        }
        lock.lock()
        if codesOnDisk == nil { codesOnDisk = codes }
        let result = codesOnDisk ?? codes
        lock.unlock()
        return result
    }
    
    /// `load(languageCode:)` read once and kept in memory, so a key that the
    /// in-memory table does not have (`localized()` miss) can be looked up in
    /// the saved texts without touching the disk on every call. A `save` for
    /// the code refreshes the copy.
    func cachedDictionary(languageCode: String) -> [String: String]? {
        lock.lock()
        if let known = loaded[languageCode] {
            lock.unlock()
            return known
        }
        lock.unlock()
        let dictionary = load(languageCode: languageCode)
        lock.lock()
        loaded[languageCode] = .some(dictionary)
        lock.unlock()
        return dictionary
    }
    
    /// The saved dictionaries a key may fall back to for the language, by
    /// code: the language itself with any region ("ru", "ru-RU") and English
    /// ("en", "en-US"). `String.servedText` orders them. Other languages'
    /// files are left on disk unread.
    func fallbackDictionaries(for languageCode: String) -> [String: [String: String]] {
        let wanted = Set([Self.primaryLanguage(of: languageCode), "en"])
        let codes = Set(cachedLanguageCodes() + [languageCode, "en"])
            .filter { wanted.contains(Self.primaryLanguage(of: $0)) }
        var result: [String: [String: String]] = [:]
        for code in codes {
            if let dictionary = cachedDictionary(languageCode: code) {
                result[code] = dictionary
            }
        }
        return result
    }
    
    /// The text saved on disk for a key the in-memory table does not have:
    /// the current language (any region), then English. Nil when no saved
    /// dictionary serves the key. This is the offline/other-language part of
    /// `String.localized()` and of the backend message resolver.
    func servedFallback(for key: String) -> String? {
        let language = currentLanguageCode
        return String.servedText(for: key,
                                 dictionary: [:],
                                 cached: fallbackDictionaries(for: language),
                                 language: language)
    }
    
    /// "ru" for "ru", "ru-RU" or "ru_RU".
    static func primaryLanguage(of code: String) -> String {
        let separators = CharacterSet(charactersIn: "-_")
        let primary = code.components(separatedBy: separators).first ?? code
        return primary.lowercased()
    }
    
    /// Saves atomically off the main thread. An empty dictionary is never
    /// written: it would only replace good texts with nothing.
    func save(_ dictionary: [String: String], languageCode: String) {
        guard !dictionary.isEmpty else { return }
        lock.lock()
        loaded[languageCode] = .some(dictionary)
        if var codes = codesOnDisk, !codes.contains(languageCode) {
            codes.append(languageCode)
            codesOnDisk = codes
        }
        lock.unlock()
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
    /// Several may run at once (the current language and English).
    func runInBackground(_ publisher: AnyPublisher<[String: String], Never>) {
        let id = UUID()
        // Registered before subscribing: a publisher that completes at once
        // (`Just`) removes the entry synchronously, and then nothing is kept.
        lock.lock()
        refreshes[id] = AnyCancellable { }
        lock.unlock()
        let cancellable = publisher.sink(receiveCompletion: { [weak self] _ in
            guard let self else { return }
            self.lock.lock()
            self.refreshes[id] = nil
            self.lock.unlock()
        }, receiveValue: { _ in })
        lock.lock()
        if refreshes[id] != nil { refreshes[id] = cancellable }
        lock.unlock()
    }
    
    // MARK: - Private
    
    private static let filePrefix = "translations-"
    private static let fileSuffix = ".json"
    
    private var directoryURL: URL? {
        fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Localization", isDirectory: true)
    }
    
    private func fileURL(for languageCode: String) -> URL? {
        let safe = languageCode.replacingOccurrences(of: "/", with: "_")
        return directoryURL?.appendingPathComponent(Self.filePrefix + safe + Self.fileSuffix)
    }
}
