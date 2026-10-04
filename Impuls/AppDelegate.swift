//
//  AppDelegate.swift
//  MimoBike
//
//  Created by Vardan on 09.04.21.
//

import UIKit
import GoogleMaps
import Firebase
import FirebaseCore
import IQKeyboardManagerSwift
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    let sessionNetwork = SessionNetwork()

    /// The current FCM registration token. Home uploads it with
    /// `PUT /api/user/device` on every appearance (cold start, after login) and
    /// again whenever Firebase rotates it (`didReceiveRegistrationToken`).
    var fcmToken: String?

    /// Posted when `fcmToken` changes, so a visible Home re-uploads it.
    static let fcmTokenUpdated = NSNotification.Name("UpdateFCMToken")
    /// Posted when a push tap has been routed; the object is the `PushRoute`.
    /// A running Home opens it at once, otherwise it waits in
    /// `pendingPushRoute` for Home to appear (cold start through the splash,
    /// or a signed-out user who must log in first).
    static let pushRouteReceived = NSNotification.Name("Mimo.Notification.pushRouteReceived")

    private(set) var pendingPushRoute: PushRoute?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        // Saved server texts are used until (and unless) the backend answers.
        LocalizationStore.shared.restoreCached()
        MimoSocketLog.start()
        DeviceCheckManager.shared.sendEphemeralToken()
        GMSServices.provideAPIKey(Constant.APIKeys.GOOGLE_MAPS_API_KEY)
        KeychainManager().resetIfNeed()
        approvalNavigationToolBarAppearance()
        ApplicationSettings.construct()
        MILoader.run(containerView: window)
        
        registerForNotifications(application: application)
        
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.keyboardDistance = 40
        IQKeyboardManager.shared.resignOnTouchOutside = true
        
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    /// Set view controller as root
    func setRootViewController(_ vc: UIViewController) {
        ThemeManager.shared.apply(to: UIApplication.shared.windows.first)
        UIApplication.shared.windows.first?.rootViewController = vc
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    /// Wires Firebase Messaging and asks APNs for a device token. The user is
    /// NOT asked for notification permission here: Home asks, with the brand
    /// rationale, once the rider is signed in (see
    /// `MimoHomeViewController.offerNotificationPermissionIfNeeded`). The APNs
    /// registration and the FCM token do not depend on that permission, so the
    /// token is registered with the backend either way and pushes start the
    /// moment the permission is granted.
    private func registerForNotifications(application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        application.registerForRemoteNotifications()
    }

    // MARK: - Push routing

    /// Parks the route of a tapped push and tells a running Home about it.
    private func hold(pushRoute: PushRoute) {
        pendingPushRoute = pushRoute
        NotificationCenter.default.post(name: AppDelegate.pushRouteReceived, object: pushRoute)
    }

    /// Hands over the parked route once; a second call returns nil.
    func takePendingPushRoute() -> PushRoute? {
        defer { pendingPushRoute = nil }
        return pendingPushRoute
    }

    /// The legacy `action: wallet` marker (and every wallet-domain push) means
    /// the balance changed; the screens that show it re-read it.
    private func refreshBalanceIfNeeded(for payload: PushPayload) {
        guard payload.refreshesBalance, KeychainManager().isUserLoggedIn() else { return }

        let messageService: MessageServiceProtocol = Resolver.resolve()
        messageService.publish(.balanceUpdated)
    }
    
    private func approvalNavigationToolBarAppearance() {
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().tintColor = .mimoDarkGray
        let backImage = UIImage(named: "ic_back")!.withRenderingMode(.alwaysOriginal)
        UINavigationBar.appearance().backIndicatorImage = backImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backImage
        let attributes = [NSAttributedString.Key.font: UIFont(name: "Roboto-Bold", size: 17)!, .foregroundColor: UIColor.mimoDarkGray] as [NSAttributedString.Key : Any]
        UINavigationBar.appearance().titleTextAttributes = attributes
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let urlComponent = URLComponents(url: url, resolvingAgainstBaseURL: true)
        
        let questItem = urlComponent?.queryItems?.first(where: { $0.name == "code" })
        
        guard let code = questItem?.value else {
            let isIdram =  urlComponent?.path.contains("idram") ?? false
            
            if !isIdram {
                UIAlertController.showError(message: "Could not perform email verification")
            }
            
            return true
        }
        
        sessionNetwork.request(with: URLBuilder(from: AuthAPI.emailVerification(code: code))) { result in
            switch result {
            case .success:
                NotificationCenter.default.post(name: Constant.Notifications.accountVerified, object: nil)
                debugPrint("success verify")
            case .failure(_):
                UIAlertController.showError(message: "Could not perform email verification")
            }
        }
        
        return true
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    /// The first token and every rotation. The backend drops a token FCM
    /// rejects as UNREGISTERED and never restores it, so each new token has to
    /// reach `PUT /api/user/device` (accounts docs/push-notifications.md,
    /// "Token lifecycle (mobile)").
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.fcmToken = fcmToken
        NotificationCenter.default.post(name: AppDelegate.fcmTokenUpdated, object: nil)
    }

    /// A push while the app is in the foreground is shown as a banner (and
    /// kept in the list); its tap arrives in `didReceive` like any other.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        refreshBalanceIfNeeded(for: PushPayload(userInfo: notification.request.content.userInfo))

        completionHandler([.list, .banner, .badge, .sound])
    }

    /// A tap on a system push - app killed, in the background or open - goes
    /// through the one router keyed on the payload `type` (accounts
    /// docs/push-notifications.md, "Routing table"); an unknown type opens the
    /// notification list.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let payload = PushPayload(userInfo: response.notification.request.content.userInfo)

        refreshBalanceIfNeeded(for: payload)
        hold(pushRoute: PushRouter.route(for: payload))

        completionHandler()
    }
}
