//
//  StorageManager.swift
//  MimoBike
//
//  Created by Albert on 20.05.21.
//

import Foundation

final class StorageManager {
    
    /// Store in user defaults
    func store<T>(_ value: T, key: UserDefaultsNames) {
        UserDefaults.standard.setValue(value, forKey: key.rawValue)
    }
    
    /// Fetch from user defaults
    func fetch<T: Hashable>(key: UserDefaultsNames, type: T.Type) -> T? {
        return UserDefaults.standard.value(forKey: key.rawValue) as? T
    }
    
    func remove(key: UserDefaultsNames) {
        UserDefaults.standard.set(nil, forKey: key.rawValue)
    }
}


enum UserDefaultsNames: String {
    case language
    case avatar
    case phoneNumber
    case isAccountCompleted
    case activeInsuranceStart
    case activeInsuranceEnd
    case insurancePrice
}
