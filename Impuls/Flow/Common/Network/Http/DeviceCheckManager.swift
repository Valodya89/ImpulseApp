//
//  DeviceCheckManager.swift
//  MimoBike
//
//  Created by Valodya Galstyan on 04.09.22.
//

import Foundation
import  DeviceCheck

class DeviceCheckManager {
    
    static let shared = DeviceCheckManager()
    
    var deviceUnicToken = ""
    func sendEphemeralToken(){
            //check if DCDevice is available (iOS 11)

           
            //send **ephemeral** token to server to
            self.deviceUnicToken = checkAndSaveValueInKeychain()
                print("deviceUnicToken = \(self.deviceUnicToken)")
    }
    
    func checkAndSaveValueInKeychain() -> String {
        
        if let data = KeychainHelper.standard.read(service: "access-token", account: "Service") {
            let accessToken = String(data: data, encoding: .utf8)
            return accessToken ?? ""
            
        } else {
            let newAccessToken = UIDevice.current.identifierForVendor?.uuidString ?? ""
            
            let data = Data(newAccessToken.utf8)
            KeychainHelper.standard.save(data, service: "access-token", account: "Service")
            var accessToken2 = ""
            if let data2 = KeychainHelper.standard.read(service: "access-token", account: "Service") {
                accessToken2 = String(data: data2, encoding: .utf8) ?? ""
            }
            return accessToken2
        }
    }
}

final class KeychainHelper {
    
    static let standard = KeychainHelper()
    private init() {}
    
    // Class implementation here...
    
    func save(_ data: Data, service: String, account: String) {
        
        // Create query
        let query = [
            kSecValueData: data,
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ] as CFDictionary
        
        // Add data in query to keychain
        let status = SecItemAdd(query, nil)
        
        if status != errSecSuccess {
            // Print out the error
            print("Error: \(status)")
        }
    }
    
    func read(service: String, account: String) -> Data? {
        
        let query = [
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecClass: kSecClassGenericPassword,
            kSecReturnData: true
        ] as CFDictionary
        
        var result: AnyObject?
        SecItemCopyMatching(query, &result)
        
        return (result as? Data)
    }
    
    
}
