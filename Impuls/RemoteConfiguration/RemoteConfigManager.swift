//
//  RemoteConfigManager.swift
//  MimoBike
//
//  Created by Andrey Lupin on 01.02.26.
//

import FirebaseRemoteConfig

struct RemoteConfigManager {
    
    private static var remoteConfig: RemoteConfig = {
        var remoteConfig = RemoteConfig.remoteConfig()
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
        // Every flag the app knows defaults to false until the remote value
        // arrives, so a missing key reads as the safe value and never as an
        // error.
        remoteConfig.setDefaults(AppConfig.CodingKeys.allCases.reduce(into: [String: NSObject]()) { defaults, key in
            defaults[key.rawValue] = NSNumber(value: false)
        })
        return remoteConfig
    }()
        
    static func configure(exprationDuration: TimeInterval = 0, completion: @escaping () -> Void) {
        remoteConfig.fetch(withExpirationDuration: exprationDuration) { (status, error) in
            if let err = error {
                print("<<================= FirebaseRemoteConfig.fetch.Error =================<<")
                print(err.localizedDescription)
            }
            print("<<================= FirebaseRemoteConfig.fetch.Success =================<<")
            RemoteConfig.remoteConfig().activate()
            
            do {
                MimoMeta.appConfig = try decodeAppConfig()
                print("<<================= FirebaseRemoteConfig.JSONDecoder.Success =================<<")
            } catch  {
              print("<<================= FirebaseRemoteConfig.JSONDecoder.Error =================<<")
            }
            completion()
        }
    }
    
    static func configure() async throws -> AppConfig {
        _ = try await remoteConfig.fetch()
        try await RemoteConfig.remoteConfig().activate()
        
        return try decodeAppConfig()
    }

    /// Reads every key the app knows from the activated config. Unknown remote
    /// keys are ignored and missing ones fall back to the in-app default, so
    /// the decode only fails if the payload itself cannot be serialised.
    private static func decodeAppConfig() throws -> AppConfig {
        var appConfigDictionary = [String : Bool]()
        
        AppConfig.CodingKeys.allCases.forEach { key in
            appConfigDictionary[key.rawValue] = RemoteConfigManager.bool(forKey: key.rawValue) ?? false
        }
        
        return try JSONDecoder().decode(AppConfig.self, from: (appConfigDictionary.jsonData ?? Data()))
    }
    
    static func value(forKey key: String) -> String? {
        return remoteConfig.configValue(forKey: key).stringValue
    }
    
    static func bool(forKey key: String) -> Bool? {
        return remoteConfig.configValue(forKey: key).boolValue
    }
    
    static func jsonValue(forKey key: String) -> [String: Any]? {
        return remoteConfig.configValue(forKey: key).jsonValue as? [String: Any]
    }
}
