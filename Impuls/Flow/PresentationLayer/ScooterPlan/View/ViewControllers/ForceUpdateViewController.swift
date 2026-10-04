//
//  ForceUpdateViewController.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 30.09.22.
//

import UIKit

/// The blocking update wall ("Hi, friend", MOBILE_force_update_description,
/// MOBILE_update_app). Home presents it full screen when the backend names a
/// version above the installed one (`MimoHomeWorker.checkAppVersion`). There
/// is deliberately no way out other than the store button: no swipe-down, no
/// back button, no close control.
class ForceUpdateViewController: UIViewController, StoryboardInitializable {

    @IBOutlet weak var updateButton: UILocalizedButton!

    /// The bundle id of the published Impulse app. A dev build runs under
    /// another bundle id that is not on the store, so the lookup falls back
    /// to this one. Never a hard-coded store id: the page is always derived
    /// from the lookup answer for the Impulse bundle.
    private static let publishedBundleIdentifier = "com.impulsepower.app"

    private var storeURL: URL?
    private var lookupTask: URLSessionDataTask?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Not dismissable: the sheet cannot be pulled down and, when a legacy
        // caller wraps the wall in a navigation controller, there is no back.
        isModalInPresentation = true
        navigationItem.hidesBackButton = true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false

        updateButton.layer.cornerRadius = updateButton.frame.height / 2

        // Resolve the store page up front so the tap opens it at once.
        resolveStoreURL { [weak self] url in
            self?.storeURL = url
        }
    }

    @IBAction func updateAction(_ sender: UILocalizedButton) {
        if let storeURL {
            open(storeURL)
            return
        }

        sender.isEnabled = false
        resolveStoreURL { [weak self] url in
            sender.isEnabled = true
            self?.storeURL = url
            self?.open(url ?? Self.searchFallbackURL)
        }
    }

    private func open(_ url: URL) {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

    // MARK: - Store page

    /// This app's App Store page, taken from
    /// `https://itunes.apple.com/lookup?bundleId=...` (`results[0].trackViewUrl`,
    /// or `trackId` when the URL is missing). The running bundle id is asked
    /// first, then the published Impulse one. `nil` when neither answers.
    private func resolveStoreURL(completion: @escaping (URL?) -> Void) {
        guard lookupTask == nil else {
            // A lookup is in flight; the button handler re-asks when it ends.
            return
        }

        var candidates: [String] = []
        if let running = Bundle.main.bundleIdentifier, !running.isEmpty {
            candidates.append(running)
        }
        if !candidates.contains(Self.publishedBundleIdentifier) {
            candidates.append(Self.publishedBundleIdentifier)
        }

        lookup(bundleIdentifiers: candidates) { [weak self] url in
            DispatchQueue.main.async {
                self?.lookupTask = nil
                completion(url)
            }
        }
    }

    private func lookup(bundleIdentifiers: [String], completion: @escaping (URL?) -> Void) {
        guard let bundleIdentifier = bundleIdentifiers.first else {
            completion(nil)
            return
        }
        let rest = Array(bundleIdentifiers.dropFirst())

        guard var components = URLComponents(string: "https://itunes.apple.com/lookup") else {
            completion(nil)
            return
        }
        components.queryItems = [URLQueryItem(name: "bundleId", value: bundleIdentifier)]
        guard let url = components.url else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.cachePolicy = .reloadIgnoringLocalCacheData

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            if let data, let storeURL = Self.storeURL(fromLookup: data) {
                completion(storeURL)
            } else if let self, !rest.isEmpty {
                self.lookup(bundleIdentifiers: rest, completion: completion)
            } else {
                completion(nil)
            }
        }
        lookupTask = task
        task.resume()
    }

    /// `results[0].trackViewUrl`, else `https://apps.apple.com/app/id{trackId}`.
    private static func storeURL(fromLookup data: Data) -> URL? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = (json["results"] as? [[String: Any]])?.first else {
            return nil
        }
        if let trackViewUrl = result["trackViewUrl"] as? String, let url = URL(string: trackViewUrl) {
            return url
        }
        if let trackId = result["trackId"] {
            return URL(string: "https://apps.apple.com/app/id\(trackId)")
        }
        return nil
    }

    /// Last resort when the lookup is unreachable: the App Store search for
    /// this app's name, so the rider still lands in the store.
    private static var searchFallbackURL: URL {
        let name = (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (Bundle.main.infoDictionary?["CFBundleName"] as? String)
            ?? "Impulse"
        var components = URLComponents(string: "https://apps.apple.com/search")!
        components.queryItems = [URLQueryItem(name: "term", value: name)]
        return components.url!
    }
}
