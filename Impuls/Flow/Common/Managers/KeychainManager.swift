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
    
    /// Save refresh token in keychain. Only a JWT is ever written: the accounts
    /// service issues nothing else (docs/authentication.md: `refresh_token` is
    /// an HS512 JWT), and a value that is not one can only be garbage that
    /// would make every refresh fail.
    func saveRefreshToken(token: String) {
        guard Self.isRefreshTokenJWT(token) else {
            ErrorReporter.shared.reportAbnormalBehavior(
                "Refresh token to store is not a JWT; not saved",
                action: "saveRefreshToken"
            )
            return
        }
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
    
    /// Check user token.
    ///
    /// An expired access token still counts as signed in while a refresh
    /// token is stored: the first request answered with 401 renews the pair
    /// through POST /account/refresh-token (see SessionNetwork). Without a
    /// refresh token the legacy rule applies and the user signs in again.
    func isUserLoggedIn() -> Bool {
        guard keychain[accessTokenKey] != nil else { return false }
        return !isTokenExpired() || getRefreshToken() != nil
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
    
    /// Get refresh token from keychain.
    ///
    /// Only a JWT counts. Mimo iOS builds between 2023-06 and 2024-02 stored the
    /// access token's expiry stamp (a digits-only number) under this key, and
    /// the keychain survives reinstalls; Impulse never shipped that bug, but
    /// the same rule protects it from any other stale value under the key.
    /// Sending such a value can only fail (the server answers the 401
    /// envelope), so it is dropped and the rider is treated as having no
    /// refresh token: the next 401 ends the session once (after the
    /// /account/start fallback) and a new sign-in stores a real token.
    func getRefreshToken() -> String? {
        guard let token = try? keychain.getString(refreshTokenKey), !token.isEmpty else { return nil }
        guard Self.isRefreshTokenJWT(token) else {
            try? keychain.remove(refreshTokenKey)
            ErrorReporter.shared.reportAbnormalBehavior(
                "Stored refresh token is not a JWT; discarded",
                action: "getRefreshToken",
                extra: ["length": "\(token.count)", "digitsOnly": token.allSatisfy(\.isNumber) ? "true" : "false"]
            )
            return nil
        }
        return token
    }

    // MARK: - JWT

    /// Whether `token` has the shape of a refresh token the accounts service
    /// issues: three non-empty base64url parts whose payload is a JSON object
    /// with a numeric `exp`. Nothing is verified - the server does that - the
    /// app only refuses to store or send a value that cannot be a token.
    static func isRefreshTokenJWT(_ token: String) -> Bool {
        expiry(ofJWT: token) != nil
    }

    /// `exp` of a JWT (seconds since 1970), read from its payload without
    /// verifying it. Nil when the value is not a three-part JWT, its payload is
    /// not a JSON object, or that object has no numeric `exp`.
    static func expiry(ofJWT token: String) -> Date? {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3, parts.allSatisfy({ !$0.isEmpty }) else { return nil }

        var payload = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while payload.count % 4 != 0 { payload += "=" }

        guard let data = Data(base64Encoded: payload),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval else { return nil }

        return Date(timeIntervalSince1970: exp)
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
    
    /// Store a `JwtToken` pair (`access_token`, `refresh_token`, `expires_in`)
    /// as returned by POST /account/start, /account/verify-device and
    /// /account/refresh-token. A missing refresh token, or one that is not a
    /// JWT, keeps the stored one; nothing but a JWT is ever written under the key.
    func parse(from content: UserToken) {
        self.saveToken(token: content.token?.accessToken ?? "")
        if let refreshToken = content.token?.refreshToken, !refreshToken.isEmpty {
            // `saveRefreshToken` refuses (and reports) anything that is not a JWT.
            self.saveRefreshToken(token: refreshToken)
        }
        self.saveExpireIn(expiresIn: content.token?.expiresIn ?? 0)
    }
}
