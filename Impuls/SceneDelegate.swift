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
        window.rootViewController = UIHostingController(rootView: SplashView())
        window.makeKeyAndVisible()
        
        self.window = window
        
        MILoader.run(containerView: window)
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
        }
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

