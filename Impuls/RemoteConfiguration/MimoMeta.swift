//
//  MimoMeta.swift
//  MimoBike
//
//  Created by Andrey Lupin on 01.02.26.
//

import Foundation
import KeychainAccess

public class MimoMeta {

    public static var appConfig = AppConfig()
    public static let configuration = Config()
    public static var externalLinks: [String: [String: String]]?
    public static var localizations: [String: [String: String?]?]?
    public static var fbLocalizations: [String: String?]?
    public static var csatLocalizations: [String: [String: String?]?]?
    public static var authLocalizations: [String: [String: String?]?]?
    public static var assets: [String: [String: String]]?
    public static var appMinVersion: String?
        
    public static let deviceIdentifierString = "deviceIdentifier"
    
    public static var deviceIdentifier: String {
        var _deviceIdentifier = UIDevice.current.identifierForVendor?.uuidString ?? ""
        _deviceIdentifier = _deviceIdentifier.replacingOccurrences(of: "-", with: "")
        
        do {
            if try MimoMeta.configuration.keychain.get(MimoMeta.deviceIdentifierString) == nil {
                try MimoMeta.configuration.keychain.set(_deviceIdentifier, key: MimoMeta.deviceIdentifierString)
                
                return _deviceIdentifier
            } else {
                return try MimoMeta.configuration.keychain.get(MimoMeta.deviceIdentifierString) ?? _deviceIdentifier
            }
        } catch {
            debugPrint(error.localizedDescription)
        }
        
        return _deviceIdentifier
    }
    
    public var deviceIdentifier: String? {
        set {
            do {
                if try MimoMeta.configuration.keychain.get(MimoMeta.deviceIdentifierString) == nil {
                    if let deviceIdentifier = newValue {
                        try MimoMeta.configuration.keychain.set(deviceIdentifier, key: MimoMeta.deviceIdentifierString)
                    } else {
                        try MimoMeta.configuration.keychain.remove(MimoMeta.deviceIdentifierString)
                    }
                }
            } catch {
                debugPrint(error.localizedDescription)
            }
        }
        get {
            return try? MimoMeta.configuration.keychain.get(MimoMeta.deviceIdentifierString)
        }
    }
    
    public init() {
        
    }
}
