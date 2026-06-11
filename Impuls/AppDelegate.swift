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
    var isOpenedWithPushNotification = false
    var fcmToken: String?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        DeviceCheckManager.shared.sendEphemeralToken()
        GMSServices.provideAPIKey(Constant.APIKeys.GOOGLE_MAPS_API_KEY)
        KeychainManager().resetIfNeed()
        approvalNavigationToolBarAppearance()
        ApplicationSettings.construct()
        MILoader.run(containerView: window)
        
        registerForNotifications(application: application)
        
        if Reachability.isConnectedToNetwork(){
            print("Internet Connection Available!")
        } else {
            print("Internet Connection not Available!")
            let splashVC = NoInternetConnectionViewController()
            setRootViewController(splashVC)
        }
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
        UIApplication.shared.windows.first?.rootViewController = vc
        UIApplication.shared.windows.first?.makeKeyAndVisible()
    }
    
    private func registerForNotifications(application: UIApplication) {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: { _, _ in }
        )
        
        application.registerForRemoteNotifications()
    }
    
    private func approvalNavigationToolBarAppearance() {
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().tintColor = #colorLiteral(red: 0.2078431373, green: 0.2078431373, blue: 0.2078431373, alpha: 1)
        let backImage = UIImage(named: "ic_back")!.withRenderingMode(.alwaysOriginal)
        UINavigationBar.appearance().backIndicatorImage = backImage
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backImage
        let attributes = [NSAttributedString.Key.font: UIFont(name: "Roboto-Bold", size: 17)!, .foregroundColor: #colorLiteral(red: 0.2078431373, green: 0.2078431373, blue: 0.2078431373, alpha: 1)] as [NSAttributedString.Key : Any]
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
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        self.fcmToken = fcmToken
        NotificationCenter.default.post(name: NSNotification.Name("UpdateFCMToken"), object: nil)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let application = UIApplication.shared
        
        if application.applicationState == .inactive {
            isOpenedWithPushNotification = true
        }
        
        completionHandler()
    }
}
