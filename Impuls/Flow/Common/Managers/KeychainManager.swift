//
//  KeychainManager.swift
//  MimoBike
//
//  Created by Albert on 14.05.21.
//

import Foundation
import KeychainAccess

protocol UserToken {
    var user: UserResponse? { get }
    var token: TokenResponse? { get}
}

final class KeychainManager {
    
    let keychain = Keychain(service: "com.mimo.MimoBike")
    let accessTokenKey = "AccessToken"
    let refreshTokenKey = "RefreshToken"
    let expiresInKey = "ExpiresIn"

    
    // MARK: - Functions
    
    /// Save token in keychain
    func saveToken(token: String) {
        do {
            try keychain.set(token, key: accessTokenKey)
        } catch let error {
            print(error)
        }
    }
    
    /// Save refresh token in keychain
    func saveRefreshToken(token: String) {
        do {
            try keychain.set(token, key: refreshTokenKey)
        } catch let error {
            print(error)
        }
    }
    
    /// Save expires In in keychain
    func saveExpireIn(expiresIn: Double) {
        do {
            let willExpireIn = Date().timeIntervalSince1970 + expiresIn
            try keychain.set(String(format: "%.0f", willExpireIn), key: expiresInKey)
        } catch let error {
            print(error)
        }
    }
    
    /// Check user token
    func isUserLoggedIn() -> Bool {
        return keychain[accessTokenKey] != nil && !isTokenExpired()
    }
    
    /// Check user token
    func isTokenExpired() -> Bool {
        guard let expiresInString = keychain[expiresInKey],
              let expiresIn = Double(expiresInString) else { return true }
        return expiresIn < Date().timeIntervalSince1970
    }
    
    /// Get token from keychain
    func getAccessToken() -> String? {
        let token = try? keychain.getString(accessTokenKey)
        return token
    }
    
    /// Get refresh token from keychain
    func getRefreshToken() -> String? {
//        let token = try? keychain.getString(refreshTokenKey)
//        return token
        
        return nil
    }
    
    /// Delete token from keychain
    func removeData() {
        do {
            try keychain.removeAll()
        } catch let error {
            debugPrint("Error: \(error)")
        }
    }
    
    /// Remove all keychain data when run first time
    func resetIfNeed() {
        if !UserDefaults.standard.bool(forKey: "hasRunBefore") {
            // Remove Keychain items here
            do {
                try keychain.removeAll()
            } catch let error {
                debugPrint("Error: \(error)")
            }
            
            // Update the flag indicator
            UserDefaults.standard.set(true, forKey: "hasRunBefore")
        }
    }
    
    func parse(from content: UserToken) {
        self.saveToken(token: content.token?.accessToken ?? "")
//        self.saveRefreshToken(token: content.token?.refreshToken ?? "")
        self.saveExpireIn(expiresIn: content.token?.expiresIn ?? 0)
    }
}
