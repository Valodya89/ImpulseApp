//
//  ThemeManager.swift
//  Impuls
//
//  Stores the user's appearance preference (system / light / dark) and
//  applies it to every window so both UIKit and SwiftUI screens follow it.
//

import UIKit
import SwiftUI
import Combine

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark
    
    /// Order used by pickers (segmented control, SwiftUI lists).
    static var ordered: [AppTheme] { [.system, .light, .dark] }
    
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    /// Server-driven title with an English fallback so a bare key never reaches the screen.
    var title: String {
        switch self {
        case .system: return "MOBILE_settings_theme_system".localized(fallback: "System")
        case .light: return "MOBILE_settings_theme_light".localized(fallback: "Light")
        case .dark: return "MOBILE_settings_theme_dark".localized(fallback: "Dark")
        }
    }
}

final class ThemeManager: ObservableObject {
    
    static let shared = ThemeManager()
    
    @Published private(set) var theme: AppTheme
    
    private let storageManager = StorageManager()
    
    private init() {
        let stored = storageManager.fetch(key: .appTheme, type: String.self) ?? ""
        theme = AppTheme(rawValue: stored) ?? .system
    }
    
    /// Whether the interface currently resolves to dark (respects the "system" option).
    var isDarkModeActive: Bool {
        switch theme {
        case .dark: return true
        case .light: return false
        case .system:
            return UITraitCollection.current.userInterfaceStyle == .dark
                || ThemeManager.keyWindow?.traitCollection.userInterfaceStyle == .dark
        }
    }
    
    /// The style every window should be forced to (`.unspecified` follows the device).
    var interfaceStyle: UIUserInterfaceStyle { theme.interfaceStyle }
    
    func set(_ newTheme: AppTheme, animated: Bool = true) {
        guard newTheme != theme else { return }
        theme = newTheme
        storageManager.store(newTheme.rawValue, key: .appTheme)
        applyToAllWindows(animated: animated)
        NotificationCenter.default.post(name: Constant.Notifications.ThemeUpdate, object: newTheme)
    }
    
    /// Applies the stored preference to a single window (call right after creating it).
    func apply(to window: UIWindow?) {
        window?.overrideUserInterfaceStyle = theme.interfaceStyle
    }
    
    /// Applies the stored preference to every window of every connected scene.
    func applyToAllWindows(animated: Bool = false) {
        let windows = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
        
        let update = { windows.forEach { self.apply(to: $0) } }
        
        if animated, let window = windows.first {
            UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: update)
        } else {
            update()
        }
    }
    
    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }
}

// MARK: - SwiftUI helper

/// Injects the theme manager and forces the chosen color scheme on a SwiftUI hierarchy
/// that is not hosted inside one of the app windows (previews, standalone hosting).
struct ThemedView<Content: View>: View {
    @ObservedObject private var themeManager = ThemeManager.shared
    private let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .preferredColorScheme(themeManager.theme.colorScheme)
            .environmentObject(themeManager)
    }
}
