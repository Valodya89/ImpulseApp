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
            
            let appConfigKeys = remoteConfig.allKeys(from: .remote)
            var appConfigDictionary = [String : Bool]()
            
            appConfigKeys.forEach { key in
                appConfigDictionary[key] = RemoteConfigManager.bool(forKey: key) ?? false
            }
            
            do {
                let appConfig = try JSONDecoder().decode(AppConfig.self, from: (appConfigDictionary.jsonData ?? Data()))
                MimoMeta.appConfig = appConfig
                print("<<================= FirebaseRemoteConfig.JSONDecoder.Success =================<<")
            } catch  {
              print("<<================= FirebaseRemoteConfig.JSONDecoder.Error =================<<")
            }
            completion()
        }
    }
    
    static func configure() async throws -> AppConfig {
        let status = try await remoteConfig.fetch()
        try await RemoteConfig.remoteConfig().activate()
        
        let appConfigKeys = remoteConfig.allKeys(from: .remote)
        var appConfigDictionary = [String : Bool]()
        
        appConfigKeys.forEach { key in
            appConfigDictionary[key] = RemoteConfigManager.bool(forKey: key) ?? false
        }
        
        let appConfig = try JSONDecoder().decode(AppConfig.self, from: (appConfigDictionary.jsonData ?? Data()))
        return appConfig
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
