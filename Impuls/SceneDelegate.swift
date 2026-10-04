//
//  SceneDelegate.swift
//  MimoBike
//
//  Created by Razmik Mkhitaryan on 25.09.23.
//

import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?


    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        ThemeManager.shared.apply(to: window)
        window.rootViewController = UIHostingController(rootView: SplashView())
        window.makeKeyAndVisible()
        
        self.window = window
        
        MILoader.run(containerView: window)
        
        // A link that cold-starts the app arrives here, not in `scene(_:continue:)`
        // or `scene(_:openURLContexts:)`. Nothing is on screen yet, so the handler
        // only parks what it finds (a station code waits for Home).
        if let url = connectionOptions.userActivities.first(where: { $0.activityType == NSUserActivityTypeBrowsingWeb })?.webpageURL {
            handle(url: url)
        } else if let context = connectionOptions.urlContexts.first {
            handle(url: context.url)
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let context = URLContexts.first else { return }
        handle(url: context.url)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return }
        handle(url: url)
    }

    private func handle(url: URL) {
        let urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: true)

        if urlComponent?.queryItems?.first(where: { $0.name == "view" && $0.value == "email_verification"}) != nil {
            guard let code = urlComponent?.queryItems?.first(where: { $0.name == "code" })?.value else { return }

            NotificationCenter.default.post(name: Constant.Notifications.emailVerificationCode, object: code)
            return
        }

        if urlComponent?.path.contains("ameriatransactionstate") == true {
            let queryItems = urlComponent?.queryItems ?? []
            var payload: [String: String] = [:]
            for item in queryItems {
                payload[item.name] = item.value
            }
            NotificationCenter.default.post(name: Constant.Notifications.paymentCallback, object: payload)
            return
        }

        if let code = SceneDelegate.stationCode(from: url) {
            // A rider who is not signed in lands on the welcome screen; the
            // station is not remembered across the login.
            guard KeychainManager().isUserLoggedIn() else { return }
            HomeRouter.shared.holdStationLink(code: code)
            return
        }

        // Any other link is not ours to act on.
    }

    // MARK: - Station App Link

    /// The hosts that serve the station stickers' links; both are associated
    /// domains of the app (applinks: in the entitlements).
    private static let stationLinkHosts: Set<String> = ["accounts.impulsepower.ru", "impulsepower.ru"]

    /// Parses `https://accounts.impulsepower.ru/scan/{code}` (a trailing slash
    /// is ignored) and the same path on the app's own URL schemes
    /// (`mimo://scan/{code}`, `mimo:///scan/{code}`). Returns the code, or nil
    /// for any other link. The code itself is validated by `HomeRouter`.
    static func stationCode(from url: URL) -> String? {
        guard let scheme = url.scheme?.lowercased() else { return nil }

        var segments: [String]
        if scheme == "https" || scheme == "http" {
            guard scheme == "https", let host = url.host?.lowercased(), stationLinkHosts.contains(host) else { return nil }
            segments = url.pathComponents.filter { $0 != "/" }
        } else {
            // On a custom scheme the first segment is parsed as the host.
            segments = url.pathComponents.filter { $0 != "/" }
            if let host = url.host, !host.isEmpty {
                segments.insert(host, at: 0)
            }
        }

        guard segments.count == 2, segments[0].lowercased() == "scan" else { return nil }
        let code = segments[1].trimmingCharacters(in: .whitespacesAndNewlines)
        return code.isEmpty ? nil : code
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

    func set(rootView: some View) {
        window?.rootViewController = UIHostingController(rootView: rootView)
        window?.makeKeyAndVisible()
        
        MILoader.run(containerView: window)
    }
    
    func set(rootViewController: UIViewController?) {
        window?.rootViewController = rootViewController
        window?.makeKeyAndVisible()
        
        MILoader.run(containerView: window)
    }
}

